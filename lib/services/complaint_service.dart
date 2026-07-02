import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

/// 진정서 생성 결과
class ComplaintResult {
  final String complaintKo;
  final String summaryNative;
  final bool fallback;
  ComplaintResult(this.complaintKo, this.summaryNative, this.fallback);
}

/// 기존 Node 백엔드(/api/complaint, Gemini) 재사용.
/// iOS 시뮬레이터는 호스트 localhost 공유 → localhost:8080 직접 접근.
class ComplaintService {
  String get _base {
    // Android 에뮬레이터는 10.0.2.2, iOS 시뮬레이터·데스크톱은 localhost
    if (!Platform.isIOS && !Platform.isMacOS) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  Future<ComplaintResult> generate({
    required String name,
    required String nationality,
    required String lang,
    required String promisedWage,
    required String unpaidPeriod,
    required List<Map<String, String>> logs,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_base/api/complaint'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'nationality': nationality,
              'lang': lang,
              'promisedWage': promisedWage,
              'unpaidPeriod': unpaidPeriod,
              'logs': logs,
            }),
          )
          .timeout(const Duration(seconds: 60));
      final d = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      return ComplaintResult(
        d['complaint_ko'] as String? ?? '',
        d['summary_native'] as String? ?? '',
        d['fallback'] as bool? ?? false,
      );
    } catch (e) {
      return ComplaintResult(
        '(오프라인) 서버에 연결할 수 없어 초안을 생성하지 못했어요.\n데모 서버(node app/server.js)가 실행 중인지 확인해 주세요.',
        'Could not reach the server. Make sure the demo server is running.',
        true,
      );
    }
  }
}

final complaintService = ComplaintService();
