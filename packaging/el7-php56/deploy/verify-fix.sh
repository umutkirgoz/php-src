#!/bin/bash
# Non-invasive verification of the CVE-2026-109618/109619 fix on this host.
# Uses only /tmp/php-sec-verify; does not touch the web root or app sessions.
PHP=${PHP_BIN:-/usr/bin/php}; CGI=${PHP_CGI:-/usr/bin/php-cgi}
SO=${PHP_SO:-/usr/lib64/httpd/modules/libphp5.so}
W=/tmp/php-sec-verify; rm -rf $W; mkdir -p $W/sess
echo "package:      $(rpm -q ${PKG_MAIN:-php} ${COMMON_PKG:-php-common} | tr '\n' ' ')"
echo "mod_php file: $SO  marker=$(grep -c __PHP_Incomplete_Class_Serialized $SO)"
echo "cli marker:   $(grep -c __PHP_Incomplete_Class_Serialized $PHP)"
parent=$(cat /run/httpd/httpd.pid 2>/dev/null)
total=0; new=0; old=0; unreadable=0
for p in $(pgrep -x httpd); do
  total=$((total+1))
  if ! m=$(cat /proc/$p/maps 2>/dev/null); then unreadable=$((unreadable+1))
  elif echo "$m" | grep -q 'libphp5.so (deleted)'; then old=$((old+1))
  elif echo "$m" | grep -q libphp5.so; then new=$((new+1)); fi
done
echo "httpd procs:  total=$total using-current-libphp5=$new using-deleted-old-libphp5=$old unreadable=$unreadable (parent $parent)"
cat > $W/oom.php <<'P'
<?php
register_shutdown_function(function () { echo "shutdown function ran\n"; });
ini_set('memory_limit', '8M'); echo "before\n";
$s = str_repeat('x', 32 * 1024 * 1024); echo "after\n";
P
echo "-- OOM (cli):"; $PHP -n -d log_errors=0 -d display_errors=1 $W/oom.php 2>&1 | sed 's/^/   /'; echo "   exit=${PIPESTATUS[0]}"
cat > $W/upload.php <<'P'
<?php
echo "_SESSION before session_start: ", (isset($_SESSION) ? "SET" : "not set"), "\n";
echo "FILES: ", $_FILES['f']['name'], " size=", $_FILES['f']['size'], "\n";
echo "session file: ", file_get_contents(ini_get('session.save_path') . '/sess_abc'), "\n";
P
printf '%s' 'a|O:8:"DateTime":3:{s:4:"date";s:26:"2020-01-01 00:00:00.000000";s:13:"timezone_type";i:3;s:8:"timezone";s:3:"UTC";}b|C:11:"ArrayObject":21:{x:i:0;a:0:{};m:a:0:{}}' > $W/sess/sess_abc
python=$(command -v python || command -v python2)
$python - "$W/body.txt" <<'P'
import sys
b='XyZ'; parts=[]
parts.append('--%s\r\nContent-Disposition: form-data; name="PHP_SESSION_UPLOAD_PROGRESS"\r\n\r\nk1\r\n' % b)
junk=''.join('X-Junk-%d: %s\r\n' % (i, 'y'*20) for i in range(200))
parts.append('--%s\r\nContent-Disposition: form-data; name="f"; filename="a.txt"\r\n%sContent-Type: text/plain\r\n\r\n%s\r\n' % (b, junk, 'D'*5000))
parts.append('--%s--\r\n' % b)
open(sys.argv[1],'w').write(''.join(parts))
P
echo "-- upload progress (php-cgi, temp session dir):"
REQUEST_METHOD=POST CONTENT_TYPE='multipart/form-data; boundary=XyZ' CONTENT_LENGTH=$(stat -c %s $W/body.txt) \
SCRIPT_FILENAME=$W/upload.php REDIRECT_STATUS=1 HTTP_COOKIE='PHPSESSID=abc' \
$CGI -d session.save_path=$W/sess -d session.upload_progress.enabled=1 -d session.upload_progress.cleanup=0 \
  -d session.upload_progress.freq=0 -d upload_tmp_dir=$W -d session.serialize_handler=php < $W/body.txt \
  | sed -n '/^_SESSION/,$p' | sed 's/"start_time";i:[0-9]*/"start_time";i:T/g; s/s:[0-9]*:"\/tmp\/php-sec-verify\/php[A-Za-z0-9]*"/TMPFILE/' | cut -c1-260 | sed 's/^/   /'
rm -rf $W
