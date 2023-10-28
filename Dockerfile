FROM ubuntu:mantic-20231011@sha256:4c32aacd0f7d1d3a29e82bee76f892ba9bb6a63f17f9327ca0d97c3d39b9b0ee

WORKDIR /app

ENV PYTHONUNBUFFERED=1

RUN groupadd --system weewx && useradd --system --create-home --gid weewx weewx

RUN mkdir -p /var/www/html/weewx /var/lib/weewx

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get -y --no-install-recommends install \
        wget \
        curl \
        gnupg \
        build-essential \
        ca-certificates \
        libfreetype6-dev \
        git \
        fonts-freefont-ttf \
        python3-pip \
        python3-requests \
        python3-paho-mqtt \
        python3-dateutil \
        python3-ephem \
        python3-dev \
        zlib1g-dev zlib1g \
        nginx \
        s6 \
        doas \
        libjpeg-dev libjpeg8 && \
    curl -fSsL https://weewx.com/keys.html | gpg --dearmor --output /etc/apt/trusted.gpg.d/weewx.gpg && \
    curl -fSsL https://weewx.com/apt/weewx-python3.list | tee /etc/apt/sources.list.d/weewx.list && \
    apt-get update && \
    apt-get install --no-install-recommends -y weewx && \
    apt remove -y python3-pillow && \
    python3 -m pip install --break-system-packages Pillow==9.0.1 && \
    apt-get -y remove \
        build-essential \
        python3-dev \
        gnupg \
        libjpeg-dev \
        zlib1g-dev && \
    apt-get clean && rm -rf /tmp/setup /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -fSsL https://github.com/chaunceygardiner/weewx-nws/releases/download/v2.3/weewx-nws-2.3.zip -o /tmp/weewx-nws.zip && \
    wee_extension --install /tmp/weewx-nws.zip && \
    rm /tmp/weewx-nws.zip && \
    curl -fSsL https://github.com/USA-RedDragon/weewxMQTT/archive/refs/heads/master.zip -o /tmp/weewxMQTT.zip && \
    wee_extension --install /tmp/weewxMQTT.zip && \
    rm /tmp/weewxMQTT.zip && \
    curl -fSsL https://github.com/gjr80/weewx-stackedwindrose/releases/download/v3.0.1/stackedwindrose-3.0.1.tar.gz -o /tmp/stackedwindrose.tar.gz && \
    tar -zxvf /tmp/stackedwindrose.tar.gz -C /tmp && \
    cp /tmp/stackedwindrose/bin/user/stackedwindrose.py /usr/share/weewx/user && \
    cp -R /tmp/stackedwindrose/skins/* /etc/weewx/skins && \
    rm -rf /tmp/stackedwindrose.tar.gz /tmp && \
    rm -rf /etc/weewx/skins/Seasons/ && \
    git clone https://github.com/USA-RedDragon/weewx-seasons-dark.git && \
    mv weewx-seasons-dark/skins/Seasons /etc/weewx/skins/ && \
    rm -rf weewx-seasons-dark

COPY --chown=root:root rootfs /
RUN usermod -a -G root weewx

RUN chown -R weewx:weewx /var/www/html/weewx /etc/weewx /usr/share/weewx /var/lib/weewx
RUN chmod g+w /var/www/html/weewx /etc/weewx /usr/share/weewx /var/lib/weewx


CMD ["/bin/s6-svscan", "/etc/s6"]
