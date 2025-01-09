{%- from "linux/map.jinja" import system with context %}
{%- if system.enabled %}

  {% if system.pkgs %}
linux_repo_prereq_pkgs:
  pkg.installed:
  - pkgs: {{ system.pkgs | json }}
  {%- endif %}

  # global proxy setup
  {%- if grains.os_family == 'Debian' %}
    {%- if system.proxy.get('pkg', {}).get('enabled', False) %}
/etc/apt/apt.conf.d/99proxies-salt:
  file.managed:
  - template: jinja
  - source: salt://linux/files/apt.conf.d_proxies
  - defaults:
      external_host: False
      https: {{ system.proxy.get('pkg', {}).get('https', None) | default(system.proxy.get('https', None), true) }}
      http: {{ system.proxy.get('pkg', {}).get('http', None) | default(system.proxy.get('http', None), true) }}
      ftp: {{ system.proxy.get('pkg', {}).get('ftp', None) | default(system.proxy.get('ftp', None), true) }}
    {%- else %}
/etc/apt/apt.conf.d/99proxies-salt:
  file.absent
    {%- endif %}
  {%- else %}
  # Implement grobal proxy configiration for non-debian OS.
  {%- endif %}

  {% set default_repos = {} %}

  {%- if system.purge_repos|default(False) %}
purge_sources_list_d_repos:
  file.directory:
  - name: /etc/apt/sources.list.d/
  - clean: True
  {%- endif %}

/etc/apt/keyrings:
  file.directory:
  - user: root
  - group: root
  - mode: 700

  {%- for name, repo in system.repo.items() | sort %}
    {%- set name=repo.get('name', name) %}
    {%- if grains.os_family == 'Debian' %}

# per repository proxy setup
      {%- if repo.get('proxy', {}).get('enabled', False) %}
        {%- set external_host = repo.proxy.get('host', None) or repo.source.split('/')[2] %}
/etc/apt/apt.conf.d/99proxies-salt-{{ name }}:
  file.managed:
  - template: jinja
  - source: salt://linux/files/apt.conf.d_proxies
  - defaults:
      external_host: {{ external_host }}
      https: {{ repo.proxy.get('https', None) or system.proxy.get('pkg', {}).get('https', None) | default(system.proxy.get('https', None), True) }}
      http: {{ repo.proxy.get('http', None) or system.proxy.get('pkg', {}).get('http', None) | default(system.proxy.get('http', None), True) }}
      ftp: {{ repo.proxy.get('ftp', None) or system.proxy.get('pkg', {}).get('ftp', None) | default(system.proxy.get('ftp', None), True) }}
      {%- else %}
/etc/apt/apt.conf.d/99proxies-salt-{{ name }}:
  file.absent
      {%- endif %}

      {%- if repo.pin is defined or repo.pinning is defined %}
linux_repo_{{ name }}_pin:
  file.managed:
    - name: /etc/apt/preferences.d/{{ name }}
    - source: salt://linux/files/preferences_repo
    - template: jinja
    - defaults:
        repo_name: {{ name }}
      {%- else %}
linux_repo_{{ name }}_pin:
  file.absent:
    - name: /etc/apt/preferences.d/{{ name }}
      {%- endif %}

      {%- if repo.get("key_url", None) %}
linux_repo_{{ name }}_key:
  cmd.run:
    - name: "curl -sL {{ repo.key_url }} | gnupg --dearmor -o /etc/apt/keyrings/{{ name }}.gpg"
    - require:
      - file: /etc/apt/keyrings
    - require_in:
        {%- if repo.get('default', False) %}
      - file: default_repo_list
        {% else %}
      - pkgrepo: linux_repo_{{ name }}
        {% endif %}
      {%- endif %}

      {%- if repo.get('default', False) %}
        {%- do default_repos.update({name: repo}) %}
      {%- else %}

        {%- if repo.get('enabled', True) %}
linux_repo_{{ name }}:
  pkgrepo.managed:
    - refresh_db: False
    - file: /etc/apt/sources.list.d/{{ name }}.list
          {%- if repo.key_id is defined %}
    - keyid: {{ repo.key_id }}
          {%- endif %}
    - require:
      - file: /etc/apt/apt.conf.d/99proxies-salt-{{ name }}
    - require_in:
      - refresh_db
        {%- else %}
linux_repo_{{ name }}:
  pkgrepo.absent:
    - file: /etc/apt/sources.list.d/{{ name }}.list
    - refresh_db: False
    - require_in:
      - refresh_db
        {%- endif %}
      {%- endif %}
    {%- endif %}

    {%- if grains.os_family == "RedHat" %}

      {%- if repo.get('enabled', True) %}
        {%- if repo.get('proxy', {}).get('enabled', False) %}
# PLACEHOLDER
# TODO, implement per proxy configuration for Yum
        {%- endif %}

        {%- if not repo.get('default', False) %}
linux_repo_{{ name }}:
  pkgrepo.managed:
  - refresh_db: False
  - require_in:
    - refresh_db
  - name: {{ name }}
  - humanname: {{ repo.get('humanname', name) }}
          {%- if repo.mirrorlist is defined %}
  - mirrorlist: {{ repo.mirrorlist }}
          {%- else %}
  - baseurl: {{ repo.source }}
          {%- endif %}
  - gpgcheck: {% if repo.get('gpgcheck', False) %}1{% else %}0{% endif %}
          {%- if repo.gpgkey is defined %}
  - gpgkey: {{ repo.gpgkey }}
          {%- endif %}
        {%- endif %}
      {%- else %}
  pkgrepo.absent:
    - refresh_db: False
    - require_in:
      - refresh_db
    - name: {{ repo.source }}
      {%- endif %}
    {%- endif %}
  {%- endfor %}

  {%- if default_repos|length > 0 and grains.os_family == 'Debian' %}

default_repo_list:
  file.managed:
    - name: /etc/apt/sources.list
    - source: salt://linux/files/sources.list
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    {%- if system.purge_repos|default(False) %}
    - replace: True
    {%- endif %}
    - defaults:
        default_repos: {{ default_repos }}

  {%- endif %}

refresh_db:
  {%- if system.get('refresh_repos_meta', True) %}
  module.run:
    {%- if 'module.run' in salt['config.get']('use_superseded', default=[]) %}
    - pkg.refresh_db: []
    {%- else %}
    - name: pkg.refresh_db
    {% endif %}
  {%- else %}
  test.succeed_without_changes
  {%- endif %}

{%- endif %}
