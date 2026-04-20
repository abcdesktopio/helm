#! /bin/sh

set -e

(grep -Eo "ghcr\.io/[a-zA-Z0-9._/-]+:[a-zA-Z0-9._-]+" "$1" && \
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
}
' "$1") | while read img; do
    docker manifest inspect "$img" > /dev/null \
      && echo "OK $img" \
      || ( echo "KO $img";exit 1)
  done

