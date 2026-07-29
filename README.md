# 마음 약방 — Godot 프로토타입

Rusty Lake 계열의 정적 2D 포인트앤클릭 문법을 참고한 멀티플랫폼 추리·방탈출 게임 프로젝트.

> 참고 대상의 게임 문법만 연구하며, Rusty Lake의 그림·캐릭터·아이콘·음원·문구·고유 UI는 복제하지 않는다.

![마음 약방 유년기 방 프로토타입](assets/backgrounds/childhood/front.png)

## 목표 플랫폼

- 설치형: Windows, macOS, Android, iOS/iPadOS
- 선택 배포: WebAssembly/WebGL 2 기반 웹 빌드
- 기본 화면 비율: 4:3
- 모바일 기본 플레이 방향: 가로

## 구현 기술

- Godot 4.7.1+
- GDScript
- Compatibility 렌더러
- `user://` JSON 자동 저장

바로 실행 가능한 흐름과 조작법은 [Godot 프로토타입 안내](docs/prototype-guide.md)를 참고한다.

현재 프로토타입에는 약방 프롤로그, 유년기·청소년기·성인기 세 기억의 방, 진실의 방과 엔딩까지 하나의 플레이 흐름으로 구현되어 있다. 각 공간에는 같은 드림코어 3D 페인터리 스타일의 4방향 배경이 연결되어 있으며, 퍼즐 오브젝트는 투명 PNG 에셋으로 분리되어 있다.

## 문서

- [게임 설계](docs/game-design.md)
- [전체 챕터 상세 설계](docs/full-chapter-blueprint.md)
- [팀 공유용 Word 설계서](docs/mind-pharmacy-full-chapter-blueprint.docx)
- [기술 구조](docs/technical-architecture.md)
- [반응형 UI 명세](docs/ui-spec.md)
- [MVP·플랫폼 검수 계획](docs/mvp-platform-plan.md)
- [콘텐츠 작성 규칙](docs/content-authoring.md)
- [자산 목록](docs/asset-checklist.md)

## 콘텐츠와 플레이 흐름

- `content/schema/chapter.schema.json`: 챕터 JSON 형식
- `content/chapters/childhood.json`: 유아기 데이터 구조 예시
- `content/manifest.json`: 게임이 불러올 챕터 목록
- `tools/validate-content.mjs`: ID·아이템·뷰·완료 조건 검사
- `tools/snapshot_ideation.py`: DOCX 버전 스냅샷과 문단·이미지 차이 검사

검증:

```bash
node tools/validate-content.mjs
```

새 Ideation 파일 기록:

```bash
python tools/snapshot_ideation.py /path/to/ideation.docx
```

## 다음 개발 순서

1. 전체 흐름과 퍼즐 난이도를 팀이 함께 플레이테스트한다.
2. 코드 기반 방 그림을 최종 4:3 배경과 상태별 오브젝트 이미지로 교체한다.
3. 콘텐츠 정의를 JSON 기반 런타임으로 이전해 기획과 코드의 결합을 낮춘다.
4. 설정에 콘텐츠 경고, 음향·화면 효과 감소, 도움 정보 화면을 추가한다.
5. 플랫폼별 내보내기와 모바일 터치 QA를 완료한다.

## Ideation 업데이트 원칙

`ideation.docx`는 자유로운 기획 원본으로 유지한다. 개발에 반영하기로 확정된 내용만 이 저장소의 Markdown 명세와 JSON 콘텐츠로 옮긴다. 각 변경에는 `docs/ideation-changelog.md`에 날짜, 변경 이유, 영향받는 챕터와 자산을 기록한다.
