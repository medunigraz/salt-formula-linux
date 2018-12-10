{%- from "linux/map.jinja" import system with context %}

{%- for acl in system.acl %}

linux_acl_{{ acl.path }}_{{ acl.type }}_{{ acl.name }}:
  acl.present:
    - name: {{ acl.path }}
    - acl-name: {{ acl.name }}
    - acl_type: {{ acl.type }}
    - perms: {{ acl.perms }}

{%- endfor %}
