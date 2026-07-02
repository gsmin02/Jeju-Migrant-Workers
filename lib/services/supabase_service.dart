import 'package:supabase_flutter/supabase_flutter.dart';

const kSupabaseUrl = 'https://oegapohfarwuoredjoao.supabase.co';
const kSupabaseKey = 'sb_publishable_Ll613ZCUexn626vwLD43nw_vbyYu7au';

/// work_logs 실저장. 실패(테이블 없음·오프라인)해도 앱은 계속 — 폴백 판단용 bool 반환.
class SupabaseService {
  bool ready = false;

  Future<void> init() async {
    try {
      await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseKey, debug: false);
      final auth = Supabase.instance.client.auth;
      if (auth.currentSession == null) {
        await auth.signInAnonymously();
      }
      ready = true;
    } catch (e) {
      ready = false;
    }
  }

  SupabaseClient? get _c => ready ? Supabase.instance.client : null;

  /// 출근: 행 생성 후 id 반환 (실패 시 null)
  Future<String?> startLog(String clockIn) async {
    try {
      final now = DateTime.now();
      final row = await _c!
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
    if (logId == null || _c == null) return false;
    try {
      await _c!.from('work_logs').update({'clock_out': clockOut}).eq('id', logId);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final supabase = SupabaseService();
