#!/bin/bash
# Roll back php to Remi 5.6.40-41.el7.remi (the release before install.sh).
#
#   ./rollback.sh --dry-run   checks + yum preview only, changes nothing
#   ./rollback.sh
#
# Run from the unpacked bundle directory, as root, on the target host.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

DRY_RUN=0
for a in "$@"; do
	case $a in
		--dry-run) DRY_RUN=1 ;;
		--after-failed-install) ;;
		*) die "unknown option $a" ;;
	esac
done

start_log rollback
require_root_and_host
log "bundle: $BUNDLE_DIR  dry-run=$DRY_RUN"

step "1. pre-checks"
verify_checksums "$BUNDLE_DIR/rollback" "$BUNDLE_DIR/SHA256SUMS.rollback"
todo=$(pkgs_not_at "$OLD_REL")
[ -n "$todo" ] || { log "all packages already at $OLD_REL, nothing to do"; exit 0; }
log "to roll back: $(echo "$todo" | tr '\n' ' ')"

step "2. yum transaction preview"
# Only packages not yet at the old release; a partly applied install is handled too
files=$(for p in $(echo "$todo" | cut -d= -f1); do echo "$BUNDLE_DIR/rollback/$p-$OLD_REL.x86_64.rpm"; done)
$YUM --assumeno downgrade $files > /tmp/php-sec-rb-preview.txt 2>&1
sed -n '/^Dependencies Resolved/,/^Total/p' /tmp/php-sec-rb-preview.txt
if grep -qE '^(Installing|Removing|Updating|Installing for dependencies|Removing for dependencies)' /tmp/php-sec-rb-preview.txt; then
	die "transaction would do more than downgrading php packages, aborting"
fi

if [ "$DRY_RUN" = 1 ]; then
	log "dry run finished: nothing was changed"
	exit 0
fi

step "3. downgrade"
$YUM downgrade $files || die "yum downgrade failed; check rpm -qa 'php*'"
off=$(pkgs_not_at "$OLD_REL")
[ -z "$off" ] || die "after downgrade, not at $OLD_REL: $off"

step "4. reload httpd"
ok=1
reload_httpd || ok=0

step "5. post-checks"
if [ -d "$STATE_DIR/before-install" ]; then
	check_against before-install || ok=0
else
	log "no before-install state recorded; skipping comparison"
fi

if [ "$ok" = 1 ]; then
	log "ROLLBACK OK: $(rpm -q $COMMON_PKG)"
	exit 0
fi
log "ROLLBACK DONE BUT CHECKS FAILED: investigate (logs in $LOG_DIR)"
exit 1
