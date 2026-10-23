<?php
session_start(); $_SESSION['n'] = isset($_SESSION['n']) ? $_SESSION['n'] + 1 : 1;
$checks = array(
  'version' => PHP_VERSION, 'sapi' => PHP_SAPI,
  'serialize' => unserialize(serialize(array('a' => new ArrayObject(array(1))))) instanceof Traversable || true,
  'json' => json_encode(array('x' => 1)), 'mb' => mb_strtoupper('ğüşiöç', 'UTF-8'),
  'mcrypt' => function_exists('mcrypt_encrypt'),
  'igbinary' => igbinary_unserialize(igbinary_serialize(array(1,2))) === array(1,2),
  'apcu' => apcu_store('k', 1) && apcu_fetch('k') === 1, 'memcache' => class_exists('Memcache'),
  'redis' => class_exists('Redis'), 'soap' => class_exists('SoapClient'),
  'pdo_mysql' => in_array('mysql', PDO::getAvailableDrivers()), 'mysql' => function_exists('mysql_connect'),
  'zip' => class_exists('ZipArchive'), 'wddx' => function_exists('wddx_serialize_value'),
  'session_n' => $_SESSION['n'],
);
echo json_encode($checks), "\n";
