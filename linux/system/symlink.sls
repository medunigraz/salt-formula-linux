{%- from "linux/map.jinja" import system with context %}
{%- if system.enabled %}

{%- for symlink_name, symlink in system.symlink.items() %}

linux_symlink_{{ symlink_name }}:
  file.symlink:
    {%- if symlink.name is defined %}
    - name: {{ symlink.name }}
    {%- else %}
    - name: {{ symlink_name }}
    {%- endif %}
    - target: {{ symlink.target }}
    {%- if symlink.makedirs is defined %}
    - makedirs: {{ symlink.makedirs }}
    {%- endif %}
    {%- if symlink.user is defined %}
    - user: {{ symlink.user }}
    {%- endif %}
    {%- if symlink.group is defined %}
    - group: {{ symlink.group }}
    {%- endif %}
    {%- if symlink.mode is defined %}
    - mode: {{ symlink.mode }}
    {%- endif %}
    {%- if symlink.force is defined %}
    - force: {{ symlink.force }}
    {%- endif %}

{%- endfor %}

{%- endif %}
