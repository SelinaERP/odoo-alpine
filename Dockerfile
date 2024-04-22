FROM python:3.10-alpine as builder
LABEL maintainer="Fanani M. Ihsan"

RUN echo "Build Odoo Community Edition"

ENV LANG C.UTF-8
ENV ODOO_VERSION 14.0
ENV ODOO_RC /etc/odoo/odoo.conf

WORKDIR /build

# Install some dependencies
RUN apk add -q --no-cache \
    bash \
    build-base \
    ca-certificates \
    fontconfig \
    font-noto-cjk \
    freetype \
    freetype-dev \
    grep \
    jpeg-dev \
    libev-dev \
    libevent-dev \
    libffi-dev \
    libjpeg \
    libjpeg-turbo-dev \
    libpng \
    libpng-dev \
    libssl3 \
    libstdc++ \
    libx11 \
    libxcb \
    libxext \
    libxml2-dev \
    libxrender \
    libxslt-dev \
    nodejs \
    npm \
    openldap-dev \
    postgresql-dev \
    python3-dev \
    rsync \
    ttf-dejavu \
    ttf-droid \
    ttf-freefont \
    ttf-liberation \
    zlib \
    zlib-dev

RUN npm install -g less rtlcss postcss
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.19.0-0.12.6-full /bin/wkhtmltopdf /bin/wkhtmltopdf
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.19.0-0.12.6-full /bin/wkhtmltoimage /bin/wkhtmltoimage
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.19.0-0.12.6-full /bin/libwkhtmltox.so /bin/libwkhtmltox.so
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.19.0-0.12.6-full /bin/libwkhtmltox.so.0 /bin/libwkhtmltox.so.0
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.19.0-0.12.6-full /bin/libwkhtmltox.so.0.12 /bin/libwkhtmltox.so.0.12
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.19.0-0.12.6-full /bin/libwkhtmltox.so.0.12.6 /bin/libwkhtmltox.so.0.12.6
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.19.0-0.12.6-full /lib/libssl.so.3 /lib/libssl.so.3
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.19.0-0.12.6-full /usr/lib/libssl.so.3 /usr/lib/libssl.so.3

# Create addons directory
RUN mkdir /mnt/addons

# Add Odoo Community
ADD https://github.com/odoo/odoo/archive/refs/heads/${ODOO_VERSION}.zip .
RUN unzip -qq ${ODOO_VERSION}.zip && cd odoo-${ODOO_VERSION} && \
    pip3 install -q --upgrade pip && \
    pip3 install -q --upgrade setuptools && \
    echo 'INPUT ( libldap.so )' > /usr/lib/libldap_r.so && \
    pip3 install -q --no-cache-dir -r requirements.txt && \
    python3 setup.py install && \
    mkdir -p /mnt/addons/community && \
    rsync -a --exclude={'__pycache__','*.pyc'} ./addons/ /mnt/addons/community/

# Fix alpine python path
COPY ./usr/local/bin/odoo.sh /usr/local/bin/odoo.sh
COPY ./usr/local/bin/wait-for-psql.py /usr/local/bin/wait-for-psql.py

# Clear Installation cache
RUN find /usr/local \( -type d -a -name __pycache__ \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' + && \
    find /mnt/addons \( -type d -a -name __pycache__ \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' + && \
    rm -rf /build

FROM python:3.10-alpine as main

ENV LANG C.UTF-8
ENV ODOO_VERSION 14.0
ENV ODOO_RC /etc/odoo/odoo.conf

# Install some dependencies
RUN apk add -q --no-cache \
    bash \
    fontconfig \
    font-noto-cjk \
    freetype \
    nginx \
    supervisor \
    syslog-ng \
    ttf-dejavu \
    ttf-droid \
    ttf-freefont \
    ttf-liberation

# Change the ownership working directory
RUN chown nginx:nginx -R /mnt

# Copy base libs
COPY --from=builder /lib /lib
COPY --from=builder /var/lib /var/lib
COPY --from=builder /usr/lib /usr/lib
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /bin /bin
COPY --from=builder /usr/bin /usr/bin
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /sbin /sbin
COPY --from=builder /usr/sbin /usr/sbin
COPY --from=builder --chown=nginx:nginx /mnt /mnt

# Copy entire supervisor configurations
COPY ./etc/ /etc/

# Copy init script
COPY ./write_config.py /write_config.py
COPY ./entrypoint.sh /entrypoint.sh

# Expose web service
EXPOSE 8080

WORKDIR /mnt
ENTRYPOINT ["/entrypoint.sh"]
