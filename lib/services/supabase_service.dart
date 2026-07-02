import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/workplaces.dart';

const kSupabaseUrl = 'https://oegapohfarwuoredjoao.supabase.co';
const kSupabaseKey = 'sb_publishable_Ll613ZCUexn626vwLD43nw_vbyYu7au';

/// 커뮤니티 게시글
class CommunityPost {
  final String id;
  final String category;
  final String title;
  final String body;
  final String? aiAnswer;
  final int likes;
  final bool pinned;
  final bool mine;
  CommunityPost({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    this.aiAnswer,
    this.likes = 0,
    this.pinned = false,
    this.mine = false,
  });

  factory CommunityPost.fromMap(Map<String, dynamic> m, {String? uid}) => CommunityPost(
        id: m['id'] as String,
        category: (m['category'] ?? '') as String,
        title: (m['title'] ?? '') as String,
        body: (m['body'] ?? '') as String,
        aiAnswer: m['ai_answer'] as String?,
        likes: (m['likes'] ?? 0) as int,
        pinned: (m['pinned'] ?? false) as bool,
        mine: uid != null && m['author'] == uid,
      );
}

/// 커뮤니티 댓글
class PostComment {
  final String who;
  final String body;
  final bool isAi;
  PostComment(this.who, this.body, this.isAi);
  factory PostComment.fromMap(Map<String, dynamic> m) => PostComment(
        (m['author_label'] ?? '익명') as String,
        (m['body'] ?? '') as String,
        (m['is_ai'] ?? false) as bool,
      );
}

/// Supabase 연동 서비스 — 인증 + work_logs + 사업장/커뮤니티/프로필.
/// 실패(오프라인·테이블 없음)해도 앱이 죽지 않도록 예외는 삼키고 폴백값을 준다.
class SupabaseService {
  bool ready = false;

  Future<void> init() async {
    try {
      await Supabase.initialize(url: kSupabaseUrl, publishableKey: kSupabaseKey, debug: false);
      ready = true;
    } catch (_) {
      ready = false;
    }
  }

  SupabaseClient get _c => Supabase.instance.client;
  GoTrueClient get _auth => Supabase.instance.client.auth;

  // ---------------- 인증 ----------------
  String? get uid => ready ? _auth.currentUser?.id : null;
  bool get isLoggedIn => uid != null;
  Stream<AuthState> get onAuthChange => _auth.onAuthStateChange;

  /// 회원가입 (이메일+비밀번호). 이름·국적은 user_metadata로 저장 → 트리거가 profiles 생성.
  Future<String?> signUp(String email, String password,
      {String? name, String? nationality}) async {
    try {
      await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name, 'nationality': nationality},
      );
      return null; // 성공
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'err_signup'; // auth.dart에서 현재 언어로 번역
    }
  }

  /// 로그인. 실패 시 오류 메시지 반환, 성공 시 null.
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'err_signin'; // auth.dart에서 현재 언어로 번역
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  // ---------------- 프로필 ----------------
  Future<Map<String, dynamic>?> fetchProfile() async {
    final id = uid;
    if (id == null) return null;
    try {
      return await _c.from('profiles').select().eq('id', id).maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(Map<String, dynamic> patch) async {
    final id = uid;
    if (id == null) return;
    try {
      await _c.from('profiles').update(patch).eq('id', id);
    } catch (_) {}
  }

  // ---------------- 사업장 ----------------
  Future<List<Workplace>> fetchWorkplaces() async {
    try {
      final rows = await _c.from('workplaces').select().order('sort');
      return (rows as List)
          .map((r) => Workplace.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ---------------- 커뮤니티 ----------------
  Future<List<CommunityPost>> fetchPosts({bool hot = true}) async {
    try {
      final rows = await _c
          .from('community_posts')
          .select()
          .order('pinned', ascending: false)
          .order(hot ? 'likes' : 'created_at', ascending: false);
      return (rows as List)
          .map((r) => CommunityPost.fromMap(r as Map<String, dynamic>, uid: uid))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> addPost(String category, String title, String body) async {
    final id = uid;
    if (id == null) return '로그인이 필요해요';
    try {
      await _c.from('community_posts').insert({
        'author': id,
        'category': category,
        'title': title,
        'body': body,
      });
      return null;
    } catch (_) {
      return '글 등록에 실패했어요';
    }
  }

  Future<List<PostComment>> fetchComments(String postId) async {
    try {
      final rows = await _c
          .from('community_comments')
          .select()
          .eq('post_id', postId)
          .order('created_at');
      return (rows as List)
          .map((r) => PostComment.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> addComment(String postId, String label, String body) async {
    final id = uid;
    if (id == null) return false;
    try {
      await _c.from('community_comments').insert({
        'post_id': postId,
        'author': id,
        'author_label': label,
        'body': body,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------------- 근무 기록 (work_logs) ----------------
  /// 최근 근무 기록 (내 것만, RLS로 자동 필터).
  Future<List<Map<String, dynamic>>> fetchLogs() async {
    if (!isLoggedIn) return [];
    try {
      final rows = await _c
          .from('work_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(30);
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// 출근: 행 생성 후 id 반환 (실패 시 null)
  Future<String?> startLog(String clockIn) async {
    if (!isLoggedIn) return null;
    try {
      final now = DateTime.now();
      final row = await _c
          .from('work_logs')
          .insert({'work_date': '${now.month}월 ${now.day}일', 'clock_in': clockIn})
          .select()
          .single();
      return row['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// 퇴근: 열린 행에 clock_out 기록. 성공 시 true(DB), 실패 시 false(로컬).
  Future<bool> endLog(String? logId, String clockOut) async {
    if (logId == null || !isLoggedIn) return false;
    try {
      await _c.from('work_logs').update({'clock_out': clockOut}).eq('id', logId);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final supabase = SupabaseService();
