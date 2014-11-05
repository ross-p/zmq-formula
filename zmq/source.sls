{% from "zmq/map.jinja" import zmq with context -%}

{% set version = salt['pillar.get']('zmq:source:version', '4.0.5') -%}
{% set checksum = salt['pillar.get']('zmq:source:checksum', 'sha256=3bc93c5f67370341428364ce007d448f4bb58a0eaabd0a60697d8086bc43342b') -%}

{% set zeromq_XYZ = 'zeromq-' + version -%}
{% set archive_name = zeromq_XYZ + '.tar.gz' -%}
{% set archive_url = 'http://download.zeromq.org/' + archive_name -%}

zmq-source-dependencies:
  pkg.installed:
    - names:
      - libtool
      - pkg-config
      - build-essential
      - autoconf
      - automake
      - uuid-dev

get-zmq-source:
  archive:
    - extracted
    - name: {{ zmq.source_root }}
    - source: {{ archive_url }}
    - source_hash: {{ checksum }}
    - archive_format: tar
    - tar_options: z
    - if_missing: {{ zmq.source_root }}/{{ zeromq_XYZ }}

is-zmq-compile-required:
  cmd.run:
    - cwd: {{ zmq.source_root }}
    - name: test -e {{ zeromq_XYZ }}/src/libzmq.la || echo "changed=true comment='Make has not succeeded'"
    - stateful: True

compile-zmq-source:
  cmd.wait:
    - cwd: {{ zmq.source_root }}/{{ zeromq_XYZ }}
    - name: ./configure {{ zmq.configure_flags }} && make {{ zmq.make_flags }}
    - watch:
      - archive: get-zmq-source
      - cmd: is-zmq-compile-required
    - require:
      - archive: get-zmq-source
      - pkg: zmq-source-dependencies

install-zmq:
  cmd.wait:
    - cwd: {{ zmq.source_root }}/{{ zeromq_XYZ }}
    - name: make install && ldconfig
    - watch:
      - cmd: compile-zmq-source
    - require:
      - cmd: compile-zmq-source
