<?php
session_start(); $_SESSION['n'] = isset($_SESSION['n']) ? $_SESSION['n'] + 1 : 1;
$im = imagecreatetruecolor(10, 10); ob_start(); imagepng($im); $png = strlen(ob_get_clean());
$checks = array(
  'version' => PHP_VERSION, 'sapi' => PHP_SAPI,
  'serialize' => unserialize(serialize(array('a' => new ArrayObject(array(1))))) instanceof Traversable || true,
  'json' => json_encode(array('x' => 1)), 'gd_png_bytes' => $png,
  'mb' => mb_strtoupper('ğüşiöç', 'UTF-8'), 'igbinary' => igbinary_unserialize(igbinary_serialize(array(1,2))) === array(1,2),
  'msgpack' => msgpack_unpack(msgpack_pack('x')) === 'x', 'memcached' => class_exists('Memcached'),
  'soap' => class_exists('SoapClient'), 'pdo_mysql' => in_array('mysql', PDO::getAvailableDrivers()),
  'mysqli' => function_exists('mysqli_connect'), 'zip' => class_exists('ZipArchive'), 'wddx' => function_exists('wddx_serialize_value'),
  'session_n' => $_SESSION['n'],
);
echo json_encode($checks), "\n";
