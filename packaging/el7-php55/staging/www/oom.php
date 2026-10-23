<?php
@unlink('/tmp/oom-shutdown');
register_shutdown_function(function () { file_put_contents('/tmp/oom-shutdown', "ran\n"); });
ini_set('memory_limit', '8M');
echo "before\n"; flush();
$s = str_repeat('x', 32 * 1024 * 1024);
echo "after\n";
