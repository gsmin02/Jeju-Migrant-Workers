# 제이 (제주 이주민 · Jeju Migrant Workers)

제주 이주노동자가 평소 동료들과 근무를 기록해 근거를 모으고, 임금체불이 발생하면 그 기록으로 **진정서를 자동 생성**해 떼인 임금을 되찾도록 돕는 앱.

- 이름: **제이** = **제**주 **이**주민 · 영문 **Jeju Migrant Workers**
- 프레임워크: Flutter (iOS·Android)
- 서버: [Jeju-Migrant-Workers-SERVER](https://github.com/gsmin02/Jeju-Migrant-Workers-SERVER) (NestJS)

## 핵심 기능

- **GPS 근무 기록** — 출퇴근 원탭 기록, Supabase 저장 (실패 시 로컬 폴백)
- **증거함** — GPS 기록·채용공고·동료 교차기록
- **진정서 자동 생성** — 기록 + 약속 임금/미지급 기간 → 노동청 제출용 한국어 진정서 + 모국어 요약 + PDF
- **사업장 신고 이력** — 익명 제보 집계 (오픈 무료 기간 / 유료 전환 미리보기)
- **커뮤니티 · SOS** — 익명 Q&A, 1350·제주지원센터 핫라인, 상황별 법률 안내

## 증거 설계 — 5축 모델

| 축 | 원칙 | 앱 장치 |
|---|---|---|
| 공유 | 사업주에게 보고·공유된 기록이 강함 | 사업주 기록 공유 (로드맵) |
| 기간 | GPS 기록 3개월+ 축적 | 출석체크·출퇴근 알림 |
| 교차 | 동료 기록이 서로를 검증 | 사업장 네트워크·친구 초대 |
| 동시성 | 공동 진정 시 진술 보강 | 공동 진정 (로드맵) |
| 단서 | 응시한 채용공고 = 계약 추정 자료 | 채용공고 저장·증거함 |

## 실행

```bash
flutter pub get
flutter run                 # 연결된 기기/시뮬레이터
# 화면 점프(개발용): --dart-define=START=main --dart-define=TAB=1
```

> 진정서 실생성에는 서버(`Jeju-Migrant-Workers-SERVER`)가 `localhost:8080`에서 실행 중이어야 합니다. 없으면 준비된 샘플로 폴백합니다.

## 구조

```
lib/
├── main.dart              # 진입 · Supabase 초기화 · 화면 게이트
├── theme.dart             # 감귤 팔레트
├── state/                 # app_state(provider) · i18n(ko/en/vi/id)
├── services/              # supabase · complaint(서버 호출)
├── screens/               # splash · onboarding · main_shell · 5탭
└── widgets/               # 진정서 시트 · 상점 · 페이월 · 공통
```

> ⚠️ 생성되는 진정서는 참고용 초안이며 법률 자문이 아닙니다. 제출 전 고용노동부 1350 또는 제주외국인노동자지원센터(064-712-1141) 확인 안내를 포함합니다.
