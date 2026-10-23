#!/bin/bash
# Fetch SOURCES/php-5.6.40-strip.tar.xz from the Remi 5.6.40-41 source RPM.
# Needs rpm2cpio + cpio (e.g. run inside the build-env image).
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
cd "$HERE"
SRPM=php-5.6.40-41.remi.src.rpm
[ -f "$SRPM" ] || curl -fsSLO "https://rpms.remirepo.net/SRPMS/$SRPM"
TMP=$(mktemp -d)
(cd "$TMP" && rpm2cpio "$HERE/$SRPM" | cpio -id php-5.6.40-strip.tar.xz 2>/dev/null)
mv "$TMP/php-5.6.40-strip.tar.xz" SOURCES/
rmdir "$TMP"
sha256sum -c sources.sha256
