# Mirror of 192.168.42.170 PHP stack: CentOS 7 + httpd prefork + Remi php55 (SCL) 5.5.38-13
FROM centos:7
RUN set -eux; \
    base=http://vault.centos.org/7.9.2009; rm -f /etc/yum.repos.d/*.repo; \
    for r in os updates extras; do printf '[%s]\nname=%s\nbaseurl=%s/%s/$basearch/\ngpgcheck=1\ngpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7\n' $r $r $base $r >> /etc/yum.repos.d/vault.repo; done; \
    printf '[epel]\nname=EPEL 7\nbaseurl=https://archives.fedoraproject.org/pub/archive/epel/7/x86_64/\ngpgcheck=1\ngpgkey=https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7\n' > /etc/yum.repos.d/epel.repo; \
    rpm --import https://rpms.remirepo.net/RPM-GPG-KEY-remi; rpm --import https://rpms.remirepo.net/RPM-GPG-KEY-remi2018 || true; \
    printf '[remi]\nname=remi\nbaseurl=https://rpms.remirepo.net/enterprise/7/remi/x86_64/\ngpgcheck=1\n[remi-php56]\nname=remi-php56\nbaseurl=https://rpms.remirepo.net/enterprise/7/php56/x86_64/\ngpgcheck=1\n' > /etc/yum.repos.d/remi.repo; \
    for k in remi2017 remi2019 remi2020 remi2021 remi2022 remi2023 remi2024; do rpm --import https://rpms.remirepo.net/RPM-GPG-KEY-$k; done; \
    V=5.5.38-13.el7.remi; \
    yum -y install httpd mod_ssl procps-ng iproute \
      php55-php-$V php55-php-cli-$V php55-php-common-$V php55-php-mbstring-$V php55-php-mcrypt-$V \
      php55-php-mysqlnd-$V php55-php-pdo-$V php55-php-process-$V php55-php-soap-$V php55-php-xml-$V \
      php55-php-pear-1.10.15-3.el7.remi php55-runtime-2.1-5.el7.remi \
      php55-php-pecl-apcu-4.0.11-1.el7.remi php55-php-pecl-igbinary-2.0.8-1.el7.remi \
      php55-php-pecl-jsonc-1.3.10-1.el7.remi php55-php-pecl-memcache-3.0.8-5.el7.remi \
      php55-php-pecl-redis-3.1.6-1.el7.remi php55-php-pecl-zip-1.22.3-1.el7.remi; \
    mkdir -p /rollback && cd /rollback && yum -y install yum-utils && \
    yumdownloader php55-php-$V php55-php-cli-$V php55-php-common-$V php55-php-mbstring-$V php55-php-mcrypt-$V \
      php55-php-mysqlnd-$V php55-php-pdo-$V php55-php-process-$V php55-php-soap-$V php55-php-xml-$V; \
    yum clean all
