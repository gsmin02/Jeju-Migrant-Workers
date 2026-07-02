import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class WorkLog {
  final String date;
  final String detail; // "07:00 – 18:30 · 한라양식"
  final String hours; // "10.5h" 또는 "저장됨"
  final String source; // GPS / 직접입력 / DB / 로컬
  WorkLog(this.date, this.detail, this.hours, this.source);
}

/// 앱 전역 상태 (목업의 전역 변수 이식)
class AppState extends ChangeNotifier {
  String lang = 'ko';
  int points = 1250;
  bool attended = false;
  bool paid = false; // 이용권 구매 여부
  bool previewPaid = false; // 유료 전환 미리보기 (오픈 무료 기간)
  bool punchedIn = false;
  String? jobAd; // 채용공고 파일명
  int attendStreak = 3;
  String? _openLogId; // 열린 출근 기록 id (Supabase)

  final List<WorkLog> logs = [
    WorkLog('6월 30일 (월)', '07:00 – 18:30 · 한라양식', '10.5h', 'GPS'),
    WorkLog('6월 29일 (일)', '07:10 – 15:00 · 한라양식', '7.3h', 'GPS'),
    WorkLog('6월 28일 (토)', '06:50 – 19:00 · 한라양식', '11.7h', '직접입력'),
  ];

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

  void checkAttend() {
    if (attended) return;
    attended = true;
    attendStreak += 1;
    points += 5;
    notifyListeners();
  }

  void setJobAd(String name) {
    jobAd = name;
    notifyListeners();
  }

  void setPreviewPaid(bool v) {
    previewPaid = v;
    notifyListeners();
  }

  void buyPass() {
    paid = true;
    notifyListeners();
  }

  /// 유료 마스킹이 걸리는 조건: 미리보기 ON + 미구매
  bool get masked => previewPaid && !paid;

  Future<void> punch(bool punchIn, String time) async {
    punchedIn = punchIn;
    if (punchIn) {
      _openLogId = await supabase.startLog(time);
    } else {
      final saved = await supabase.endLog(_openLogId, time);
      logs.insert(
        0,
        WorkLog('오늘', '~ $time 퇴근 · 한라양식', '저장됨', saved ? 'DB' : '로컬'),
      );
      _openLogId = null;
    }
    notifyListeners();
  }
}
