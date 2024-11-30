# Dakon Slim Odoo Image

An alternate Odoo image to enhance security, boost performance, and streamline operations effectively.

## Quick Links

- [Repository](https://github.com/dakonio/odoo-alpine)
- [Maintainer](https://dakon.io)

## Main Features

- Less ~500 Mb size
- Production ready
- Use alpine and slim
- Less vulnerabilities
- Dynamic environment variable

## Environment Variable

This image's environment variable is dynamic; using the prefix `OPTIONS__<CONFIG_KEY>,` it will be automatically converted to `/etc/odoo.conf`. Here is an example:

```
OPTIONS__ADMIN_PASSWD=secret
OPTIONS__DATA_DIR=/var/lib/odoo
OPTIONS__ADDONS_PATH=/mnt/addons/community
OPTIONS__LOG_HANDLER=:INFO
OPTIONS__LOG_LEVEL=info
OPTIONS__DB_HOST=localhost
OPTIONS__DB_PORT=5432
OPTIONS__DB_USER=odoo
OPTIONS__DB_PASSWORD=odoo
OPTIONS__DB_NAME=False
OPTIONS__WORKERS=3
OPTIONS__PROXY_MODE=True
```

It will be converted on `/etc/odoo/odoo.conf` as:

```
[options]
admin_passwd = secret
data_dir = /var/lib/odoo
addons_path = /mnt/addons/community
server_wide_modules = base,web
log_handler = :INFO
log_level = info
db_host = localhost
db_port = 5432
db_user = odoo
db_password = odoo
db_name = false
workers = 3
proxy_mode = true
```


## How to use this image?


### With Docker Compose

The easiest way to use this image is by using docker-compose. Create `docker-compose.yml` on your project.


```
services:

  db:
    image: postgres
    container_name: db
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_PASSWORD=odoo
      - POSTGRES_USER=odoo
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - db-data:$PGDATA

  odoo:
    image: dakonio/odoo
    container_name: odoo
    ports:
      - "80:8080"
    environment:
      - OPTIONS__ADMIN_PASSWD=secret
      - OPTIONS__DATA_DIR=/var/lib/odoo
      - OPTIONS__ADDONS_PATH=/mnt/addons/community
      - OPTIONS__LOG_HANDLER=:INFO
      - OPTIONS__LOG_LEVEL=info
      - OPTIONS__DB_HOST=db
      - OPTIONS__DB_PORT=5432
      - OPTIONS__DB_USER=odoo
      - OPTIONS__DB_PASSWORD=odoo
      - OPTIONS__DB_NAME=False
      - OPTIONS__WORKERS=3
      - OPTIONS__PROXY_MODE=True
    depends_on:
      - db
    links:
      - db
    volumes:
      - odoo-data:/mnt
    platform: linux/amd64

volumes:
  db-data:
    driver: local
  odoo-data: {}
```

Then, run the following command.

`docker-compose run -d`
