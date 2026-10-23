# CentOS 7 x86_64 build env for Remi php 5.6.40 rebuild
FROM php70-el7-build:x86_64
COPY php.spec /tmp/php.spec
RUN set -eux; \
    rpm --import https://rpms.remirepo.net/RPM-GPG-KEY-remi; \
    rpm --import https://rpms.remirepo.net/RPM-GPG-KEY-remi2017 || true; \
    rpm --import https://rpms.remirepo.net/RPM-GPG-KEY-remi2018 || true; \
    printf '[remi]\nname=Remi EL7\nbaseurl=https://rpms.remirepo.net/enterprise/7/remi/x86_64/\ngpgcheck=1\nenabled=1\n' > /etc/yum.repos.d/remi.repo; \
    yum -y install yum-utils; \
    yum -y remove libwebp-devel; \
    yum-builddep -y -x 'libwebp-devel-0.3*' --define 'dist .el7.sec' /tmp/php.spec; \
    yum clean all
