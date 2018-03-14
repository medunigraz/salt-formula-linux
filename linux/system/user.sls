{%- from "linux/map.jinja" import system with context %}
{%- if system.enabled %}

{%- set sudo = False %}
{%- for name, user in system.user.items() %}
{%- if user.enabled %}
{%- if user.sudo %}
{%- set sudo = True %}
{%- endif %}
{%- endif %}
{%- endfor %}


include:
  - linux.system.group
{%- if sudo %}
  - linux.system.sudo
{%- endif %}

{%- for name, user in system.user.items() %}

{%- if user.enabled %}

{%- set requires = [] %}
{%- for group in user.get('groups', []) %}
  {%- if group in system.get('group', {}).keys() %}
    {%- do requires.append({'group': 'system_group_'+group}) %}
  {%- endif %}
{%- endfor %}

system_user_{{ name }}:
  user.present:
  - name: {{ name }}
  - home: {{ user.home }}
  {% if user.get('password') == False %}
  - enforce_password: false
  {% elif user.get('password') == None %}
  - enforce_password: true
  - password: '*'
  {% elif user.get('password') %}
  - enforce_password: true
  - password: {{ user.password }}
  - hash_password: {{ user.get('hash_password', False) }}
  {% endif %}
  - gid_from_name: {{ user.get('gid_from_name', False) }}
  {%- if user.groups is defined %}
  - groups: {{ user.groups }}
  {%- endif %}
  {%- if user.system is defined and user.system %}
  - system: True
  {%- else %}
  - shell: {{ user.get('shell', '/bin/bash') }}
  {%- endif %}
  {%- if user.uid is defined and user.uid %}
  - uid: {{ user.uid }}
  {%- endif %}
  - require: {{ requires|yaml }}

system_user_home_{{ user.home }}:
  file.directory:
  - name: {{ user.home }}
  - user: {{ name }}
  - mode: 700
  - makedirs: true
  - require:
    - user: system_user_{{ name }}

{%- if system.get('sudo', {}).get('enabled', False) %}
{%- if user.get('sudo', False) %}

/etc/sudoers.d/90-salt-user-{{ name|replace('.', '-') }}:
  file.managed:
  - source: salt://linux/files/sudoer
  - template: jinja
  - user: root
  - group: root
  - mode: 440
  - defaults:
    user_name: {{ name }}
  - require:
    - user: system_user_{{ name }}
    - pkg: linux_sudo_pkg_installed
  - check_cmd: /usr/sbin/visudo -c -f

{%- else %}

/etc/sudoers.d/90-salt-user-{{ name|replace('.', '-') }}:
  file.absent

{%- endif %}
{%- endif %}

{%- else %}

system_user_{{ name }}:
  user.absent:
  - name: {{ name }}

system_user_home_{{ user.home }}:
  file.absent:
  - name: {{ user.home }}

{%- if system.get('sudo', {}).get('enabled', False) %}
/etc/sudoers.d/90-salt-user-{{ name|replace('.', '-') }}:
  file.absent
{%- endif %}

{%- endif %}

{%- endfor %}

{%- endif %}
