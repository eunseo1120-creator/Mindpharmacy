# 콘텐츠 작성 규칙

## 문서 역할

- `ideation.docx`: 아이디어, 참고 이미지, 미확정 스토리
- `game-design.md`: 팀이 합의한 플레이 경험
- `content/*.json`: 게임이 실제로 실행하는 확정 콘텐츠
- `asset-checklist.md`: 제작·검수 상태
- `ideation-changelog.md`: DOCX 변경 사항과 반영 여부

## ID 규칙

ID는 영문 소문자와 밑줄만 사용한다.

```text
chapter_childhood
view_childhood_front
item_torn_bear
puzzle_repair_bear
flag_bear_repaired
dialogue_childhood_letter
```

표시 이름은 언제든 바꿀 수 있지만 ID는 저장 파일 호환성을 위해 가급적 바꾸지 않는다.

## 챕터 정의 필수 필드

```json
{
  "schemaVersion": 1,
  "id": "chapter_childhood",
  "title": "거대한 두려움의 방",
  "startViewId": "view_childhood_front",
  "views": [],
  "items": [],
  "puzzles": [],
  "completion": {
    "requiredFlags": ["flag_childhood_door_open"]
  }
}
```

## 오브젝트 정의 체크리스트

- 어느 방향에 있는가?
- 처음부터 보이는가?
- 클릭 가능한 영역은 어디인가?
- 일반 클릭과 아이템 사용 결과는 무엇인가?
- 획득, 확대, 대사, 퍼즐 시작 중 어떤 행동인가?
- 퍼즐 해결 전후 이미지가 다른가?
- 사운드와 자막이 필요한가?
- 힌트에서 어떤 이름으로 부르는가?

## 퍼즐 명세 템플릿

```text
퍼즐 ID:
표시 이름:
챕터 / 방향:
플레이 목적:
발견 단서:
필요 아이템:
입력 방식:
정답:
오답 피드백:
성공 효과:
후속 퍼즐:
힌트 1:
힌트 2:
힌트 3:
필요 이미지:
필요 소리:
접근성 대체:
```

## 변경 반영 절차

1. 새 `ideation.docx`의 스냅샷을 만들고 이전 버전과 차이를 확인한다.
2. 각 변경을 `확정`, `보류`, `폐기`로 분류한다.
3. 확정 사항만 게임 설계와 JSON에 반영한다.
4. 변경된 ID, 퍼즐 순서, 자산 목록을 검사한다.
5. 기존 저장 데이터 마이그레이션 필요 여부를 확인한다.
6. 해당 챕터를 처음부터 끝까지 다시 플레이한다.

스냅샷 생성:

```bash
python tools/snapshot_ideation.py /path/to/ideation.docx
```

이 도구는 원본 DOCX를 수정하지 않는다. 문서 전체 SHA-256, 텍스트 문단, 포함 이미지의 크기와 SHA-256, 외부 링크를 `docs/ideation-snapshots/`에 JSON으로 저장한다. 동일한 파일은 중복 저장하지 않으며, 새 버전이면 직전 스냅샷과 문단·이미지 차이를 출력한다.

스냅샷은 변경 탐지용이다. Word의 화면 배치, 도형 위치, 잘림과 페이지 나눔은 새 DOCX를 렌더링해 별도로 확인해야 한다.

## 민감 콘텐츠 검수

- 피해자의 행동을 문제의 원인처럼 묘사하지 않는다.
- 신고 전화가 모든 상황을 즉시 해결한다는 인상을 피한다.
- 도움 요청을 퍼즐의 “마법적 정답”이 아니라 현실의 지원 연결로 설명한다.
- 실제 기관명과 전화번호는 출시 직전 공식 출처로 재검증한다.
- 가능하면 관련 분야 전문가나 상담기관의 감수를 받는다.
