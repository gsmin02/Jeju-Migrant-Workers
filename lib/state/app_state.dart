import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../data/avatar_svgs.dart';

class WorkLog {
  final String date;
  final String detail; // "07:00 – 18:30 · 한라양식"
  final String hours; // "저장됨" / "진행중"
  final String source; // GPS / DB / 로컬
  final double? hoursNum; // 실제 근무 시간(시) — clock_in/out에서 계산, 없으면 null
  WorkLog(this.date, this.detail, this.hours, this.source, {this.hoursNum});
}

/// 앱 전역 상태. 사용자 데이터(프로필·근무기록)는 Supabase에서 로드한다.
class AppState extends ChangeNotifier {
  AppState() {
    lang = _detectLang();
  }

  static String _detectLang() {
    final locales = PlatformDispatcher.instance.locales;
    for (final l in locales) {
      final c = l.languageCode.toLowerCase();
      if (langLabels.containsKey(c)) return c;
    }
    if (locales.isNotEmpty && locales.first.languageCode.toLowerCase() != 'ko') {
      return 'en';
    }
    return 'ko';
  }

  String lang = 'ko';

  // ----- 사용자 프로필 (DB: profiles) -----
  String? name;
  String? nationality;
  String? workplace; // 내 사업장 이름 (없으면 null)
  String? tenure; // 근속 (예: "1년 2개월")
  String? inviteCode; // 내 초대 코드 (profiles.invite_code)
  int points = 0;
  int attendStreak = 0;
  bool attended = false;

  // ----- 아바타 커스터마이징 (DB: profiles) -----
  String skinColor = '#f0c093';
  String clothKind = 'farm';
  String hatName = '귤모자'; // 상점 미리보기 모자
  String hatBigName = '귤모자'; // 홈 프로필 모자 (kHatsBig에 있는 것만 반영)
  String propKind = 'none';

  // ----- 근무 기록 (DB: work_logs) -----
  final List<WorkLog> logs = [];

  bool paid = false; // 이용권 구매 여부
  bool previewPaid = false; // 유료 전환 미리보기
  bool punchedIn = false;
  bool punchedOutDone = false; // 오늘 퇴근까지 완료(GPS 링 'out' 상태)
  String? jobAd;
  String? _openLogId;
  String? _loadedUid; // 프로필/기록을 로드한 사용자 (중복 로드 방지)

  // ----- 출퇴근 알림 설정 -----
  bool notiAuto = true;
  bool notiIn = true;
  bool notiOut = true;
  TimeOfDay notiInTime = const TimeOfDay(hour: 6, minute: 30);
  TimeOfDay notiOutTime = const TimeOfDay(hour: 18, minute: 0);

  void toggleNoti(String which) {
    switch (which) {
      case 'auto':
        notiAuto = !notiAuto;
      case 'in':
        notiIn = !notiIn;
      case 'out':
        notiOut = !notiOut;
    }
    notifyListeners();
  }

  void setNotiTime(String which, TimeOfDay time) {
    if (which == 'in') {
      notiInTime = time;
    } else {
      notiOutTime = time;
    }
    notifyListeners();
  }

  // ----- 시스템 알림 배너 (상단 오버레이) -----
  String? sysNotiTitle;
  String? sysNotiText;
  int _sysNotiSeq = 0;

  void showSysNoti(String title, String text) {
    sysNotiTitle = title;
    sysNotiText = text;
    final seq = ++_sysNotiSeq;
    notifyListeners();
    Timer(const Duration(milliseconds: 4500), () {
      if (seq == _sysNotiSeq) {
        sysNotiTitle = null;
        sysNotiText = null;
        notifyListeners();
      }
    });
  }

  void dismissSysNoti() {
    _sysNotiSeq++;
    sysNotiTitle = null;
    sysNotiText = null;
    notifyListeners();
  }

  static const langOrder = ['ko', 'en', 'vi', 'id'];
  static const langLabels = {
    'ko': '한국어', 'en': 'English', 'vi': 'Tiếng Việt', 'id': 'Bahasa'
  };

  void setLang(String l) {
    lang = l;
    notifyListeners();
  }

  void cycleLang() {
    final i = langOrder.indexOf(lang);
    lang = langOrder[(i + 1) % langOrder.length];
    notifyListeners();
  }

  /// 로그인 직후 호출 — 프로필·근무기록을 DB에서 로드 (한 번만).
  Future<void> onLoggedIn() async {
    final uid = supabase.uid;
    if (uid == null || _loadedUid == uid) return;
    _loadedUid = uid;

    final p = await supabase.fetchProfile();
    if (p != null) {
      name = p['name'] as String?;
      nationality = p['nationality'] as String?;
      workplace = p['workplace'] as String?;
      tenure = p['tenure'] as String?;
      inviteCode = p['invite_code'] as String?;
      points = (p['points'] ?? 0) as int;
      attendStreak = (p['attend_streak'] ?? 0) as int;
      final last = p['last_attend'] as String?;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      attended = last == today;
      // 아바타 장착 상태 복원
      skinColor = (p['skin_color'] as String?) ?? skinColor;
      clothKind = (p['cloth_kind'] as String?) ?? clothKind;
      final hn = (p['hat_name'] as String?) ?? hatName;
      hatName = hn;
      hatBigName = kBigHatNames.contains(hn) ? hn : '귤모자';
      propKind = (p['prop_kind'] as String?) ?? propKind;
    }

    final rows = await supabase.fetchLogs();
    logs
      ..clear()
      ..addAll(rows.map(_rowToLog));

    notifyListeners();
  }

  /// 로그아웃 시 다음 로그인에서 다시 로드하도록 플래그만 초기화(빌드 중 호출되므로 notify 안 함).
  void resetForLogout() {
    _loadedUid = null;
  }

  WorkLog _rowToLog(Map<String, dynamic> r) {
    final wp = (r['workplace'] ?? '') as String;
    final cin = (r['clock_in'] ?? '') as String? ?? '';
    final cout = r['clock_out'] as String?;
    final date = (r['work_date'] ?? '') as String? ?? '';
    final detail = cout != null ? '$cin – $cout · $wp' : '$cin ~ 근무중 · $wp';
    return WorkLog(date, detail, cout != null ? '저장됨' : '진행중', 'DB',
        hoursNum: _calcHours(cin, cout));
  }

  /// "HH:MM" 출퇴근으로 근무 시간(시)을 계산. 불완전하면 null.
  static double? _calcHours(String? cin, String? cout) {
    final a = _toMinutes(cin), b = _toMinutes(cout);
    if (a == null || b == null) return null;
    var diff = b - a;
    if (diff < 0) diff += 24 * 60; // 자정 넘김
    return diff / 60.0;
  }

  static int? _toMinutes(String? hhmm) {
    if (hhmm == null) return null;
    final p = hhmm.trim().split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  // ----- 근무 요약 (DB 근무기록 기반) -----
  /// 근무한 날 수(기록 건수).
  int get workDays => logs.length;

  /// 총 근무 시간(시). clock_in/out이 있는 기록만 합산.
  double get totalHours => logs.fold(0.0, (sum, l) => sum + (l.hoursNum ?? 0));

  Future<void> checkAttend() async {
    if (attended) return;
    attended = true;
    attendStreak += 1;
    points += 5;
    notifyListeners();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await supabase.saveProfile({
      'points': points,
      'attend_streak': attendStreak,
      'last_attend': today,
    });
  }

  /// 포인트 적립 (글 작성 등). 즉시 반영 + DB 저장.
  Future<void> awardPoints(int n) async {
    points += n;
    notifyListeners();
    await supabase.saveProfile({'points': points});
  }

  void setJobAd(String name) {
    jobAd = name;
    notifyListeners();
  }

  /// 프로필 편집 저장 (이름·사업지·근속·국적). 즉시 반영 후 DB에 저장.
  Future<void> updateProfile(
      {String? name, String? workplace, String? tenure, String? nationality}) async {
    if (name != null) this.name = name;
    if (workplace != null) this.workplace = workplace;
    if (tenure != null) this.tenure = tenure;
    if (nationality != null) this.nationality = nationality;
    notifyListeners();
    // tenure 컬럼이 없을 수도 있어(마이그레이션 전) 분리 저장 — 이름 등은 항상 반영됨.
    await supabase.saveProfile({
      'name': this.name,
      'workplace': this.workplace,
      'nationality': this.nationality,
    });
    await supabase.saveProfile({'tenure': this.tenure});
  }

  /// 초대 코드 사용. 성공 시 내 포인트 +bonus.
  /// 반환: 'ok' / 'already' / 'notfound' / 'self' / 'auth' / 'err'
  Future<String> redeemInvite(String code) async {
    final res = await supabase.redeemInvite(code.trim());
    if (res['ok'] == true) {
      points += (res['bonus'] ?? 100) as int;
      notifyListeners();
      return 'ok';
    }
    return (res['reason'] ?? 'err') as String;
  }

  // ----- 아바타 장착 (변경 즉시 DB profiles에 저장) -----
  void equipSkin(String color) {
    skinColor = color;
    notifyListeners();
    supabase.saveProfile({'skin_color': color});
  }

  void equipCloth(String kind) {
    clothKind = kind;
    notifyListeners();
    supabase.saveProfile({'cloth_kind': kind});
  }

  void equipHat(String name) {
    hatName = name;
    if (kBigHatNames.contains(name)) hatBigName = name;
    notifyListeners();
    supabase.saveProfile({'hat_name': name});
  }

  void equipProp(String kind) {
    propKind = kind;
    notifyListeners();
    supabase.saveProfile({'prop_kind': kind});
  }

  void setPreviewPaid(bool v) {
    previewPaid = v;
    notifyListeners();
  }

  void buyPass() {
    paid = true;
    notifyListeners();
  }

  /// 유료 마스킹 조건: 미리보기 ON + 미구매
  bool get masked => previewPaid && !paid;

  Future<void> punch(bool punchIn, String time) async {
    punchedIn = punchIn;
    punchedOutDone = !punchIn; // 퇴근하면 GPS 링을 'out' 상태로
    if (punchIn) {
      _openLogId = await supabase.startLog(time);
    } else {
      final saved = await supabase.endLog(_openLogId, time);
      logs.insert(
        0,
        WorkLog('오늘', '~ $time 퇴근 · ${workplace ?? '한라양식'}', '저장됨',
            saved ? 'DB' : '로컬'),
      );
      _openLogId = null;
    }
    notifyListeners();
  }
}
