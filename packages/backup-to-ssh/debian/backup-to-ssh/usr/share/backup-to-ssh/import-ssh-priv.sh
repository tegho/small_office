#!/bin/bash

keys_dir="/etc/backup-to-ssh.keys"
key_file="$1"

if [ -z "$keys_dir" ] || [ ! -d "$keys_dir" ] || [ ! -w "$keys_dir" ]; then
  echo "Cannot write keys to $keys_dir"
  exit 1
fi

if [ -z "$key_file" ] || [ ! -r "$key_file" ] ; then
  echo -en "Usage:\n  $0 keyfile\n"
  exit 1
fi

cp -f "$key_file" "$keys_dir" && chmod 600 "$keys_dir"/*
