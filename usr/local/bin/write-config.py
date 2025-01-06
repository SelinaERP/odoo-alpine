#!/usr/bin/env python3
import os
from configparser import ConfigParser
from odoo.tools import config as odoo_config

ODOO_CONFIG_FILE = os.environ['ODOO_RC']
ODOO_CONFIG_SECTIONS = os.environ['ODOO_RC_GROUPS'].split(',')
CONFIG_MAPPER = {}

config_parser = ConfigParser()
config_parser.read(ODOO_CONFIG_FILE)
for section in config_parser.sections():
    if section not in ODOO_CONFIG_SECTIONS:
        ODOO_CONFIG_SECTIONS.append(section)

for section in ODOO_CONFIG_SECTIONS:
    CONFIG_MAPPER[section] = {}
    if section not in config_parser.keys():
        continue
    for key, value in config_parser[section].items():
        CONFIG_MAPPER[section][key] = value

# add some config from OS environment
for variable, value in os.environ.items():
    try:
        option, key = variable.lower().split("__")
        if option in ODOO_CONFIG_SECTIONS:
            CONFIG_MAPPER[option][key] = value
    except ValueError:
        # skip invalid config
        pass

config_maps = odoo_config.casts
for section in ODOO_CONFIG_SECTIONS:
    for config in CONFIG_MAPPER[section]:
        value = ""
        try:
            # official odoo config
            config_type = config_maps[config].type
            if config_type == "int":
                value = int(CONFIG_MAPPER[section][config])
            elif config_type == "float":
                value = float(CONFIG_MAPPER[section][config])
            else:
                value = str(CONFIG_MAPPER[section][config])
        except Exception:
            # non represented odoo config
            try:
                # numericable first
                value = int(CONFIG_MAPPER[section][config])
            except Exception:
                value = CONFIG_MAPPER[section][config]
        finally:
            config_parser[section][config] = str(value).replace('\n', '')


if __name__ == "__main__":
    with open(ODOO_CONFIG_FILE, "w") as configfile:
        config_parser.write(configfile)
