{%- if pillar.linux.systemget("enabled", False) %}
  {%- if pillar.linux.system.login_defs is mapping %}
login_defs:
  file.keyvalue:
    - name: /etc/login.defs
    - key_values: pillar.linux.system.login_defs
    - append_if_not_found: True
  {%- endif %}
{%- endif %}
