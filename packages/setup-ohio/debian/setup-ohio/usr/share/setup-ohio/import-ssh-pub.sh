#!/bin/bash

printhelp() {
  echo "Usage:"
  echo "  $0 filename-key.pub username"
}

import_file="$1"
username="$2"

if [ -z "$import_file" ] || [ ! -s "$import_file" ] ; then
  echo "No public key specified or the file is empty: $import_file"
  printhelp
  exit 1
fi

if [ -z "$username" ] || ! userhome=$(getent passwd "$username"); then
  echo "Username is empty or not exist: $username"
  printhelp
  exit 1
fi
userhome=$(echo "$userhome"|cut -d: -f6)


if [ -d "$userhome" ] && [ -w "$userhome" ]; then
  mkdir -p "$userhome/.ssh" && cat "$import_file" >> "$userhome/.ssh/authorized_keys" ; chown -R "$username":"$username" "$userhome/.ssh"
fi
