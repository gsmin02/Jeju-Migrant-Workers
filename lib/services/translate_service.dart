import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;

/// 커뮤니티 글 번역 서비스 — NestJS 백엔드(/api/translate, Gemini) 호출.
/// 결과는 호출부에서 Supabase post_translations에 캐시해 재호출을 막는다.
class TranslateService {
  String get _base {
    // Android 에뮬레이터만 10.0.2.2, 그 외(웹·iOS·데스크톱)는 localhost.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  /// [texts]를 [target] 언어로 번역. 성공 시 같은 길이의 번역 배열,
  /// 실패·폴백(서버 미동작/키 없음) 시 null 반환(호출부가 원문 유지).
  Future<List<String>?> translate(List<String> texts, String target) async {
    if (texts.isEmpty) return texts;
    try {
      final resp = await http
          .post(
            Uri.parse('$_base/api/translate'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'texts': texts, 'target': target}),
          )
          .timeout(const Duration(seconds: 30));
      final d = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final list = (d['translations'] as List?)?.map((e) => e.toString()).toList();
      final fallback = d['fallback'] as bool? ?? false;
      if (fallback || list == null || list.length != texts.length) return null;
      return list;
    } catch (_) {
      return null;
    }
  }
}

final translateService = TranslateService();
