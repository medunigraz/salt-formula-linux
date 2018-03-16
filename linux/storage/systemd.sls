{%- from "linux/map.jinja" import storage with context %}
{%- if storage.enabled %}

{%- for path, mount in storage.systemd.items() %}

{%- if mount.enabled %}

{{ path.strip('/')|replace('/', '-') }}_packages:
  pkg.installed:
  - pkgs: {{ storage.get(mount.file_system, {}).get('pkgs', []) }}

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
        options: {{ mount.get('options', 'defaults,noatime') }}
        description: {{ mount.get('description', 'Salt managed mount') }}
        wanted_by: {{ mount.get('wanted_by', 'multi-user.target') }}
    - require:
      - pkg: {{ path.strip('/')|replace('/', '-') }}_packages

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
