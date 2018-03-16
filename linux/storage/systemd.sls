{%- from "linux/map.jinja" import storage with context %}
{%- if storage.enabled %}

{%- for path, mount in storage.systemd.items() %}

{%- if mount.enabled %}

{%- if mount.file_system == 'nfs' %}
linux_storage_nfs_packages:
  pkg.installed:
  - pkgs: {{ storage.nfs.pkgs }}
{%- endif %}

{%- if mount.file_system == 'cifs' %}
linux_storage_cifs_packages:
  pkg.installed:
  - pkgs: {{ storage.cifs.pkgs }}
{%- endif %}

/etc/systemd/system/{{ path.strip('/')|replace('/', '-') }}.mount:
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
        options: {{ mount.get('opts', 'defaults,noatime') }}
        description: {{ mount.get('description', 'Salt managed mount') }}
        wanted_by: {{ mount.get('wanted_by', 'multi-user.target') }}
    - require:
{%- if mount.file_system == 'nfs' %}
      - pkg: linux_storage_nfs_packages
{%- endif %}
{%- if mount.file_system == 'cifs' %}
      - pkg: linux_storage_cifs_packages
{%- endif %}

{{ path.strip('/')|replace('/', '-') }}.mount:
  service.running:
    - enable: True
    - reload: False
    - require:
      file: /etc/systemd/system/{{ path.strip('/')|replace('/', '-') }}.mount
    - watch:
      file: /etc/systemd/system/{{ path.strip('/')|replace('/', '-') }}.mount

{%- endif %}

{%- endfor %}

{%- endif %}
