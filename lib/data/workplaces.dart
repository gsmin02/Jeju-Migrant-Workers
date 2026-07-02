/// 사업장 모델. 데이터는 Supabase `workplaces` 테이블에서 불러온다.
/// (하드코딩 목록 제거 — 시드는 supabase/schema.sql 참조)
library;

class Workplace {
  const Workplace({
    required this.name,
    required this.job,
    required this.industry,
    required this.region,
    required this.pay,
    this.reports = 0,
    required this.workers,
    this.lastReport,
    this.rating,
  });

  final String name; // 사업장 이름
  final String job; // 직무
  final String industry; // 업종 분류 (아이콘 매핑용)
  final String region; // 근무 지역
  final String pay; // 급여
  final int reports; // 임금체불 신고 누적 건수 (0 = 신고 없음)
  final int workers; // 이 앱을 쓰는 노동자 수
  final String? lastReport; // 최근 신고 연도
  final double? rating; // 근로 평가 (신고 없을 때만)

  bool get flagged => reports > 0;

  factory Workplace.fromMap(Map<String, dynamic> m) => Workplace(
        name: (m['name'] ?? '') as String,
        job: (m['job'] ?? '') as String,
        industry: (m['industry'] ?? '') as String,
        region: (m['region'] ?? '') as String,
        pay: (m['pay'] ?? '') as String,
        reports: (m['reports'] ?? 0) as int,
        workers: (m['workers'] ?? 0) as int,
        lastReport: m['last_report'] as String?,
        rating: (m['rating'] as num?)?.toDouble(),
      );

  /// 업종 → 이모지 아이콘.
  String get icon {
    switch (industry) {
      case '어업':
      case '양식':
        return '🐟';
      case '축산':
        return '🐄';
      case '농업':
        return '🍊';
      case '청소/미화':
        return '♻️';
      case '식료품 제조':
      case '제조':
        return '🏭';
      default:
        return '🏢';
    }
  }
}
