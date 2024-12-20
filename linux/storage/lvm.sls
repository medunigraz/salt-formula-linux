{%- from "linux/map.jinja" import storage with context %}
{%- if storage.get('enabled', False) %}

linux_lvm_pkgs:
  pkg.installed:
  - pkgs: {{ storage.lvm_pkgs | json }}


/etc/lvm/lvm.conf:
  file.managed:
  - source: salt://linux/files/lvm.conf
  - template: jinja
  - require:
    - pkg: linux_lvm_pkgs

lvm_services:
  service.running:
  - enable: true
  - names: {{ storage.lvm_services }}
  - require:
    - file: /etc/lvm/lvm.conf
  - watch:
    - file: /etc/lvm/lvm.conf

{%- for vgname, vg in storage.lvm.items() %}

{%- if vg.get('enabled', True) %}

{%- for dev in vg.devices %}
lvm_{{ vg.get('name', vgname) }}_pv_{{ dev }}:
  lvm.pv_present:
    - name: {{ dev }}
    - require:
      - pkg: linux_lvm_pkgs
      - file: /etc/lvm/lvm.conf
      - service: lvm_services
    - require_in:
      - lvm: lvm_vg_{{ vg.get('name', vgname) }}
{%- endfor %}

lvm_vg_{{ vg.get('name', vgname) }}:
  lvm.vg_present:
    - name: {{ vg.get('name', vgname) }}
    - devices: {{ vg.devices|join(',') }}

{%- if vg.get('volume', None) %}
{%- for lvname, volume in vg.volume.items() %}

lvm_{{ vg.get('name', vgname) }}_lv_{{ volume.get('name', lvname) }}:
  lvm.lv_present:
    - order: 1
    - name: {{ volume.get('name', lvname) }}
    - vgname: {{ vg.get('name', vgname) }}
    {%- if volume.size is defined %}
    - size: {{ volume.size }}
    {%- endif %}
    {%- if volume.extents is defined %}
    - extents: {{ volume.extents }}
    {%- endif %}
    {%- if volume.stripes is defined %}
    - stripes: {{ volume.stripes }}
    {%- endif %}
    {%- if (volume.force is defined and volume.force is sameas true) %}
    - force: True
    {%- else %}
    - force: False
    {%- endif %}
    - require:
      - lvm: lvm_vg_{{ vg.get('name', vgname) }}
    {%- if (volume.mount is defined) %}
    - require_in:
      - mount: {{ volume.mount.path }}
    {%- if not volume.mount.get('file_system', None) in ['nfs', 'nfs4', 'cifs', 'tmpfs', None] %}
      - cmd: mkfs_{{ volume.mount.device}}
    {%- endif %}
    {%- endif %}

{%- endfor %}
{%- endif %}

{%- endif %}

{%- endfor %}

{%- endif %}
