# Godot 기술 구조

## 선택

Godot 4와 GDScript 기반의 2D 프로젝트를 사용한다.

- `Compatibility` 렌더러: 데스크톱·모바일·웹 호환성 우선
- `Control` UI: 4:3 장면과 반응형 인벤토리
- JSON 콘텐츠: 챕터·퍼즐 내용을 코드에서 분리
- `user://` JSON 저장: 프로토타입 자동 저장
- 플랫폼 Export Preset: Windows, macOS, Android, iOS, Web

## 런타임 계층

```text
content/chapters/*.json
          ↓
챕터·퍼즐 정의와 검증
          ↓
게임 상태 / 조건·효과 실행기 ── 저장 시스템
          ↓
Godot Scene / Control UI / Audio
          ↓
Compatibility 렌더러와 플랫폼별 Export
```

## 현재 프로토타입

```text
project.godot
export_presets.cfg
scenes/
└── main.tscn
scripts/
├── game.gd
├── room_art.gd
└── save_manager.gd
tests/
└── smoke_test.gd
content/
├── manifest.json
├── chapters/
└── schema/
```

- `game.gd`: 전체 흐름을 한눈에 파악하기 위한 프로토타입 통합 스크립트
- `room_art.gd`: 외부 이미지 없이 장면을 표시하는 임시 도형 아트
- `save_manager.gd`: 로컬 저장과 스키마 버전 확인
- `smoke_test.gd`: 첫 편지부터 물약 완성까지 자동 진행 검증

## 본 제작 전환 구조

```text
scenes/
├── app/
│   ├── boot.tscn
│   └── main.tscn
├── pharmacy/
├── rooms/
│   ├── childhood/
│   ├── school/
│   └── adulthood/
└── ending/
scripts/
├── domain/
├── systems/
│   ├── inventory/
│   ├── interaction/
│   ├── puzzle/
│   ├── dialogue/
│   ├── audio/
│   └── save/
└── ui/
content/
├── chapters/
├── dialogue/
└── schema/
assets/
├── backgrounds/
├── objects/
├── items/
├── ui/
├── audio/
└── video/
```

방마다 전체 시스템을 복제하지 않는다. 공통 Room Controller가 챕터 JSON을 읽어 방향, 배경, 핫스폿과 퍼즐 조건을 구성한다.

## 상태 모델

저장 데이터에는 노드 자체가 아니라 복원 가능한 값만 기록한다.

```gdscript
{
    "schema_version": 1,
    "current_place": "childhood",
    "direction_index": 2,
    "inventory": ["needle", "thread"],
    "flags": {
        "letter_opened": true,
        "bear_collected": true
    }
}
```

`schema_version`은 기획 변경 후 기존 저장을 변환하거나 안전하게 초기화하기 위해 유지한다.

## 좌표와 화면

- 논리 장면: 1600×1200, 4:3
- 전체 프로젝트 기준: 1600×900
- 남은 가로 공간: 인벤토리와 메뉴
- 핫스폿: 0~1 정규화 좌표
- Stretch Mode: `canvas_items`
- 작은 화면에서도 장면을 임의 크롭하지 않음
- 터치 대상은 시각 아이콘보다 넓게 설정

세부 배치와 입력 상태는 `ui-spec.md`를 기준으로 한다.

## 퍼즐 모델

본 제작에서는 각 행동을 조건과 효과로 해석한다.

```json
{
  "id": "puzzle_repair_bear",
  "when": [
    { "type": "hasItem", "itemId": "item_needle" },
    { "type": "hasItem", "itemId": "item_thread" }
  ],
  "effects": [
    { "type": "removeItem", "itemId": "item_needle" },
    { "type": "removeItem", "itemId": "item_thread" },
    {
      "type": "replaceItem",
      "from": "item_torn_bear",
      "to": "item_repaired_bear"
    }
  ]
}
```

JSON 안에서 임의 GDScript 코드를 실행하지 않는다. 엔진이 허용한 조건과 효과만 해석한다.

## 내보내기

- Windows: `.exe`와 `.pck`
- macOS: Universal `.app` 또는 `.zip`
- Android: `.apk`, 출시 시 `.aab`
- iOS/iPadOS: Xcode 프로젝트
- Web: WebAssembly/WebGL 2

실제 내보내기에는 해당 Godot Export Template이 필요하다. iOS 배포에는 macOS, Xcode와 Apple 개발자 서명이 추가로 필요하다.

## 검증

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/smoke_test.gd
node tools/validate-content.mjs
```

필수 검사:

- 모든 GDScript 파싱과 시작 장면 로드
- 첫 편지부터 물약 조제까지 전체 상태 경로
- JSON의 아이템·뷰·플래그 참조
- 저장 후 장면·인벤토리·플래그 복원
- 마우스·터치·키보드 입력
- 실제 iPad와 휴대전화의 안전 영역 및 화면 회전

## 성능 원칙

- 첫 화면에는 약방 공통 자산만 로드한다.
- 편지 선택 후 해당 챕터 자산을 백그라운드 로드한다.
- 완료한 챕터의 대형 텍스처와 오디오를 해제한다.
- 배경은 WebP, 투명 오브젝트는 WebP 또는 PNG를 사용한다.
- 영상은 플랫폼별 코덱 지원을 확인하고 스킵 기능을 제공한다.
