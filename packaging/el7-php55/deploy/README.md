# php55-php 5.5.38-13.1.el7.sec — kurulum / geri alma (192.168.42.170)

Paketler 192.168.42.170 üzerinde derlenen sürümdür (`../build-170`).

## Paket hazırlama (yerelde)

```bash
./make-bundle.sh      # -> php55-php-5.5.38-13.1.el7.sec-deploy.tar.gz (+ .sha256)
```

## Sunucuya kopyalama

```bash
scp php55-php-5.5.38-13.1.el7.sec-deploy.tar.gz* root@192.168.42.170:/root/php-sec/
ssh root@192.168.42.170
cd /root/php-sec && sha256sum -c php55-php-5.5.38-13.1.el7.sec-deploy.tar.gz.sha256
tar -xzf php55-php-5.5.38-13.1.el7.sec-deploy.tar.gz && cd php55-php-5.5.38-13.1.el7.sec-deploy
```

## Kurulum

```bash
./install.sh --dry-run    # sadece kontrol + yum ön izleme, hiçbir şey değişmez
./install.sh              # bakım penceresinde
```

Adımlar:
1. RPM checksum'ları (yeni + geri dönüş), 10 paketin `5.5.38-13.el7.remi` olduğu, `httpd -t`, httpd aktif
2. yum ön izleme: 10 paketin güncellenmesi dışında bir işlem varsa durur
3. Yedek: `rpm -qa`, `php -m`, `httpd -M`, sağlık URL'lerinin HTTP kodları, php55/httpd php config'leri
   (`/root/php-sec/state/before-install/`)
4. `yum localinstall` (repo'lar kapalı, yalnızca paketteki RPM'ler)
5. `httpd -t` + `systemctl reload httpd` (graceful), reload sonrası error_log kontrolü
6. Kontroller: `php -m`, `httpd -M`, httpd aktif, sağlık URL'leri kurulum öncesiyle aynı kodu dönüyor

5. veya 6. adım başarısız olursa **otomatik olarak geri alınır**
(`--no-auto-rollback` ile kapatılabilir).

## Geri alma

```bash
./rollback.sh --dry-run
./rollback.sh
```

Yalnızca `5.5.38-13.el7.remi` olmayan paketleri Remi'nin orijinal RPM'lerine düşürür,
httpd'yi reload eder ve kurulum öncesi kayıtla karşılaştırır.

## Ayarlar

`lib.sh` başındaki değerler ortam değişkeniyle değiştirilebilir, ör.:

```bash
HEALTH_URLS="http://127.0.0.1/|yorum.mynet.com http://127.0.0.1/health|yorum.mynet.com" ./install.sh
```

Loglar: `/root/php-sec/logs/`, durum kayıtları: `/root/php-sec/state/`.
