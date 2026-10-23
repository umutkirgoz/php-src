# Mirror of 192.168.42.201 PHP stack: CentOS 7 + httpd prefork + Remi php 5.6.40-41
FROM centos:7
RUN set -eux; \
    base=http://vault.centos.org/7.9.2009; rm -f /etc/yum.repos.d/*.repo; \
    for r in os updates extras; do printf '[%s]\nname=%s\nbaseurl=%s/%s/$basearch/\ngpgcheck=1\ngpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7\n' $r $r $base $r >> /etc/yum.repos.d/vault.repo; done; \
    printf '[epel]\nname=EPEL 7\nbaseurl=https://archives.fedoraproject.org/pub/archive/epel/7/x86_64/\ngpgcheck=1\ngpgkey=https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7\n' > /etc/yum.repos.d/epel.repo; \
    rpm --import https://rpms.remirepo.net/RPM-GPG-KEY-remi; rpm --import https://rpms.remirepo.net/RPM-GPG-KEY-remi2018 || true; \
    printf '[remi]\nname=remi\nbaseurl=https://rpms.remirepo.net/enterprise/7/remi/x86_64/\ngpgcheck=1\n[remi-php56]\nname=remi-php56\nbaseurl=https://rpms.remirepo.net/enterprise/7/php56/x86_64/\ngpgcheck=1\n' > /etc/yum.repos.d/remi.repo; \
    V=5.6.40-41.el7.remi; \
    yum -y install httpd mod_ssl procps-ng iproute \
      php-$V php-cli-$V php-common-$V php-gd-$V php-mbstring-$V php-mysqlnd-$V php-pdo-$V \
      php-process-$V php-soap-$V php-xml-$V php-pear \
      php-pecl-igbinary-2.0.8-1.el7.remi.5.6 php-pecl-jsonc-1.3.10-2.el7.remi.5.6 \
      php-pecl-memcached-2.2.0-3.el7.remi.5.6 php-pecl-msgpack-0.5.7-1.el7.remi.5.6 \
      php-pecl-zip-1.22.3-1.el7.remi.5.6; \
    mkdir -p /rollback && cd /rollback && yum -y install yum-utils && \
    yumdownloader php-$V php-cli-$V php-common-$V php-gd-$V php-mbstring-$V php-mysqlnd-$V php-pdo-$V php-process-$V php-soap-$V php-xml-$V; \
    yum clean all
