#!/bin/bash
# Install php 5.6.40-47.1.el7.sec (CVE-2026-109618 / CVE-2026-109619 fix and Remi
# 5.6.40-42..47 security fixes) over Remi php 5.6.40-41.el7.remi.
#
#   ./install.sh --dry-run   checks + yum preview only, changes nothing
#   ./install.sh             install; on failed post-checks, rolls back automatically
#   ./install.sh --no-auto-rollback
#
# Run from the unpacked bundle directory, as root, on the target host.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

DRY_RUN=0 AUTO_ROLLBACK=1
for a in "$@"; do
	case $a in
		--dry-run) DRY_RUN=1 ;;
		--no-auto-rollback) AUTO_ROLLBACK=0 ;;
		*) die "unknown option $a" ;;
	esac
done

start_log install
require_root_and_host
log "bundle: $BUNDLE_DIR  dry-run=$DRY_RUN auto-rollback=$AUTO_ROLLBACK"

step "1. pre-checks"
verify_checksums "$BUNDLE_DIR/rpms" "$BUNDLE_DIR/SHA256SUMS.new"
verify_checksums "$BUNDLE_DIR/rollback" "$BUNDLE_DIR/SHA256SUMS.rollback"
todo=$(pkgs_not_at "$NEW_REL")
[ -n "$todo" ] || { log "all packages already at $NEW_REL, nothing to do"; exit 0; }
off=$(pkgs_not_at "$OLD_REL")
[ -z "$off" ] || die "expected all of [$PKGS] at $OLD_REL, but: $off"
log "installed: $OLD_REL for all $(echo $PKGS | wc -w) packages"
httpd -t || die "httpd -t fails before the change; fix that first"
$ACTIVE_CMD >/dev/null || die "httpd is not active"

step "2. yum transaction preview"
$YUM --assumeno localinstall $(rpm_files "$BUNDLE_DIR/rpms" "$NEW_REL") > /tmp/php-sec-preview.txt 2>&1
sed -n '/^Dependencies Resolved/,/^Total/p' /tmp/php-sec-preview.txt
if grep -qE '^(Installing|Removing|Downgrading|Installing for dependencies|Removing for dependencies)' /tmp/php-sec-preview.txt; then
	die "transaction would do more than updating the $(echo $PKGS | wc -w) packages, aborting"
fi
grep -qE '^Updating:' /tmp/php-sec-preview.txt || die "unexpected yum preview, see /tmp/php-sec-preview.txt"

if [ "$DRY_RUN" = 1 ]; then
	record_state dry-run
	log "dry run finished: nothing was changed"
	exit 0
fi

step "3. backup"
record_state before-install
tar -czf "$STATE_DIR/before-install/etc-php.tar.gz" $CONFIG_PATHS 2>/dev/null
log "config backup: $STATE_DIR/before-install/etc-php.tar.gz"

step "4. install"
$YUM localinstall $(rpm_files "$BUNDLE_DIR/rpms" "$NEW_REL") || die "yum localinstall failed (packages unchanged unless yum says otherwise; check rpm -qa)"
off=$(pkgs_not_at "$NEW_REL")
[ -z "$off" ] || die "after install, not at $NEW_REL: $off"
find $CONFIG_PATHS -name '*.rpmnew' -newer "$STATE_DIR/before-install/rpm-qa.txt" 2>/dev/null | sed 's/^/    new .rpmnew (config kept): /'

step "5. reload httpd"
ok=1
reload_httpd || ok=0

step "6. post-checks"
check_against before-install || ok=0

if [ "$ok" = 1 ]; then
	record_state after-install
	log "SUCCESS: $(rpm -q $COMMON_PKG)"
	exit 0
fi

log "post-checks FAILED"
if [ "$AUTO_ROLLBACK" = 1 ]; then
	log "rolling back automatically"
	exec "$BUNDLE_DIR/rollback.sh" --after-failed-install
fi
log "auto rollback disabled: run $BUNDLE_DIR/rollback.sh"
exit 1
