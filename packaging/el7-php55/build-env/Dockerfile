# CentOS 7 x86_64 build env for Remi php55 (SCL) 5.5.38 rebuild
FROM php70-el7-build:x86_64
COPY php.spec /tmp/php.spec
RUN set -eux; \
    for k in remi remi2017 remi2018 remi2019 remi2020 remi2021 remi2022 remi2023 remi2024; do rpm --import https://rpms.remirepo.net/RPM-GPG-KEY-$k; done; \
    printf '[remi]\nname=Remi EL7\nbaseurl=https://rpms.remirepo.net/enterprise/7/remi/x86_64/\ngpgcheck=1\nenabled=1\n' > /etc/yum.repos.d/remi.repo; \
    yum -y remove libwebp-devel; \
    yum -y install yum-utils scl-utils-build php55-build-2.1-5.el7.remi php55-runtime-2.1-5.el7.remi; \
    yum-builddep -y -x 'libwebp-devel-0.3*' -x 'libicu[0-9]*' --define 'scl php55' --define 'dist .el7.sec' /tmp/php.spec; \
    yum clean all
