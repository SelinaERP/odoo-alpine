FROM python:3.12-alpine AS builder
LABEL maintainer="fanani.mi@gmail.com"

RUN echo "Build Odoo Community Edition"

ENV LANG C.UTF-8
ENV PYTHONUNBUFFERED 1
ENV ODOO_VERSION 14.0
ENV ODOO_RC /etc/odoo/odoo.conf
ENV ODOO_RC_GROUPS options

WORKDIR /build

# Install some dependencies
RUN apk add -q --no-cache \
    bash \
    build-base \
    ca-certificates \
    jpeg-dev \
    libev-dev \
    libevent-dev \
    libffi-dev \
    libjpeg \
    libjpeg-turbo-dev \
    libpng \
    libpng-dev \
    libpq \
    libpq-dev \
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
    py3-pip \
    python3-dev \
    rsync \
    zlib \
    zlib-dev

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

# Add some scripts
ADD ./entrypoint.sh /entrypoint.sh
ADD ./usr/local/bin/wait-for-psql.py /usr/local/bin/wait-for-psql.py
RUN chmod 755 /entrypoint.sh && chmod 755 /usr/local/bin/wait-for-psql.py

# Clear Installation cache
RUN find /usr/local \( -type d -a -name __pycache__ \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' + && \
    find /mnt/addons \( -type d -a -name __pycache__ \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' + && \
    rm -rf /build

FROM python:3.12-alpine AS main

ENV LANG C.UTF-8
ENV PYTHONUNBUFFERED 1
ENV ODOO_VERSION 14.0
ENV ODOO_RC /etc/odoo/odoo.conf
ENV ODOO_RC_GROUPS options

# Copy base libs
COPY --from=builder /bin /bin
COPY --from=builder /lib /lib
COPY --from=builder /usr /usr

# add wkhtmltopdf
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.12-0.12.6-full /bin/wkhtmltopdf /bin/wkhtmltopdf
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.12-0.12.6-full /bin/wkhtmltoimage /bin/wkhtmltoimage
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.12-0.12.6-full /bin/libwkhtmltox.so /bin/libwkhtmltox.so
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.12-0.12.6-full /bin/libwkhtmltox.so.0 /bin/libwkhtmltox.so.0
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.12-0.12.6-full /bin/libwkhtmltox.so.0.12 /bin/libwkhtmltox.so.0.12
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.12-0.12.6-full /bin/libwkhtmltox.so.0.12.6 /bin/libwkhtmltox.so.0.12.6
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.12-0.12.6-full /lib/libssl.so.1.1 /lib/libssl.so.1.1
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.12-0.12.6-full /lib/libcrypto.so.1.1 /lib/libcrypto.so.1.1
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.12-0.12.6-full /usr/share/fonts /usr/share/fonts

# Install some dependencies
RUN apk add -q --no-cache \
    bash \
    fontconfig \
    font-noto-cjk \
    libpq \
    libxrender \
    sassc

# prepare default user
RUN adduser \
    --uid 1000 \
    --home /var/lib/odoo \
    --disabled-password \
    --gecos "Odoo" \
    --system \
    odoo

# Copy all necessary code, script, and config
COPY --from=builder --chown=odoo:odoo /mnt /mnt
COPY --from=builder --chown=odoo:odoo /entrypoint.sh /entrypoint.sh
COPY --chown=odoo:odoo /etc/odoo/odoo.conf /etc/odoo/odoo.conf
COPY --chown=odoo:odoo /usr/local/bin/write-config.py /usr/local/bin/write-config.py
RUN sed -i "s/set -e/set -e \nwrite-config.py/g" /entrypoint.sh
RUN mkdir /var/lib/odoo && chown odoo:odoo -R /var/lib/odoo


# Expose web service
USER odoo
EXPOSE 8069 8072
ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
