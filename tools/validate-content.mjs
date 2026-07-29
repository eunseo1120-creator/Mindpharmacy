import { readFile, readdir } from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const projectRoot = process.cwd();
const chaptersDirectory = path.join(projectRoot, "content", "chapters");
const files = (await readdir(chaptersDirectory))
  .filter((name) => name.endsWith(".json"))
  .sort();

let errorCount = 0;
let warningCount = 0;

function report(file, message) {
  errorCount += 1;
  console.error(`${file}: ${message}`);
}

function warn(file, message) {
  warningCount += 1;
  console.warn(`${file}: 경고: ${message}`);
}

function findDuplicates(values) {
  const seen = new Set();
  return values.filter((value) => {
    if (seen.has(value)) return true;
    seen.add(value);
    return false;
  });
}

function checkItemReference(file, itemIds, itemId, location) {
  if (!itemIds.has(itemId)) {
    report(file, `${location}가 존재하지 않는 아이템 '${itemId}'을 참조합니다.`);
  }
}

for (const file of files) {
  const relativeFile = path.join("content", "chapters", file);
  const chapter = JSON.parse(
    await readFile(path.join(chaptersDirectory, file), "utf8")
  );

  const viewIds = new Set(chapter.views.map((view) => view.id));
  const itemIds = new Set(chapter.items.map((item) => item.id));
  const producedFlags = new Set();
  const producedItems = new Set();
  const requiredItems = new Set();
  const requiredTrueFlags = new Set();
  const allIds = [
    chapter.id,
    ...chapter.views.map((view) => view.id),
    ...chapter.items.map((item) => item.id),
    ...chapter.puzzles.map((puzzle) => puzzle.id),
    ...chapter.views.flatMap((view) =>
      view.hotspots.flatMap((hotspot) => [
        hotspot.id,
        ...hotspot.interactions.map((interaction) => interaction.id)
      ])
    )
  ];

  for (const duplicate of new Set(findDuplicates(allIds))) {
    report(relativeFile, `중복 ID '${duplicate}'이 있습니다.`);
  }

  if (!viewIds.has(chapter.startViewId)) {
    report(relativeFile, `startViewId '${chapter.startViewId}'가 존재하지 않습니다.`);
  }

  for (const view of chapter.views) {
    for (const hotspot of view.hotspots) {
      const { x, y, width, height } = hotspot.bounds;
      if ([x, y, width, height].some((value) => typeof value !== "number")) {
        report(relativeFile, `${hotspot.id}의 bounds 값은 모두 숫자여야 합니다.`);
      } else if (
        x < 0 ||
        y < 0 ||
        width <= 0 ||
        height <= 0 ||
        x + width > 1 ||
        y + height > 1
      ) {
        report(relativeFile, `${hotspot.id}의 bounds가 0~1 화면 범위를 벗어납니다.`);
      }

      for (const interaction of hotspot.interactions) {
        if (interaction.trigger === "useItem" && !interaction.itemId) {
          report(relativeFile, `${interaction.id}에 itemId가 없습니다.`);
        }
        if (interaction.itemId) {
          checkItemReference(
            relativeFile,
            itemIds,
            interaction.itemId,
            interaction.id
          );
        }
        inspectRules(relativeFile, interaction.when ?? [], interaction.effects);
      }
    }
  }

  for (const puzzle of chapter.puzzles) {
    if (puzzle.hints.length !== 3) {
      report(relativeFile, `${puzzle.id}의 힌트는 정확히 3단계여야 합니다.`);
    }
    inspectRules(relativeFile, puzzle.when, puzzle.effects);
  }

  function inspectRules(fileName, conditions, effects) {
    for (const condition of conditions) {
      if (condition.type === "hasItem") {
        checkItemReference(fileName, itemIds, condition.itemId, "조건");
        requiredItems.add(condition.itemId);
      }
      if (condition.type === "flagEquals" && condition.value === true) {
        requiredTrueFlags.add(condition.flag);
      }
    }
    for (const effect of effects) {
      if (effect.type === "addItem" || effect.type === "removeItem") {
        checkItemReference(fileName, itemIds, effect.itemId, "효과");
        if (effect.type === "addItem") producedItems.add(effect.itemId);
      }
      if (effect.type === "replaceItem") {
        checkItemReference(fileName, itemIds, effect.from, "교체 효과");
        checkItemReference(fileName, itemIds, effect.to, "교체 효과");
        requiredItems.add(effect.from);
        producedItems.add(effect.to);
      }
      if (effect.type === "goToView" && !viewIds.has(effect.viewId)) {
        report(fileName, `이동 대상 뷰 '${effect.viewId}'가 존재하지 않습니다.`);
      }
      if (effect.type === "setFlag" && effect.value === true) {
        producedFlags.add(effect.flag);
      }
    }
  }

  for (const requiredFlag of chapter.completion.requiredFlags) {
    if (!producedFlags.has(requiredFlag)) {
      report(
        relativeFile,
        `완료 플래그 '${requiredFlag}'를 생성하는 상호작용이 없습니다.`
      );
    }
  }

  for (const itemId of requiredItems) {
    if (!producedItems.has(itemId)) {
      warn(
        relativeFile,
        `필요 아이템 '${itemId}'을 획득·생성하는 효과가 아직 없습니다.`
      );
    }
  }

  for (const flag of requiredTrueFlags) {
    if (!producedFlags.has(flag)) {
      warn(
        relativeFile,
        `필요 플래그 '${flag}'를 true로 만드는 효과가 아직 없습니다.`
      );
    }
  }

  if (errorCount === 0) {
    console.log(`${relativeFile}: 기본 참조 및 완료 조건 검증 통과`);
  }
}

if (files.length === 0) {
  console.error("검증할 챕터 JSON이 없습니다.");
  process.exit(1);
}

if (errorCount > 0) {
  console.error(`검증 실패: ${errorCount}개 오류`);
  process.exit(1);
}

console.log(
  `검증 완료: ${files.length}개 챕터, 오류 ${errorCount}개, 미확정 경고 ${warningCount}개`
);
