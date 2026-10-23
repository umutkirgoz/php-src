#!/bin/bash
# $1 label: run selected upstream tests against the installed /usr/bin/php
L=$1; rm -rf /tmp/src-$L; cp -a /srctree/php-5.6.40 /tmp/src-$L; cd /tmp/src-$L
TEST_PHP_EXECUTABLE=/usr/bin/php TEST_PHP_CGI_EXECUTABLE=/usr/bin/php-cgi NO_INTERACTION=1 REPORT_EXIT_STATUS=0 \
  /usr/bin/php -n run-tests.php -p /usr/bin/php -q Zend/tests tests ext/session ext/standard/tests/serialize \
  ext/standard/tests/general_functions ext/wddx ext/openssl ext/date ext/mbstring > /tmp/suite-$L.log 2>&1
grep -E "^Tests (failed|passed)|^Number of tests" /tmp/suite-$L.log
sed -n "/^FAILED TEST SUMMARY/,/^=====*$/p" /tmp/suite-$L.log | grep "\[" | sed "s/ *\[.*\]//" | sort > /tmp/fail-$L.txt
