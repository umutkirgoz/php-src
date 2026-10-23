# php55-php 5.5.38-13.1.el7.sec (CentOS 7, x86_64, Remi SCL)

Remi `php55-php-5.5.38-13.el7.remi` (192.168.42.170'te kurulu olan, Remi'nin son php55
sürümü) üzerine yeniden derleme. Tek ek yama:

- Upstream 31c0ea7 backport'u: GHSA-w8hw-w9fx-j79w (CVE-2026-109618),
  GHSA-6wmf-4rv5-p3rp (CVE-2026-109619) — `SOURCES/php-cve-2026-109618-109619.patch`

Remi php55 için 2022'den sonra yeni sürüm yayınlamadığından, 5.6 paketindeki
2023–2026 tarihli diğer güvenlik düzeltmeleri bu pakette **yoktur**.

## İçerik

| Dizin | |
|---|---|
| `RPMS/` | Derlenmiş paketler (33 adet, yerelde), `SHA256SUMS` |
| `SRPMS/` | Kaynak RPM |
| `rollback/` | Sunucudaki mevcut sürüm: Remi `5.5.38-13.el7.remi` (10 paket), `SHA256SUMS` |
| `build-170/` | Aynı SRPM'in 192.168.42.170 üzerinde derlenmiş hali (arşiv) ve kurulum kayıtları |
| `php.spec`, `SOURCES/` | Spec ve tüm yamalar; kaynak tarball `fetch-sources.sh` ile Remi SRPM'inden alınır (`sources.sha256`) |
| `build-env/` | Derleme imajı (CentOS 7 + Remi EL7 deposu, gpgcheck açık); build context'e `php.spec` kopyalanmalı |
| `staging/` | Prova imajı (sunucudaki paket seti), test scriptleri, `cmp-rpms.sh` |

RPM, SRPM ve geri dönüş paketleri git'te tutulmaz; doğrulama için `*/SHA256SUMS` dosyaları commit'lidir.

## Derleme

SCL paketi Remi'nin yol düzeniyle (`/opt/remi/php55`) derlenmelidir; aksi halde
`/opt/rh/php55` altına kurulur ve PECL eklentileri yüklenmez:

```bash
rpmbuild -ba --define 'scl php55' --define '_scl_prefix /opt/remi' --define 'scl_vendor remi' \
             --define 'dist .el7.sec' --define 'runselftest 0' php.spec
```

Bağımlılıklar: `yum-builddep -x 'libicu[0-9]*' -x 'libwebp-devel-0.3*' ...` — intl, Remi'nin
orijinalindeki gibi sistem ICU 50 ile derlenir (yeni ICU'lar 5.5 ile derlenmez).

## Doğrulama

- 10 paketin dosya listesi, requires ve provides'ı Remi `-13` ile birebir aynı (`staging/cmp-rpms.sh`).
- 170'te derlenen 33 paket, yerelde derlenenlerle aynı (yalnızca debuginfo build-id'leri farklı).

## Davranış değişikliği

`memory_limit` / OOM durumunda hata loglanır ve Apache child süreci `_exit(255)` ile
sonlanır: shutdown fonksiyonları ve destructor'lar çalışmaz, istemciye yanıt yarım kalır
(nginx arkasında 502 görülebilir); prefork yeni child açar, diğer istekler etkilenmez.

## Geçiş (bakım penceresinde, onaydan sonra)

Güncellenecek 10 paket: `php55-php php55-php-cli php55-php-common php55-php-mbstring
php55-php-mcrypt php55-php-mysqlnd php55-php-pdo php55-php-process php55-php-soap php55-php-xml`.
PECL paketleri (apcu, igbinary, jsonc, memcache, redis, zip) değişmez.

```bash
P=/opt/remi/php55/root/usr/bin/php
# 0. Ön kontrol
rpm -qa 'php55*' | sort > /root/php-before.txt; $P -m > /root/php-m-before.txt; httpd -t

# 1. Paketleri kopyala ve doğrula
scp RPMS/php55-php{,-cli,-common,-mbstring,-mcrypt,-mysqlnd,-pdo,-process,-soap,-xml}-5.5.38-13.1.el7.sec.x86_64.rpm \
    RPMS/SHA256SUMS root@192.168.42.170:/root/php-sec/
scp -r rollback root@192.168.42.170:/root/php-sec/rollback
ssh root@192.168.42.170 'cd /root/php-sec && sha256sum --check --ignore-missing SHA256SUMS && cd rollback && sha256sum -c SHA256SUMS'

# 2. Kurulum
cd /root/php-sec && yum -y --disablerepo='*' localinstall php55-php*-5.5.38-13.1.el7.sec.x86_64.rpm
httpd -t && systemctl reload httpd     # graceful

# 3. Doğrulama
rpm -q php55-php-common                # php55-php-common-5.5.38-13.1.el7.sec
$P -m | diff /root/php-m-before.txt -  # fark olmamalı
curl -sI http://127.0.0.1/ ; tail -f /var/log/httpd/error_log
```

## Geri dönüş

```bash
cd /root/php-sec/rollback && yum -y --disablerepo='*' downgrade ./*.rpm
httpd -t && systemctl reload httpd
rpm -q php55-php-common                # php55-php-common-5.5.38-13.el7.remi
```

## Prova sonuçları (staging, CentOS 7.9 + sunucudaki paket seti)

| | -13 (mevcut) | 13.1 |
|---|---|---|
| `php -m` (59 modül) | | aynı |
| Smoke (session, apcu, memcache, redis, igbinary, mcrypt, soap, pdo_mysql, mysql, zip, wddx) | OK | OK |
| OOM: shutdown fonksiyonu | çalışıyor | çalışmıyor (beklenen) |
| Upload progress: script başında `$_SESSION` | dolu | boş (beklenen) |
| Upload progress: session dosyası | aynen | aynen, nesneler çözülmeden geri yazıldı |
| Test süiti (3770 test) | 15 başarısız | 15 başarısız, aynı testler |
| yükseltme → geri dönüş | | sorunsuz, modül listesi ilk haline döndü |

## 192.168.42.170 üzerindeki derleme

Onayla, sunucuda `/root/php55-build` ve `/root/rpmbuild` altında derlendi (`nice 19`,
`ionice idle`, ~9 dk). Yum, sistem repo ayarlarına dokunmadan
`/root/php55-build/repos/build.repo` ile çalıştırıldı. Sunucuya **148 paket eklendi**
(`build-170/added-packages-on-170.txt`); mevcut paketlerin hiçbiri güncellenmedi veya
kaldırılmadı. PHP paketleri kurulmadı, servisler yeniden başlatılmadı.

## Kurulum kaydı (23 Ekim 2026)

`deploy/` paketi ile kuruldu; her sunucuda `install.sh` başarılı, `deploy/verify-fix.sh` ile
doğrulandı (libphp5.so'da yeni kod, tüm httpd süreçleri yeni modülde, OOM sonrası shutdown
fonksiyonu çalışmıyor, upload progress'te `$_SESSION` sızmıyor).

| Sunucu | Host | Not |
|---|---|---|
| 192.168.42.170 | `yorum_170` | paketler bu sunucuda derlendi; derleme bağımlılıkları (148 paket) bırakıldı |
| 192.168.42.168 | `yorum_168` | ~2000 istek/dk, kurulum dakikasında 5xx yok |
| 192.168.42.169 | `yorum_169_redis` | |
| 192.168.42.171 | `yorum_171` | ~1900 istek/dk, kurulum dakikasında 5xx yok |
| 192.168.42.240 | `yorum_240` | admin paneli; Apache :8080 + Basic Auth, URL testi yapılmadı |

`install.sh` / `rollback.sh` varsayılanları 170'e göredir; diğer sunucularda `EXPECT_HOST`
(ve 240'ta `HEALTH_URLS='http://192.168.42.240:8080/|yorum.mynet.com http://192.168.42.240/|yorum.mynet.com'`)
verilmelidir.
