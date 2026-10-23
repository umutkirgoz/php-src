# php 5.6.40-47.1.el7.sec (CentOS 7, x86_64)

Remi `php-5.6.40-41.el7.remi` (192.168.42.201'de kurulu olan) üzerine yeniden derleme:

- Remi `php56-php` 5.6.40-42…47 güvenlik yamaları: CVE-2024-8925, CVE-2024-8926,
  CVE-2024-8927, CVE-2024-8932, CVE-2024-11233, CVE-2024-11234, GHSA-4w77-75f9-2c8w,
  CVE-2026-6735, CVE-2026-7261, CVE-2026-7262, GH-22187 (openssl AES-WRAP-PAD),
  mysqlnd utf8mb4 desteği
- Upstream 31c0ea7 backport'u: GHSA-w8hw-w9fx-j79w (CVE-2026-109618),
  GHSA-6wmf-4rv5-p3rp (CVE-2026-109619) — `SOURCES/php-cve-2026-109618-109619.patch`

## İçerik

| Dizin | |
|---|---|
| `RPMS/` | Derlenmiş paketler (34 adet), `SHA256SUMS` |
| `SRPMS/` | Kaynak RPM |
| `rollback/` | Sunucudaki mevcut sürüm: Remi `5.6.40-41.el7.remi` (10 paket), `SHA256SUMS` |
| `php.spec`, `SOURCES/` | Spec ve tüm yamalar; kaynak tarball `fetch-sources.sh` ile Remi SRPM'inden alınır (`sources.sha256`) |
| `build-env/` | Derleme imajı (CentOS 7 + Remi EL7 deposu, gpgcheck açık); build context'e `php.spec` kopyalanmalı |

RPM, SRPM ve geri dönüş paketleri git'te tutulmaz; doğrulama için `*/SHA256SUMS` dosyaları commit'lidir.
| `staging/` | Prova imajı (sunucudaki paket seti) ve test scriptleri |

## Davranış değişikliği

`memory_limit` / OOM durumunda hata loglanır ve Apache child süreci `_exit(255)` ile
sonlanır (eskiden bailout ile shutdown sürecine dönülürdü):

- shutdown fonksiyonları ve destructor'lar çalışmaz,
- istemciye yanıt yarım kalır (varnish arkasında 503 görülebilir),
- prefork yeni child açar; diğer istekler etkilenmez.

## Geçiş (bakım penceresinde, onaydan sonra)

Sunucuda güncellenecek 10 paket: `php php-cli php-common php-gd php-mbstring php-mysqlnd
php-pdo php-process php-soap php-xml`. PECL paketleri (igbinary, jsonc, memcached, msgpack,
zip) ve `php56-*` SCL paketleri değişmez.

```bash
# 0. Ön kontrol (salt okuma)
rpm -qa 'php*' | sort > /root/php-before.txt
php -m > /root/php-m-before.txt
httpd -t

# 1. Paketleri kopyala
scp RPMS/php{,-cli,-common,-gd,-mbstring,-mysqlnd,-pdo,-process,-soap,-xml}-5.6.40-47.1.el7.sec.x86_64.rpm \
    RPMS/SHA256SUMS root@192.168.42.201:/root/php-sec/
scp -r rollback root@192.168.42.201:/root/php-sec/rollback
ssh root@192.168.42.201 'cd /root/php-sec && sha256sum --check --ignore-missing SHA256SUMS && cd rollback && sha256sum -c SHA256SUMS'

# 2. Kurulum
cd /root/php-sec && yum -y --disablerepo='*' localinstall php*-5.6.40-47.1.el7.sec.x86_64.rpm
httpd -t && systemctl reload httpd     # graceful

# 3. Doğrulama
rpm -q php-common                      # php-common-5.6.40-47.1.el7.sec
php -m | diff /root/php-m-before.txt - # fark olmamalı
curl -sI http://127.0.0.1:8080/ ; tail -f /var/log/httpd/error_log /tmp/php_errors.log
```

## Geri dönüş

```bash
cd /root/php-sec/rollback && yum -y --disablerepo='*' downgrade ./*.rpm
httpd -t && systemctl reload httpd
rpm -q php-common                      # php-common-5.6.40-41.el7.remi
```

## Prova sonuçları (staging, CentOS 7.9 + sunucudaki paket seti)

| | -41 (mevcut) | 47.1 |
|---|---|---|
| `php -m` (57 modül) | | aynı |
| Smoke (session, gd, mbstring, igbinary, msgpack, memcached, soap, pdo_mysql, zip, wddx) | OK | OK |
| OOM: shutdown fonksiyonu | çalışıyor | çalışmıyor (beklenen) |
| Upload progress: script başında `$_SESSION` | dolu | boş (beklenen) |
| Upload progress: session dosyası | aynen | aynen, nesneler çözülmeden geri yazıldı |
| Test süiti (3988 test) | 18 başarısız | 17 başarısız; yeni hata yok, GHSA-9pqp-7h25-4f32 düzeldi |
| yükseltme → geri dönüş | | sorunsuz, modül listesi ilk haline döndü |

## Kurulum kaydı (23 Ekim 2026)

192.168.42.201 (`hissenet`): `deploy/` paketi ile kuruldu (`install.sh` başarılı, 17:44:36 graceful
reload). `deploy/verify-fix.sh` ile doğrulandı: libphp5.so'da yeni kod, tüm httpd süreçleri yeni
modülde, OOM sonrası shutdown fonksiyonu çalışmıyor, upload progress'te `$_SESSION` sızmıyor.
Reload sonrası ~2 dk süreç sayısı ve yanıt süreleri yükseldi (22→133 süreç, forum.php 0,22→0,41 sn),
ardından önceki değerlere döndü; trafikte 5xx görülmedi.

Kurulmadan kalanlar: `php56-php-*` SCL paketleri (5.6.40-41, yalnızca `/usr/bin/php56` CLI).
