# php 5.6.40-47.1.el7.sec — kurulum / geri alma (192.168.42.201, hissenet)

Remi `php-5.6.40-41.el7.remi` yerine `php-5.6.40-47.1.el7.sec`: CVE-2026-109618/109619
düzeltmesi + Remi php56-php 5.6.40-42…47 güvenlik yamaları. Paketler `../RPMS` (yerelde derlendi;
dosya listesi/requires/provides Remi `-41` ile aynı).

Güncellenen 10 paket: `php php-cli php-common php-gd php-mbstring php-mysqlnd php-pdo
php-process php-soap php-xml`. PECL paketleri (igbinary, jsonc, memcached, msgpack, zip) ve
`php56-*` SCL paketleri değişmez.

## Paket hazırlama (yerelde)

```bash
./make-bundle.sh      # -> php-5.6.40-47.1.el7.sec-deploy.tar.gz (+ .sha256)
```

## Sunucuya kopyalama

```bash
scp -i ~/.ssh/id_ecdsa_212 php-5.6.40-47.1.el7.sec-deploy.tar.gz* root@192.168.42.201:/root/php-sec/
ssh -i ~/.ssh/id_ecdsa_212 root@192.168.42.201
cd /root/php-sec && sha256sum -c php-5.6.40-47.1.el7.sec-deploy.tar.gz.sha256
tar -xzf php-5.6.40-47.1.el7.sec-deploy.tar.gz && cd php-5.6.40-47.1.el7.sec-deploy
```

## Kurulum / geri alma

```bash
./install.sh --dry-run    # sadece kontrol + yum ön izleme
./install.sh              # bakım penceresinde; kontroller başarısızsa otomatik geri alır
./verify-fix.sh           # fix doğrulaması (yalnızca /tmp kullanır)
./rollback.sh [--dry-run] # Remi 5.6.40-41'e dönüş
```

Sağlık kontrolleri (`lib.sh`, `HEALTH_URLS`): canlı forum `/topluluk/forum.php` ve `online.php`;
httpd `:8080`, varnish `:80` ve httpd `:443` üzerinden, `Host: www.hisse.net`.
`/haber/` (WordPress) kurulum öncesinde de "Database Error" ile 500 döndüğü için kullanılmaz.

Davranış değişikliği: `memory_limit` aşıldığında hata loglanır ve Apache child süreci sonlanır
(shutdown fonksiyonları çalışmaz, yanıt yarım kalır; varnish arkasında 503 görülebilir).

Loglar: `/root/php-sec/logs/`, durum kayıtları: `/root/php-sec/state/`.
