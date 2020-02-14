{%- from "linux/map.jinja" import storage with context %}
{%- if storage.enabled %}

{%- for path, mount in storage.systemd.items() %}

{%- if mount.enabled %}
{%- set unit = salt['cmd.run']('systemd-escape -p --suffix=mount '+path) %}

{{ unit }}_packages:
  pkg.installed:
  - pkgs: {{ storage.get(mount.file_system, {}).get('pkgs', []) }}

{%- if not mount.file_system in ['nfs', 'nfs4', 'cifs', 'tmpfs', 'ceph'] %}
mkfs_{{ mount.device }}:
  cmd.run:
  - name: 'mkfs.{{ mount.file_system }} -L "{{ mount.get('label', '') }}" {{ mount.device }}'
  - onlyif: 'test `blkid {{ mount.device }} | grep -q TYPE;echo $?` -eq 1'
  - require_in:
    - service: {{ unit }}
  - require:
    - pkg: {{ unit }}_packages
{%- if mount.lvm is defined %}
    - lvm: lvm_{{ mount.lvm.vg }}_lv_{{ mount.lvm.lv }}
{%- endif %}
{%- endif %}

/etc/systemd/system/{{ unit }}:
  file.managed:
    - source: salt://linux/files/systemd-mount.conf
    - user: root
    - group: root
    - mode: 640
    - template: jinja
    - context:
        path: {{ path }}
        device: {{ mount.device }}
        type: {{ mount.file_system }}
        options: {{ mount.get('options', 'defaults,noatime') }}
        description: {{ mount.get('description', 'Salt managed mount') }}
        wanted_by: {{ mount.get('wanted_by', 'multi-user.target') }}
    - require:
      - pkg: {{ unit }}_packages

{{ unit }}:
  service.running:
    - enable: True
    - reload: False
    - require:
      - file: /etc/systemd/system/{{ unit }}
    - watch:
      - file: /etc/systemd/system/{{ unit }}

{%- if mount.user is defined %}
{{ unit }}_permissions:
  file.directory:
    - name: {{ path }}
    - user: {{ mount.user }}
    - group: {{ mount.get('group', 'root') }}
    - mode: {{ mount.get('mode', 755) }}
    - require:
      - service: {{ unit }}
{%- endif %}

{%- endif %}

{%- endfor %}

{%- endif %}
