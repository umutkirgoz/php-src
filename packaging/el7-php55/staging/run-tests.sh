#!/bin/bash
# Runs inside the staging container. $1 = label
L=$1
H=http://127.0.0.1
echo "######## $L : $(rpm -q php55-php-common)"
/opt/remi/php55/root/usr/bin/php -m > /tmp/mods-$L.txt; echo "modules: $(grep -cv '^\[' /tmp/mods-$L.txt)"
/opt/remi/php55/root/usr/bin/php -r 'echo "cli: ", PHP_VERSION, "\n";'
echo "-- httpd configtest: $(httpd -t 2>&1)"
echo "-- smoke (2 requests, same session):"
rm -f /tmp/cj; curl -s -c /tmp/cj -b /tmp/cj $H/smoke.php; curl -s -c /tmp/cj -b /tmp/cj $H/smoke.php
echo "-- OOM:"
curl -s -o /tmp/oom.out -w 'http=%{http_code}\n' $H/oom.php; echo "curl exit=$?"; echo "body: $(tr '\n' ' ' < /tmp/oom.out)"
echo "shutdown function: $(cat /tmp/oom-shutdown 2>/dev/null || echo 'did not run')"
tail -n 3 /var/log/httpd/error_log | sed 's/^/  error_log: /'
echo "-- upload progress:"
printf '%s' 'a|O:8:"DateTime":3:{s:4:"date";s:26:"2020-01-01 00:00:00.000000";s:13:"timezone_type";i:3;s:8:"timezone";s:3:"UTC";}b|C:11:"ArrayObject":21:{x:i:0;a:0:{};m:a:0:{}}' > /opt/remi/php55/root/var/lib/php/session/sess_abc
chown apache:apache /opt/remi/php55/root/var/lib/php/session/sess_abc
curl -s -H 'Content-Type: multipart/form-data; boundary=XyZ' -H 'Cookie: PHPSESSID=abc' --data-binary @/var/www/html/body.txt "$H/upload.php?cleanup=0" | sed 's/"start_time";i:[0-9]*/"start_time";i:T/g; s/php[A-Za-z0-9]\{6\}"/phpXXXXXX"/'
echo
echo "-- apache children alive: $(pgrep -c httpd)"
