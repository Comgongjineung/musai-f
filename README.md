# 🚀 [내 손 안의 전시회 관람 가이드 앱, Musai]
<img width="1920" height="1080" alt="Image" src="https://github.com/user-attachments/assets/1aed974a-80d1-4c3f-bc97-8a821e9163b2" />

## 📌 개요 (Overview)

> - MUSAI는 AI 기반 작품 인식 기술을 활용해 사용자가 촬영한 작품을 분석하고 자동으로 해설을 제공하는 서비스입니다.
> - 사용자의 관심사(화풍·작가·시대 등)를 기반으로 개인 맞춤형 작품 정보를 추천합니다.
> - AR 기능을 통해 작품의 주요 포인트와 해설 내용을 시각적으로 시각화하여 감상 경험을 확장합니다.
> - 백엔드 서버는 이미지 분석 요청 처리, 작품 정보 제공, 사용자 맞춤 추천 로직 등을 담당해 전체 서비스 흐름을 안정적으로 지원합니다.

---

## 🛠️ 기술 스택 및 개발 환경 (Tech Stack & Environment)

우리 프로젝트를 구축하는 데 사용된 주요 기술과 도구는 다음과 같습니다.

### 💻 클라이언트 및 프론트엔드 (Client & Frontend)

| 분류 | 기술 스택 | 설명 |
| :--- | :--- | :--- |
| **모바일 앱** | **Flutter** | 크로스 플랫폼 모바일 애플리케이션 개발에 사용 |
| **게임/3D 엔진** | **Unity** | 3D 콘텐츠 및 특수 인터랙션 로직 구현에 사용 |
| **증강 현실 (AR)** | **Vuforia Engine** | 증강 현실 기능 구현 및 트래킹 기술 적용 |

### ⚙️ 백엔드 및 서버 (Backend & Server)

| 분류 | 기술 스택 | 설명 |
| :--- | :--- | :--- |
| **메인 백엔드** | **Spring Boot** | 주 서비스 로직 및 RESTful API 구축 |
| **AI/ML 서버** | **FastAPI** | 인공지능 모델 호스팅 및 고속 추론 API 제공 |
| **외부 연동** | **외부 AI API** | 특정 고도화된 AI 기능 구현을 위해 외부 서비스 연동 |
| **인증/보안** | **OAuth 2.0 + JWT** | 소셜 로그인 연동 및 토큰 기반 사용자 권한 관리 적용 |
| **메인 데이터베이스** | **AWS RDS MySQL** | 영속적인 데이터 저장 및 관리 (관계형 데이터베이스) |
| **메시징/알림** | **Firebase (FCM)** | 모바일 푸시 알림 서비스 구축 및 관리에 활용 |

### 🌐 배포 및 인프라 (Deployment & Infrastructure)

| 분류 | 기술 스택 | 설명 |
| :--- | :--- | :--- |
| **클라우드** | **AWS (Amazon Web Services)** | 서버 호스팅 및 인프라 구축 |
| **컨테이너** | **Docker** | 애플리케이션 환경 격리 및 개발/배포 환경 통일 |
| **CI/CD** | **Github Actions** | 자동화된 테스트, 빌드 및 배포 파이프라인 구축 |

### 🤝 협업 및 관리 (Collaboration & Management Tools)

| 분류 | 기술 스택 | 설명 |
| :--- | :--- | :--- |
| **버전 관리** | **Github** | 소스 코드 관리 및 공유 |
| **이슈 관리** | **Github Issues, Jira** | 버그 추적, 기능 요청, 개발 스프린트 관리 |
| **문서화** | **Notion** | 프로젝트 기획, 회의록, 기술 문서 정리 |
| **커뮤니케이션** | **Discord** | 실시간 팀 커뮤니케이션 및 알림 |
| **디자인** | **Figma** | UI/UX 디자인 및 프로토타이핑 |

---

## 💡 기술 채택 배경 및 개발 철학 (Technology Decisions & Philosophy)

프로젝트에 필요한 핵심 기술을 채택하고 개발을 진행한 배경과 이유는 다음과 같습니다.

### ☕️ Flutter (프론트엔드)

| 결정 이유 | 상세 내용 |
| :--- | :--- |
| **크로스 플랫폼 프레임워크** | Flutter는 **이미 다수의 상용 앱에서 사용**되는 프론트엔드 프레임워크 중 하나이며, IOS와 Android를 **단일 코드베이스**로 관리할 수 있어 장기 유지보수에 유리했다. |
| **AI·외부 서비스 연동 용이성** | REST API 기반 통신(Dio 등)이 용이하고, Firebase·카메라·알림 등 **AI 서버 및 디바이스 기능과의 연동**이 비교적 간단해 전체 아키텍처 구성에 유리했습니다. |

### ⚡️ Unity (AR 콘텐츠)

| 결정 이유 | 상세 내용 |
| :--- | :--- |
| **몰입형 콘텐츠 표현** | 전시 작품 안내 및 감상 경험을 강화하기 위해 **3D/AR 콘텐츠 표현이 필요**했고, Unity는 해당 영역에서 가장 성숙한 생태계를 갖춘 엔진입니다. |
| **Flutter와의 역할 분리** | Flutter는 **일반 UI·서비스 흐름**을 담당하고, Unity는 **AR/3D 상호작용 영역만 담당**하도록 분리하여 각 기술의 강점을 극대화했습니다. |


---

## 🌳 브랜치 전략 (Branch Strategy)

프로젝트의 안정적인 개발 및 배포 관리를 위해 **Git-flow 전략을 기반**으로 단순화된 브랜치 운영 방식을 채택했습니다.

### 📝 브랜치 명명 컨벤션

`[타입]/작업내용#이슈번호` 형식으로 브랜치를 생성하여 작업 목적과 연관된 이슈를 명확하게 추적했습니다.

| 타입 (Type) | 목적 | 예시 |
| :--- | :--- | :--- |
| **`feat`** | 새로운 기능(Feature) 개발 | `feat/user-login#15` |
| **`fix`** | 버그 수정 (Bug Fix) | `fix/ar-crash-bug#22` |
| **`refactor`** | 코드 리팩토링 (기능 변경 없이 내부 구조 개선) | `refactor/api-response` |
| **`chore`** | 빌드 시스템, 라이브러리 업데이트 등 자잘한 변경 | `chore/update-gradle` |
| **`test`** | 테스트 코드 추가/수정 | `test/auth-service` |
| **`docs`** | 문서(README, Wiki 등) 관련 변경 | `docs/update-readme` |

### 📌 브랜치 운영 방식

* **`main` 브랜치:**
    * **배포용 브랜치**이며, 서비스에 실제 배포되는 안정적인 코드만을 포함합니다.
* **`develop` 브랜치:**
    * **통합 개발 브랜치**이며, 모든 기능 개발이 완료된 후 `feature` 브랜치에서 Merge 되어 통합 테스트를 진행하는 기준 브랜치입니다.
* **`feature/[기능명]#[이슈번호]` 브랜치 (보조 브랜치):**
    * 기능 단위로 분리된 개발을 진행하며, 개발 완료 후 `develop` 브랜치로 **Pull Request(PR)**를 통해 Merge 요청을 합니다.
 
---

## 📁 디렉토리 구조 (Directory Structure)

본 프로젝트는 Flutter 단독 애플리케이션으로,
화면(UI)과 비즈니스 로직, 외부 연동(API, Firebase, OAuth)을 명확히 분리하여 **가독성·확장성·유지보수성**을 고려한 구조로 설계되었습니다.

<details>
<summary>🗂️ 프로젝트 파일 구조 보러가기</summary>

```lib/
├── main.dart                      # 앱 진입점
├── app.dart                       # MaterialApp / 라우팅 / 테마 설정
│
├── core/                          # 앱 전역 공통 모듈
│   ├── constants/
│   │   ├── colors.dart
│   │   ├── styles.dart
│   │   └── assets.dart
│   ├── utils/
│   │   ├── logger.dart
│   │   ├── permission_helper.dart
│   │   ├── location_helper.dart
│   │   └── date_formatter.dart
│   └── services/
│       ├── http_client.dart       # 공통 HTTP 통신
│       ├── firebase_service.dart  # Firebase 초기화
│       └── notification_service.dart
│
├── features/                      # 기능 단위 모듈화
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── services/
│   │   │   ├── auth_api.dart
│   │   │   ├── google_auth.dart
│   │   │   ├── kakao_auth.dart
│   │   │   └── apple_auth.dart
│   │   └── models/
│   │       └── user_model.dart
│   │
│   ├── exhibition/
│   │   ├── screens/
│   │   │   ├── exhibition_list_screen.dart
│   │   │   └── exhibition_detail_screen.dart
│   │   ├── services/
│   │   │   └── exhibition_api.dart
│   │   └── models/
│   │       └── exhibition_model.dart
│   │
│   ├── ar_view/
│   │   ├── screens/
│   │   │   └── camera_screen.dart
│   │   ├── services/
│   │   │   └── image_recognition_api.dart
│   │   └── models/
│   │       └── recog_result_model.dart
│   │
│   ├── ticket/
│   │   ├── screens/
│   │   │   ├── ticket_screen.dart
│   │   │   └── ticket_detail_screen.dart
│   │   ├── services/
│   │   │   └── ticket_api.dart
│   │   └── models/
│   │       └── ticket_model.dart
│   │
│   ├── community/
│   │   ├── screens/
│   │   │   ├── post_list_screen.dart
│   │   │   ├── post_detail_screen.dart
│   │   │   └── post_write_screen.dart
│   │   ├── services/
│   │   │   └── community_api.dart
│   │   └── models/
│   │       ├── post_model.dart
│   │       └── comment_model.dart
│   │
│   └── mypage/
│       ├── screens/
│       │   └── mypage_screen.dart
│       ├── services/
│       │   └── user_api.dart
│       └── models/
│           └── user_setting_model.dart
│
├── widgets/                       # 공용 위젯
│   ├── buttons/
│   │   ├── primary_button.dart
│   │   └── icon_button.dart
│   ├── dialogs/
│   │   └── confirm_dialog.dart
│   └── loading/
│       └── loading_indicator.dart
│
└── routes/
    └── app_routes.dart            # 화면 라우팅 정의

```
</details>

---

## 🧑‍💻 역할 분담 및 기여 (Roles & Contributions)

본 프로젝트는 효율적인 개발과 책임 분담을 위해 **공통 개발**과 **개별 기여** 영역을 명확히 나누어 진행했습니다.

### 🤝 공통 개발 영역 (Shared Responsibilities)

모든 팀원이 협력하여 아래의 주요 프론트엔드 기능 개발 및 아키텍처 설계에 참여했습니다.

* **아키텍처 및 설계:** 프론트엔드 전체 **아키텍처 및 설계** 공동 참여
* **핵심 API 연결 (Flutter/Unity 기반):**
    * **작품 인식** 및 **AI 해설 생성** 기능
    * **AR 기반 작품 포인트 분석**
    * **난이도별 작품 해설** 및 **TTS 변환**
    * **GPS 기반 전시회 추천**
    * **사용자 선호도 기반 추천 알고리즘**
    * **티켓 관리** 및 **작품 북마크** 기능
    * **OAuth 기반 회원가입/로그인** 시스템
    * **알림** 및 **푸시 메시지 처리**
    * **커뮤니티 게시글/댓글** 

---

## 📅 개발 기간 및 작업 관리 (Timeline & Workflow)

### ⏱️ 개발 기간

* **전체 개발 기간:** 2025.04.17 ~ 2025.10.31 (총 **197일**)

### 📈 작업 관리 및 협업 프로세스

* **일정 및 이슈 관리:** **Jira**를 이용하여 **스프린트 및 이슈 관리**를 진행했으며, **Slack**을 통해 실시간 진행 상황 및 알림을 공유했습니다.
* **정기 회의:** **주간 회의**를 정기적으로 진행하며 작업 순서와 우선순위를 조율하고, 각자의 진행 상황과 기술적 이슈를 점검하여 병목 현상을 최소화했습니다.

---

## 🆘 주요 트러블 슈팅 (Major Troubleshooting)

프로젝트 개발 및 배포 과정에서 발생했던 핵심 문제와 이를 해결하며 얻은 교훈은 다음과 같습니다.

### 1️⃣ 카메라 및 AR 기능의 실제 기기 테스트 환경 부족 문제

| 구분 | 내용 |
| :--- | :--- |
| **문제 요약** | 카메라 및 AR 기능이 에뮬레이터에서는 정상 동작하지 않거나 제한적으로만 동작하여, 기능 검증에 어려움이 있었습니다. |
| **문제 발생 원인** | Flutter 카메라 플러그인과 AR 기능은 실제 하드웨어 의존성이 높아 에뮬레이터 환경에서 정확한 테스트가 불가능했습니다. |
| **해결 과정** | 1. **다양한 환경 구축:** 팀원 전원이 각자 실제 스마트폰(iOS/Android)을 사용해 테스트 환경을 구축했습니다. 2. **예외 상황 확인:** 동일 기능을 다양한 기기에서 반복 테스트하여 기기별 예외 상황을 확인했습니다. |
| **교훈** | 하드웨어 의존 기능은 초기부터 **실기기 테스트를 필수 전제로 개발**해야 하며, 에뮬레이터만으로는 품질을 보장할 수 없다는 점을 명확히 인식하게 되었습니다. |

### 2️⃣ 공용 위젯 재사용 과정에서 UI 충돌 발생

| 구분 | 내용 |
| :--- | :--- |
| **문제 요약** | UI 통일성을 위해 공용 위젯을 public으로 선언하여 재사용하는 과정에서, 특정 화면 수정이 다른 화면 UI에 영향을 주는 문제가 발생했습니다. |
| **문제 발생 원인** | 공용 위젯의 책임 범위가 명확히 정의되지 않은 상태에서 기능과 스타일이 함께 변경되면서, 의도하지 않은 UI 사이드 이펙트가 발생했습니다. |
| **해결 과정** | 1. **최소 단위 분리:** 공용 위젯의 역할을 최소 단위로 분리하고, 스타일 변경이 필요한 경우 옵션 파라미터로 제어하도록 수정했습니다. 2. **규칙 수립:** UI 수정 시 영향 범위를 팀 내에서 사전 공유하는 규칙을 수립했습니다. |
| **교훈** | 공용 위젯은 **재사용성보다 안정성 우선**으로 설계해야 하며, 변경 가능성이 있는 요소는 명확히 분리해야 한다는 것을 배웠습니다. |


### 3️⃣ Flutter–Unity 연동 과정에서 MethodChannel 충돌 문제

| 구분 | 내용 |
| :--- | :--- |
| **문제 요약** | Flutter에서 Unity 기반 AR 기능을 실행하는 과정에서, iOS 빌드 후 Unity 화면이 정상적으로 실행되지 않거나 MethodChannel 통신 오류가 발생했습니다. |
| **문제 발생 원인** | Unity 내부에 포함된 Vuforia Framework를 Xcode에서 정상적으로 인식하지 못했으며, Flutter에서 Unity 실행 함수와 MethodChannel 호출 함수가 명확히 분리되지 않아 **호출 충돌**이 발생했습니다. |
| **해결 과정** | 1. **빌드 방식 변경:** Unity 플러그인 방식 대신 일반 iOS 빌드 방식으로 전환하여 Vuforia Framework 인식 문제를 해결했습니다. 2. **함수 분리:** Flutter에서 Unity 실행용 함수와 데이터 통신용 MethodChannel 함수를 명확히 분리하여 설계했습니다. |
| **교훈** | 플랫폼 간 연동에서는 **라이프사이클과 호출 흐름을 명확히 분리**하지 않으면 예기치 않은 충돌이 발생할 수 있으며, 문서화가 협업 안정성에 매우 중요함을 깨달았습니다. |

---

## ✨ 주요 기능 및 페이지 (Features by Page)

### 🔑 로그인 및 초기 설정
| 화면 이미지 | 주요 기능 및 설명 |
| :---: | :--- |
| <img src="https://github.com/user-attachments/assets/90d74711-24b8-442f-a5b7-18e4f2f2ec03" width="180"/> | **소셜 로그인 (Login)**<br><br> - **OAuth 2.0 기반 인증**: Google, Apple 등 소셜 계정을 통한 간편한 회원가입 및 로그인 지원<br> - **보안**: JWT(JSON Web Token)를 활용한 안전한 사용자 인증 및 세션 관리 |
| <img src="https://github.com/user-attachments/assets/1f373793-4f7a-4d08-aedc-a06ddb1ad68c" width="180"/> | **취향 테스트 (Preference Test)**<br><br> - **선호도 분석**: 초기 가입 시 작품 선호도 테스트를 통해 사용자의 예술적 취향 파악<br> - **추천 알고리즘**: 테스트 결과를 기반으로 개인화된 초기 작품 및 전시 추천 데이터 생성 |

### 🏠 메인 및 전시 추천
| 화면 이미지 | 주요 기능 및 설명 |
| :---: | :--- |
| <img src="https://github.com/user-attachments/assets/e12939ac-af30-4427-8ab9-6d41fb0f9759" width="180"/> | **메인 홈 (Home)**<br><br> - **GPS 기반 위치 추천**: 사용자의 현재 위치를 기반으로 가장 가까운 전시회 및 미술관 정보 제공<br> - **맞춤형 큐레이션**: 취향 테스트 결과 및 활동 데이터를 분석하여 사용자 맞춤형 작품 리스트 노출 |

### 📸 작품 인식 및 AI 도슨트
| 화면 이미지 | 주요 기능 및 설명 |
| :---: | :--- |
| <img src="https://github.com/user-attachments/assets/5e10d3de-bb1c-445b-98f4-57b15631cf46" width="180"/> <img src="https://github.com/user-attachments/assets/0e7713be-d1e3-40ff-945d-549e87ac8fba" width="180"/> | **카메라 기반 작품 인식 & 해설**<br><br> - **실시간 스캐닝**: 카메라로 작품을 비추면 AI 서버(FastAPI)가 실시간으로 작품 정보 판별<br> - **맞춤형 해설**: 사용자 설정에 따른 **난이도별(어린이/일반/전문가)** 텍스트 해설 제공<br> - **TTS 서비스**: 인식된 해설 내용을 음성으로 변환하여 오디오 가이드 제공<br> - **북마크**: 마음에 드는 작품을 즉시 저장하여 나중에 다시 확인 가능 |

### 🕶️ AR 도슨트 서비스
| 화면 이미지 | 주요 기능 및 설명 |
| :---: | :--- |
| <img src="https://github.com/user-attachments/assets/0641d15e-f4ab-45eb-b89f-9255f46a8e8e" width="180"/> | **AR 작품 도슨트 (AR Docent)**<br><br> - **인터랙티브 포인트**: Vuforia를 통해 작품 내 핵심 감상 포인트를 AR 마커로 시각화<br> - **몰입형 경험**: 실제 작품 위에 오버레이되는 디지털 정보를 통해 깊이 있는 작품 감상 지원 |

### 🎫 마이페이지 및 커뮤니티
| 화면 이미지 | 주요 기능 및 설명 |
| :---: | :--- |
| <img src="https://github.com/user-attachments/assets/be292214-203a-453e-97e4-1598736d4f7e" width="180"/> | **북마크 및 디지털 티켓**<br><br> - **개인 보관함**: 저장한 작품들을 한눈에 모아보고 다시 감상할 수 있는 북마크 기능<br> - **디지털 티켓**: 북마크한 작품이나 관람 전시를 고유한 디자인의 **디지털 티켓**으로 자동 생성 및 소장 |
| <img src="https://github.com/user-attachments/assets/5c9e5e78-6c8a-4860-a8d6-f584d5e865fe" width="180"/> | **커뮤니티 (Community)**<br><br> - **사용자 소통**: 전시 후기 공유, 정보 교환 등 사용자 간 자유로운 커뮤니케이션 공간 제공<br> - **상호작용**: 게시글 작성, 댓글, 좋아요 기능을 통한 예술 커뮤니티 활성화 |

---

## 📈 향후 개선 사항 (Future Improvements)

| 분류 | 내용 |
| :--- | :--- |
| **성능 최적화** | Redis 캐싱 도입을 통한 DB 부하 감소 및 조회 성능 향상 |
| **인프라** | Prometheus & Grafana를 활용한 서버 모니터링 시스템 구축 |
| **AI 고도화** | 사용자 행동 패턴 분석을 통한 딥러닝 기반 맞춤형 추천 엔진 도입 |
| **사용성 개선** | 글로벌 사용자를 위한 다국어 자동 번역 및 로컬라이징 지원 |

---

## 📥 애플리케이션 다운로드

지금 바로 App Store에서 **Musai**를 만나보세요!

<a href="https://apps.apple.com/kr/app/musai/id6753198681?l=en-GB">
  <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" width="160">
</a>


