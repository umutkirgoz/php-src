#!/bin/bash
# Build the self-contained deploy bundle (run locally, from anywhere):
#   php55-php-5.5.38-13.1.el7.sec-deploy.tar.gz
#     scripts, rpms/ (built on 192.168.42.170), rollback/ (Remi 5.5.38-13), checksums
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
TOP=$(cd "$HERE/.." && pwd)
NAME=php55-php-5.5.38-13.1.el7.sec-deploy
OUT=$HERE/$NAME.tar.gz
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/$NAME/rpms" "$TMP/$NAME/rollback"
cp "$HERE"/{install.sh,rollback.sh,lib.sh,SHA256SUMS.new,SHA256SUMS.rollback,README.md} "$TMP/$NAME/"
awk '{print $2}' "$HERE/SHA256SUMS.new" | while read -r f; do cp "$TOP/build-170/RPMS/x86_64/$f" "$TMP/$NAME/rpms/"; done
awk '{print $2}' "$HERE/SHA256SUMS.rollback" | while read -r f; do cp "$TOP/rollback/$f" "$TMP/$NAME/rollback/"; done
(cd "$TMP/$NAME/rpms" && shasum -a 256 -c --quiet "$HERE/SHA256SUMS.new")
(cd "$TMP/$NAME/rollback" && shasum -a 256 -c --quiet "$HERE/SHA256SUMS.rollback")
chmod +x "$TMP/$NAME"/*.sh
COPYFILE_DISABLE=1 tar --no-xattrs --no-mac-metadata -C "$TMP" -czf "$OUT" "$NAME"
(cd "$HERE" && shasum -a 256 "$NAME.tar.gz" > "$NAME.tar.gz.sha256")
echo "$OUT"; cat "$OUT.sha256"
