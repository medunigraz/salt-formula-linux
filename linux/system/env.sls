{%- from "linux/map.jinja" import system with context %}
{%- if system.get("enabled", False) %}

{%- if system.env is defined %}
{%- if system.env|length > 0 %}

linux_system_environment_proxies:
  file.blockreplace:
  - name: /etc/environment
  - marker_start: '# START - SALT MANAGED VARIABLES, DO NOT EDIT'
  - marker_end:   '# END - SALT MANAGED VARIABLES'
  - template: jinja
  - source: salt://linux/files/etc_environment
  - append_if_not_found: True
  - backup: '.bak'
  - show_changes: True
  - defaults:
      variables: {{ system.env | yaml }}

{%- else %}

linux_system_environment_proxies:
  file.blockreplace:
  - name: /etc/environment
  - marker_start: '# SALT MANAGED VARIABLES - DO NOT EDIT - START'
  - content:      '# '
  - marker_end:   '# SALT MANAGED VARIABLES - END'
  - append_if_not_found: True
  - backup: '.bak'
  - show_changes: True

{%- endif %}
{%- endif %}
{%- endif %}
