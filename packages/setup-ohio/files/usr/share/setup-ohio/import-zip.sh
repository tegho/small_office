#!/bin/bash

import_file="$1"

if [ -z "$import_file" ] || [ ! -s "$import_file" ] ; then
  echo "No zip file specified or it is empty"
  exit 1
fi

mkdir -p /etc/prometheus/pki-montana && \
  tmp_dir=$(mktemp -d /tmp/impXXXXXX) && \
  chmod 700 "$tmp_dir" && \
  unzip "$import_file" -d "$tmp_dir" && \
  rm -f "${tmp_dir}/ta.key" && \
  cp -f "$tmp_dir"/* /etc/prometheus/pki-montana && \
  chown -R 0:prometheus /etc/prometheus/pki-montana && \
  chmod 750 /etc/prometheus/pki-montana && \
  chmod 640 /etc/prometheus/pki-montana/* && \
  cp -f "$tmp_dir/ca.crt" /etc/nginx/pki-montana


rm -rf "$tmp_dir"
