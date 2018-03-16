{%- from "linux/map.jinja" import storage with context %}
include:
{%- if storage.loopback|length > 0 %}
- linux.storage.loopback
{%- endif %}
{%- if storage.disk|length > 0 %}
- linux.storage.disk
{%- endif %}
{%- if storage.lvm|length > 0 %}
- linux.storage.lvm
{%- endif %}
{%- if storage.mount|length > 0 %}
- linux.storage.mount
{%- endif %}
{%- if storage.systemd|length > 0 %}
- linux.storage.systemd
{%- endif %}
{%- if storage.swap|length > 0 %}
- linux.storage.swap
{%- endif %}
{%- if storage.multipath.enabled %}
- linux.storage.multipath
{%- endif %}
