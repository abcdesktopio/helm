#!/bin/bash
set -euo pipefail

stop_flag=0
RESULTS=""

GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITHUB_REPO="${GITHUB_REPO:-}"

HELM_VERSION=$(grep appVersion "$1/Chart.yaml" | grep -Eo '[0-9]+\.[0-9]+')

ISSUE_TITLE="Helm ${HELM_VERSION} image validation failed"


tmp=$(mktemp)

echo "| Status | Image |" > "$tmp"
echo "|--------|--------|" >> "$tmp"

echo "helm: $HELM_VERSION"

# --- Collect results ---
while read img; do
  if docker manifest inspect "$img" > /dev/null; then
    echo "[OK] $img"
    echo "| ✅ | \`$img\` |" >> "$tmp"
  else
    echo "[KO] $img"

    echo "| ❌ | \`$img\` |" >> "$tmp"
    stop_flag=1
  fi
done < <(
  grep -Eo "ghcr\.io/[a-zA-Z0-9._/-]+:[a-zA-Z0-9._-]+" "$1/values.yaml"
  awk '
  /image:/ {
      img=$2
      gsub(/'\''|"/, "", img)

      if (img ~ /:/) {
          print img
      } else {
          getline
          if ($1 ~ /tag:/) {
              tag=$2
              gsub(/'\''|"/, "", tag)
              print img ":" tag
          }
      }
  }' "$1/values.yaml"
)

# --- GitHub helpers ---
gh_api() {
  curl -s \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "$@"
}

find_issue() {
  #gh_api "https://api.github.com/repos/$GITHUB_REPO/issues?state=open" \
  gh_api "https://api.github.com/repos/$GITHUB_REPO/issues" \
    | grep -B5 "\"title\": \"$ISSUE_TITLE\"" \
    | grep '"number":' \
    | head -n1 \
    | grep -Eo '[0-9]+'
}

create_issue() {
  gh_api -X POST "https://api.github.com/repos/$GITHUB_REPO/issues" \
    -d "$(jq -n \
      --arg title "$ISSUE_TITLE" \
      --arg body "$1" \
      '{title:$title, body:$body, labels:["bug"]}')"
}

comment_issue() {
  local number=$1
  gh_api -X POST "https://api.github.com/repos/$GITHUB_REPO/issues/$number/comments" \
    -d "$(jq -n --arg body "$2" '{body:$body}')"
}

close_issue() {
  local number=$1
  gh_api -X PATCH "https://api.github.com/repos/$GITHUB_REPO/issues/$number" \
    -d '{"state":"closed"}'
}

reopen_issue() {
  local number=$1
  gh_api -X PATCH "https://api.github.com/repos/$GITHUB_REPO/issues/$number" \
    -d '{"state":"open"}'
}

add_to_project() {
    local issue_number=$1
    ISSUE_NODE_ID=$(gh api repos/$GITHUB_REPO/issues/$issue_number --jq '.node_id')
}

# --- Main logic ---
ISSUE_NUMBER=$(find_issue || true)


RESULTS=$(cat "$tmp")
rm -f "$tmp"

if [ "$stop_flag" = "1" ]; then
#  BODY="# Helm version: $HELM_VERSION\n\n## Results:$RESULTS"

BODY=$(cat <<EOF
## 🐳 Image validation report for helm $HELM_VERSION

### Results

$RESULTS

---

$( [ "$stop_flag" = "1" ] && echo "❌ **Some images are invalid**" || echo "✅ **All images are valid**" )
EOF
)


  if [ -z "$ISSUE_NUMBER" ]; then
    echo "Creating new issue"
    ISSUE_NUMBER=$(create_issue "$BODY" | jq -r '.number')
    add_to_project "$ISSUE_NUMBER"

  else

    STATE=$(gh_api "https://api.github.com/repos/$GITHUB_REPO/issues/$ISSUE_NUMBER" | jq -r '.state')
    if [ "$STATE" = "closed" ]; then
      echo "Reopening issue #$ISSUE_NUMBER"
      reopen_issue "$ISSUE_NUMBER"
    fi


    echo "Commenting existing issue #$ISSUE_NUMBER"
    comment_issue "$ISSUE_NUMBER" "$BODY"
  fi

  exit 1

else
  echo "All OK"

  if [ -n "$ISSUE_NUMBER" ]; then
    echo "Closing issue #$ISSUE_NUMBER"
    comment_issue "$ISSUE_NUMBER" "All image references are now valid ✅"
    close_issue "$ISSUE_NUMBER"
  fi
fi