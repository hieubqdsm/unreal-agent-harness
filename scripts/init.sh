#!/usr/bin/env bash
# init.sh — Name a new project generated from unreal-agent-harness.
# Replaces {{PROJECT_NAME}} and {{DATE}} in every file (except itself).
# Usage:  bash scripts/init.sh "Your Game Name"
set -euo pipefail

NAME="${1:-}"
if [ -z "$NAME" ]; then
  echo 'Usage: bash scripts/init.sh "<Project name>"' >&2
  echo 'Example: bash scripts/init.sh "Detector X"' >&2
  exit 1
fi

# Characters that break sed ('/' is the delimiter, '&' = whole-match) -> reject.
if [[ "$NAME" == *['/&']* ]]; then
  echo "Name contains invalid characters ('/' or '&'). Pick another name." >&2
  exit 1
fi

DATE="$(date +%Y-%m-%d)"
SELF='./scripts/init.sh'
echo "→ Setting project name: $NAME (date $DATE)"

# Remove the template marker — from this point the repo is a valid game repo.
rm -f ./TEMPLATE

hit=0
while IFS= read -r -d '' f; do
  if grep -qF -e '{{PROJECT_NAME}}' -e '{{DATE}}' "$f"; then
    sed -i -e "s/{{PROJECT_NAME}}/$NAME/g" -e "s/{{DATE}}/$DATE/g" "$f"
    echo "  • ${f#./}"
    hit=1
  fi
done < <(find . -type f -not -path './.git/*' -not -path "$SELF" -print0)

if [ "$hit" -eq 0 ]; then
  echo "(No placeholders left — you may have already run init.)"
fi

cat <<EOF

✓ Done. Next steps:
  1. git init && git add -A && git commit -m "init project: $NAME"
     (recommended for UE binary assets: git lfs install + track *.uasset *.umap)
  2. Create the Unreal project (USER step): open Unreal → New Project at this
     directory (Games → Blank) to generate <Name>.uproject. Agent: write the
     .uproject (+ Source/ skeleton for C++ projects) directly as text, do NOT
     open the editor (AGENTS.md §0.2).
  3. Read docs/SESSION.md and follow next_action.
EOF
