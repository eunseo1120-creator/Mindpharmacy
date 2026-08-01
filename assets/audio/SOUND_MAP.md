# 현재 사운드 매핑

모든 효과음은 상업적 사용이 가능한 Kenney CC0 팩에서 가져왔습니다. 게임 안에서 알아보기 쉬운 이름으로 변경했으며, 원본 팩 파일명은 아래와 같습니다.

| 게임 파일 | 원본 팩 | 원본 파일 | 현재 사용처 |
|---|---|---|---|
| `ui-click.ogg` | Interface Sounds | `click_002.ogg` | 일반 버튼과 핫스폿 선택 |
| `ui-back.ogg` | Interface Sounds | `back_002.ogg` | 클로즈업에서 방으로 돌아가기 |
| `room-turn.ogg` | Interface Sounds | `back_003.ogg` | 방의 왼쪽·오른쪽 화면 전환 |
| `item-pickup.ogg` | Interface Sounds | `select_004.ogg` | 일반 아이템 획득 |
| `paper-pickup.ogg` | RPG Audio | `bookFlip1.ogg` | 쪽지와 동화책 페이지 획득 |
| `book-open.ogg` | RPG Audio | `bookOpen.ogg` | 책과 그림일기 열기 |
| `page-turn.ogg` | RPG Audio | `bookFlip2.ogg` | 그림일기·동화책 페이지 넘기기 |
| `drawer-open.ogg` | RPG Audio | `creak1.ogg` | 서랍 열기 |
| `wardrobe-open.ogg` | RPG Audio | `doorOpen_1.ogg` | 옷장 열기 |
| `sewing.ogg` | RPG Audio | `cloth4.ogg` | 곰인형 바느질 |
| `soft-place.ogg` | Impact Sounds | `impactSoft_medium_001.ogg` | 곰인형을 침대 밑에 놓기 |
| `wood-connect.ogg` | Impact Sounds | `impactWood_light_002.ogg` | 목제 기차 블록 결합 |
| `train-run.ogg` | Impact Sounds | `impactWood_medium_001.ogg` | 장난감 기차가 레일을 달리기 |
| `metal-click.ogg` | RPG Audio | `metalClick.ogg` | 금속 장치 조작 |
| `lock-latch.ogg` | RPG Audio | `metalLatch.ogg` | 잠금장치 해제 |
| `door-open.ogg` | RPG Audio | `doorOpen_2.ogg` | 문 열기 |
| `keypad-tick.ogg` | Interface Sounds | `tick_002.ogg` | 신발장 비밀번호·전화 다이얼 입력 |
| `tv-button.ogg` | Interface Sounds | `switch_005.ogg` | 리모컨과 TV 볼륨 조작 |
| `combine.ogg` | Interface Sounds | `confirmation_003.ogg` | 인벤토리 아이템 조합 성공 |
| `crystal.ogg` | Interface Sounds | `glass_006.ogg` | 용기 크리스탈 생성·획득 |
| `potion.ogg` | Interface Sounds | `glass_003.ogg` | 약방에서 감정 조제 |
| `error.ogg` | Interface Sounds | `error_001.ogg` | 잘못된 입력·조합 |

이전 방 전환음은 `scroll_003.ogg`였으며, 1초 동안 여러 틱이 연속된 소리라서 한 번 눌러도 빠르게 반복되는 것처럼 들렸습니다. 현재는 짧은 단일음인 `back_003.ogg`로 교체했고, 방 전환음에는 160ms 재생 간격 제한을 적용했습니다.

## 배경음

| 게임 파일 | 원곡 | 제작자 | 라이선스 | 사용처 |
|---|---|---|---|---|
| `pharmacy-ambient.ogg` | Heavenly Loop | isaiah658 | CC0 1.0 | 약방 |
| `childhood-ambient.ogg` | Contemplation | Joth | CC0 1.0 | 유년기 방 |

출처 URL과 라이선스 세부 정보는 `ATTRIBUTION.md`를 참고하세요.
