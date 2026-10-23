# Common settings and helpers for install.sh / rollback.sh (sourced, not executed).
# Every setting can be overridden from the environment.

NEW_REL=${NEW_REL:-5.6.40-47.1.el7.sec}
OLD_REL=${OLD_REL:-5.6.40-41.el7.remi}
PKGS=${PKGS:-"php php-cli php-common php-gd php-mbstring php-mysqlnd php-pdo php-process php-soap php-xml"}
COMMON_PKG=${COMMON_PKG:-php-common}
PHP_BIN=${PHP_BIN:-/usr/bin/php}
EXPECT_HOST=${EXPECT_HOST:-hissenet}
# Health checks: "<url>|<Host header>", status code must match the one recorded before the change.
# /topluluk is the live forum (PHP); httpd :8080 directly, through varnish :80, and httpd :443.
HEALTH_URLS=${HEALTH_URLS:-"http://127.0.0.1:8080/topluluk/forum.php|www.hisse.net http://127.0.0.1:8080/topluluk/online.php|www.hisse.net http://127.0.0.1/topluluk/forum.php|www.hisse.net https://127.0.0.1/topluluk/forum.php|www.hisse.net"}
# Backed up before the change; *.rpmnew created by the update are reported
CONFIG_PATHS=${CONFIG_PATHS:-"/etc/php.ini /etc/php.d /etc/httpd/conf.d/php.conf /etc/httpd/conf.modules.d/10-php.conf"}
RELOAD_CMD=${RELOAD_CMD:-"systemctl reload httpd"}
ACTIVE_CMD=${ACTIVE_CMD:-"systemctl is-active httpd"}
HTTPD_ERROR_LOG=${HTTPD_ERROR_LOG:-/var/log/httpd/error_log}

BUNDLE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
STATE_DIR=${STATE_DIR:-/root/php-sec/state}
LOG_DIR=${LOG_DIR:-/root/php-sec/logs}
YUM="yum -y --disablerepo=*"

log()  { echo "[$(date '+%F %T')] $*"; }
die()  { log "ERROR: $*"; exit 1; }
step() { echo; log "== $*"; }

start_log() { # $1 = name
	mkdir -p "$LOG_DIR" "$STATE_DIR"
	LOG_FILE="$LOG_DIR/$1-$(date +%Y%m%d-%H%M%S).log"
	exec > >(tee -a "$LOG_FILE") 2>&1
	log "log: $LOG_FILE"
}

require_root_and_host() {
	[ "$(id -u)" -eq 0 ] || die "must run as root"
	[ "$(hostname)" = "$EXPECT_HOST" ] || die "hostname is $(hostname), expected $EXPECT_HOST (override with EXPECT_HOST=)"
}

# $1 = release: print packages whose installed release differs from it
pkgs_not_at() {
	local p
	for p in $PKGS; do
		[ "$(rpm -q --qf '%{VERSION}-%{RELEASE}' "$p" 2>/dev/null)" = "$1" ] || echo "$p=$(rpm -q "$p" 2>&1)"
	done
}

rpm_files() { # $1 = dir, $2 = release
	local p
	for p in $PKGS; do echo "$1/$p-$2.x86_64.rpm"; done
}

verify_checksums() { # $1 = dir, $2 = SHA256SUMS file
	(cd "$1" && sha256sum --quiet -c "$2") || die "checksum mismatch in $1"
	log "checksums OK: $1"
}

http_status() { # $1 = "<url>|<host>"
	curl -skg -o /dev/null -m 15 -w '%{http_code}' -H "Host: ${1#*|}" "${1%|*}"
}

record_state() { # $1 = label
	local d="$STATE_DIR/$1"
	mkdir -p "$d"
	rpm -qa | sort > "$d/rpm-qa.txt"
	"$PHP_BIN" -m > "$d/php-m.txt" 2>&1
	httpd -M 2>/dev/null | sort > "$d/httpd-M.txt"
	local u
	: > "$d/http.txt"
	for u in $HEALTH_URLS; do echo "$u $(http_status "$u")" >> "$d/http.txt"; done
	log "state recorded: $d"
	sed 's/^/    /' "$d/http.txt"
}

# Compare current state with a recorded one; returns non-zero on any difference
check_against() { # $1 = label of the reference state
	local ref="$STATE_DIR/$1" fail=0 u code want
	"$PHP_BIN" -m > /tmp/php-m.now 2>&1
	if diff -u "$ref/php-m.txt" /tmp/php-m.now; then log "php -m: same as $1"; else log "php -m: DIFFERS from $1"; fail=1; fi
	httpd -M 2>/dev/null | sort > /tmp/httpd-M.now
	if diff -u "$ref/httpd-M.txt" /tmp/httpd-M.now; then log "httpd -M: same as $1"; else log "httpd -M: DIFFERS from $1"; fail=1; fi
	$ACTIVE_CMD >/dev/null 2>&1 && log "httpd: active" || { log "httpd: NOT active"; fail=1; }
	for u in $HEALTH_URLS; do
		want=$(awk -v u="$u" '$1 == u {print $2}' "$ref/http.txt")
		code=$(http_status "$u")
		if [ "$code" = "$want" ]; then log "HTTP $u -> $code (as before)"; else log "HTTP $u -> $code, expected $want"; fail=1; fi
	done
	return $fail
}

# Returns non-zero (does not exit) so that the caller can roll back
reload_httpd() {
	httpd -t || { log "httpd -t failed, not reloading"; return 1; }
	local mark; mark=$(wc -l < "$HTTPD_ERROR_LOG" 2>/dev/null || echo 0)
	$RELOAD_CMD || { log "reload failed: $RELOAD_CMD"; return 1; }
	sleep 5
	log "httpd error_log since reload:"
	tail -n +"$((mark + 1))" "$HTTPD_ERROR_LOG" 2>/dev/null | sed 's/^/    /'
	if tail -n +"$((mark + 1))" "$HTTPD_ERROR_LOG" 2>/dev/null | grep -qiE 'segmentation fault|exit signal|Cannot load|undefined symbol'; then
		log "WARNING: suspicious lines in error_log after reload"
		return 1
	fi
}
