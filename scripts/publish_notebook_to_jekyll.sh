#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $(basename "$0") NOTEBOOK.ipynb --site /path/to/jekyll-site [options]

Required:
  NOTEBOOK.ipynb               Path to source notebook
  --site PATH                  Path to Jekyll site root (must contain _posts)

Options:
  --title TEXT                 Post title (default: derived from notebook name)
  --slug TEXT                  URL slug (default: derived from notebook name)
  --date YYYY-MM-DD            Post date (default: today)
  --categories CSV             Categories, comma-separated (default: llm,fundamentals)
  --tags CSV                   Tags, comma-separated (default: none)
  --layout NAME                Jekyll layout (default: post)

Example:
  $(basename "$0") 01_foundations_attention_embeddings.ipynb \\
    --site ~/GitHub/my-jekyll-site \\
    --title "Lesson 01: Foundations - Attention and Embeddings" \\
    --categories "llm,fundamentals,transformers" \\
    --tags "embeddings,attention"
USAGE
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' not found." >&2
    exit 1
  fi
}

slugify() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

csv_to_yaml_list() {
  local input="$1"
  local out=""
  IFS=',' read -r -a parts <<< "$input"
  for p in "${parts[@]}"; do
    local trimmed
    trimmed="$(echo "$p" | sed -E 's/^\s+//; s/\s+$//')"
    if [[ -n "$trimmed" ]]; then
      out+="  - ${trimmed}"$'\n'
    fi
  done
  echo -n "$out"
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

NOTEBOOK=""

if [[ "${1:-}" != --* ]]; then
  NOTEBOOK="$1"
  shift
fi

SITE_DIR=""
TITLE=""
SLUG=""
POST_DATE="$(date +%F)"
CATEGORIES="llm,fundamentals"
TAGS=""
LAYOUT="post"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --site)
      SITE_DIR="$2"
      shift 2
      ;;
    --title)
      TITLE="$2"
      shift 2
      ;;
    --slug)
      SLUG="$2"
      shift 2
      ;;
    --date)
      POST_DATE="$2"
      shift 2
      ;;
    --categories)
      CATEGORIES="$2"
      shift 2
      ;;
    --tags)
      TAGS="$2"
      shift 2
      ;;
    --layout)
      LAYOUT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$SITE_DIR" ]]; then
  echo "Error: --site is required." >&2
  usage
  exit 1
fi

if [[ -z "$NOTEBOOK" ]]; then
  echo "Error: notebook path is required." >&2
  usage
  exit 1
fi

if [[ ! -f "$NOTEBOOK" ]]; then
  echo "Error: notebook not found: $NOTEBOOK" >&2
  exit 1
fi

if [[ ! -d "$SITE_DIR/_posts" ]]; then
  echo "Error: '$SITE_DIR' does not look like a Jekyll site (missing _posts)." >&2
  exit 1
fi

require_cmd python
NB_CONVERT_CMD=()

if command -v jupyter >/dev/null 2>&1; then
  NB_CONVERT_CMD=(jupyter nbconvert)
elif python - <<'PY' >/dev/null 2>&1
import nbconvert  # noqa: F401
PY
then
  NB_CONVERT_CMD=(python -m nbconvert)
else
  echo "Error: neither 'jupyter' nor Python module 'nbconvert' is available." >&2
  exit 1
fi

NOTEBOOK_ABS="$(cd "$(dirname "$NOTEBOOK")" && pwd)/$(basename "$NOTEBOOK")"
BASE_NAME="$(basename "$NOTEBOOK" .ipynb)"

if [[ -z "$TITLE" ]]; then
  TITLE="$(python - <<PY
base = "$BASE_NAME"
base = __import__("re").sub(r"^\\d+[_\\.-]?", "", base)
words = __import__("re").split(r"[_-]+", base)
print(" ".join(w.capitalize() for w in words if w))
PY
)"
fi

if [[ -z "$SLUG" ]]; then
  SLUG="$(slugify "$BASE_NAME")"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

"${NB_CONVERT_CMD[@]}" --to markdown "$NOTEBOOK_ABS" --output-dir "$TMP_DIR" >/dev/null

NB_MD="$TMP_DIR/$BASE_NAME.md"
NB_ASSETS_DIR="$TMP_DIR/${BASE_NAME}_files"

if [[ ! -f "$NB_MD" ]]; then
  echo "Error: nbconvert output not found: $NB_MD" >&2
  exit 1
fi

POST_FILE="$SITE_DIR/_posts/${POST_DATE}-${SLUG}.md"
ASSET_DIR="$SITE_DIR/assets/notebooks/$SLUG"
mkdir -p "$ASSET_DIR"

python - <<PY
from pathlib import Path
src = Path(r"$NB_MD")
text = src.read_text(encoding="utf-8")
text = text.replace(r"${BASE_NAME}_files/", r"/assets/notebooks/$SLUG/")
Path(r"$TMP_DIR/body.md").write_text(text, encoding="utf-8")
PY

if [[ -d "$NB_ASSETS_DIR" ]]; then
  cp -R "$NB_ASSETS_DIR"/. "$ASSET_DIR/"
fi

cp "$NOTEBOOK_ABS" "$ASSET_DIR/$BASE_NAME.ipynb"

{
  echo "---"
  echo "layout: $LAYOUT"
  echo "title: \"$TITLE\""
  echo "date: ${POST_DATE}"
  echo "categories:"
  csv_to_yaml_list "$CATEGORIES"
  if [[ -n "$TAGS" ]]; then
    echo "tags:"
    csv_to_yaml_list "$TAGS"
  fi
  echo "---"
  echo
  cat "$TMP_DIR/body.md"
  echo
  echo "[Download notebook (.ipynb)](/assets/notebooks/$SLUG/$BASE_NAME.ipynb)"
} > "$POST_FILE"

echo "Published: $POST_FILE"
echo "Assets:    $ASSET_DIR"
