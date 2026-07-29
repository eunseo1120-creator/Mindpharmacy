#!/usr/bin/env python3
"""Create a deterministic, review-friendly snapshot of an Ideation DOCX."""

from __future__ import annotations

import argparse
import datetime as dt
import difflib
import hashlib
import json
from pathlib import Path
import re
import sys
import zipfile
import xml.etree.ElementTree as ET


WORD_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
CORE_NS = "http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
DC_NS = "http://purl.org/dc/elements/1.1/"
DCTERMS_NS = "http://purl.org/dc/terms/"
REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
NS = {"w": WORD_NS, "cp": CORE_NS, "dc": DC_NS, "dcterms": DCTERMS_NS}


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def normalized_text(element: ET.Element) -> str:
    parts: list[str] = []
    for node in element.iter():
        if node.tag == f"{{{WORD_NS}}}t" and node.text:
            parts.append(node.text)
        elif node.tag == f"{{{WORD_NS}}}tab":
            parts.append("\t")
        elif node.tag in {f"{{{WORD_NS}}}br", f"{{{WORD_NS}}}cr"}:
            parts.append("\n")
    text = "".join(parts)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def extract_paragraphs(xml_bytes: bytes) -> list[str]:
    root = ET.fromstring(xml_bytes)
    paragraphs: list[str] = []
    for paragraph in root.findall(".//w:p", NS):
        text = normalized_text(paragraph)
        if text:
            paragraphs.append(text)
    return paragraphs


def extract_properties(archive: zipfile.ZipFile) -> dict[str, str]:
    if "docProps/core.xml" not in archive.namelist():
        return {}
    root = ET.fromstring(archive.read("docProps/core.xml"))
    candidates = {
        "title": ("dc", "title"),
        "creator": ("dc", "creator"),
        "created": ("dcterms", "created"),
        "modified": ("dcterms", "modified"),
        "lastModifiedBy": ("cp", "lastModifiedBy"),
        "revision": ("cp", "revision"),
    }
    properties: dict[str, str] = {}
    for key, (prefix, name) in candidates.items():
        node = root.find(f"{prefix}:{name}", NS)
        if node is not None and node.text:
            properties[key] = node.text
    return properties


def extract_external_links(archive: zipfile.ZipFile) -> list[str]:
    rel_file = "word/_rels/document.xml.rels"
    if rel_file not in archive.namelist():
        return []
    root = ET.fromstring(archive.read(rel_file))
    links = {
        node.attrib["Target"]
        for node in root.findall(f"{{{REL_NS}}}Relationship")
        if node.attrib.get("TargetMode") == "External"
        and node.attrib.get("Target", "").startswith(("http://", "https://"))
    }
    return sorted(links)


def create_snapshot(docx: Path) -> dict:
    raw = docx.read_bytes()
    with zipfile.ZipFile(docx) as archive:
        if "word/document.xml" not in archive.namelist():
            raise ValueError("유효한 Word 문서 본문을 찾을 수 없습니다.")

        paragraphs = extract_paragraphs(archive.read("word/document.xml"))
        media = []
        for name in sorted(
            entry for entry in archive.namelist() if entry.startswith("word/media/")
        ):
            data = archive.read(name)
            media.append(
                {
                    "name": Path(name).name,
                    "bytes": len(data),
                    "sha256": sha256_bytes(data),
                }
            )

        return {
            "snapshotVersion": 1,
            "capturedAt": dt.datetime.now(dt.timezone.utc).isoformat(),
            "source": {
                "fileName": docx.name,
                "bytes": len(raw),
                "sha256": sha256_bytes(raw),
            },
            "documentProperties": extract_properties(archive),
            "paragraphCount": len(paragraphs),
            "paragraphs": paragraphs,
            "externalLinks": extract_external_links(archive),
            "embeddedMediaCount": len(media),
            "embeddedMedia": media,
        }


def load_existing_snapshots(output_dir: Path) -> list[tuple[Path, dict]]:
    snapshots: list[tuple[Path, dict]] = []
    for path in output_dir.glob("*.json"):
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if payload.get("snapshotVersion") == 1 and "source" in payload:
            snapshots.append((path, payload))
    return sorted(
        snapshots,
        key=lambda item: item[1].get("capturedAt", ""),
    )


def print_diff(previous: dict, current: dict) -> None:
    old_hash = previous["source"]["sha256"]
    new_hash = current["source"]["sha256"]
    if old_hash == new_hash:
        print("변경 없음: DOCX 해시가 이전 스냅샷과 같습니다.")
        return

    old_paragraphs = previous.get("paragraphs", [])
    new_paragraphs = current.get("paragraphs", [])
    added = 0
    removed = 0
    print("문단 변경:")
    for line in difflib.unified_diff(
        old_paragraphs,
        new_paragraphs,
        fromfile=previous["source"].get("fileName", "previous"),
        tofile=current["source"].get("fileName", "current"),
        lineterm="",
        n=1,
    ):
        if line.startswith("+") and not line.startswith("+++"):
            added += 1
        elif line.startswith("-") and not line.startswith("---"):
            removed += 1
        print(line)

    old_media = {item["sha256"] for item in previous.get("embeddedMedia", [])}
    new_media = {item["sha256"] for item in current.get("embeddedMedia", [])}
    print(
        "요약: "
        f"문단 +{added}/-{removed}, "
        f"이미지 +{len(new_media - old_media)}/-{len(old_media - new_media)}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Ideation DOCX의 텍스트·이미지·해시 스냅샷을 생성합니다."
    )
    parser.add_argument("docx", type=Path)
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("docs/ideation-snapshots"),
    )
    parser.add_argument(
        "--no-diff",
        action="store_true",
        help="직전 스냅샷과의 문단 차이 출력을 생략합니다.",
    )
    args = parser.parse_args()

    if not args.docx.is_file():
        parser.error(f"파일이 없습니다: {args.docx}")
    if args.docx.suffix.lower() != ".docx":
        parser.error("입력 파일은 .docx여야 합니다.")

    args.output_dir.mkdir(parents=True, exist_ok=True)
    existing = load_existing_snapshots(args.output_dir)
    snapshot = create_snapshot(args.docx)

    identical = next(
        (
            path
            for path, payload in existing
            if payload["source"]["sha256"] == snapshot["source"]["sha256"]
        ),
        None,
    )
    if identical:
        print(f"동일 스냅샷이 이미 존재합니다: {identical}")
        if existing and not args.no_diff:
            print_diff(existing[-1][1], snapshot)
        return 0

    timestamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    short_hash = snapshot["source"]["sha256"][:12]
    destination = args.output_dir / f"{timestamp}-{short_hash}.json"
    destination.write_text(
        json.dumps(snapshot, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"스냅샷 생성: {destination}")
    print(
        f"문단 {snapshot['paragraphCount']}개, "
        f"이미지 {snapshot['embeddedMediaCount']}개, "
        f"외부 링크 {len(snapshot['externalLinks'])}개"
    )

    if existing and not args.no_diff:
        print_diff(existing[-1][1], snapshot)
    else:
        print("이전 스냅샷이 없어 최초 기준선으로 저장했습니다.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (zipfile.BadZipFile, ET.ParseError, ValueError) as error:
        print(f"DOCX 분석 실패: {error}", file=sys.stderr)
        raise SystemExit(1)
