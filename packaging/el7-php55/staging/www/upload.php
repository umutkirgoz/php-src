<?php
echo "_SESSION before session_start: ", (isset($_SESSION) ? "SET" : "not set"), "\n";
echo "FILES: ", $_FILES['f']['name'], " type=", $_FILES['f']['type'], " size=", $_FILES['f']['size'], "\n";
echo "file: ", file_get_contents('/opt/remi/php55/root/var/lib/php/session/sess_abc'), "\n";
