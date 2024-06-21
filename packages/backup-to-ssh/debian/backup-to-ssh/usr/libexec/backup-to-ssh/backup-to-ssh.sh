#!/bin/bash

config_dir="/etc/backup-to-ssh.d"

function alert() {
  echo "$1"
#  logger -t "backup-to-ssh" "$1"
}

parse_config() {
  local config_file="$1"
  local key
  local value
  local ret
  local hash_local
  local hash_remote
  local private_key
  local object_to_backup
  local keep_recent
  local timestamp
  local t

  if [ ! -f "$config_file" ] || [ ! -r "$config_file" ] || ! source "$config_file" &> /dev/null ; then
    alert "Can't open config: $config_file"
    return 1
  fi

  local oldifs="$IFS"
  sed -n '/^[\t ]*#/d;/^[\t ]*$/d;p' "$config_file" | while IFS='=' read -r key value; do
    if [[ $key && $value ]]; then
      declare "$key=$value"
    fi
  done
  IFS="$oldifs"

  if [ -z "$label" ] ; then
    [ "$(basename $config_file)" != "example.conf" ] && alert "Variable \"label\" is not set in $config_file"
    return 1
  else
    t=$(echo "$label" | sed 's/[^0-9a-zA-Z_\-]//g')
    if [ "$t" != "$label" ] ; then
      [ "$(basename $config_file)" != "example.conf" ] && alert "Variable \"label\" has some bad symbols in $config_file"
      return 1
    fi
  fi

  if [ -z "$ssh_userhost" ] ; then
    [ "$(basename $config_file)" != "example.conf" ] && alert "Variable \"ssh_userhost\" is not set in $config_file"
    return 1
  fi

  [ -n "$private_key" ] && private_key=$(realpath -ms -- "$private_key")
  if [ -z "$private_key" ] || [ ! -r "$private_key" ] || [ ! -s "$private_key" ] ; then
    [ "$(basename $config_file)" != "example.conf" ] && alert "Variable \"private_key\" is not set or private key is unreadable in $config_file"
    return 1
  fi

  [ -n "$object_to_backup" ] && object_to_backup=$(realpath -ms -- "$object_to_backup")
  if [ -z "$object_to_backup" ] || [ ! -r "$object_to_backup" ] ; then
    [ "$(basename $config_file)" != "example.conf" ] && alert "Variable \"object_to_backup\" is not set or the object is unreadable in $config_file"
    return 1
  fi
  if [ -z "$keep_recent" ] ; then
    [ "$(basename $config_file)" != "example.conf" ] && alert "Variable \"keep_recent\" is not set in $config_file"
    return 1
  else
    t=$(echo "$keep_recent" | sed 's/[^0-9]//g')
    if [ "$t" != "$keep_recent" ] ; then
      alert "Variable \"keep_recent\" is not an integer in $config_file"
      return 1
    elif [ "$t" -lt 1 ]; then
      alert "Variable \"keep_recent\" must be greater than 0 in $config_file"
      return 1
    fi
  fi

#  echo ">> LABEL: $label"
#  echo ">> $ssh_userhost"
#  echo ">> $private_key"
#  echo ">> $object_to_backup"
#  echo ">> $keep_recent"

  ret=1
  # archive files
  if archive_file=$(mktemp /tmp/bkpXXXXXX) ; then
    chmod 600 "$archive_file"
    tar czf "$archive_file" -C $(dirname "$object_to_backup") --one-file-system $(basename "$object_to_backup") && \
      hash_local=$(sha256sum "$archive_file" | cut -d" " -f1) && ret=0
  fi

  # upload archive
  if [ "$ret" -eq 0 ]; then
    timestamp=$(date +%Y%m%d%H%M%S)

    # scp -o StrictHostKeyChecking=accept-new -pr -i "$private_key" "$archive_file" "scp://$ssh_userhost/backups/${label}_$timestamp.tgz"
    hash_remote=$(cat "$archive_file" | ssh -o StrictHostKeyChecking=accept-new -i "$private_key" "$ssh_userhost" \
      "archive=\"\$HOME/backups/$label/${label}_$timestamp.tgz\";\
       mkdir -p \$(dirname \"\$archive\");\
       cat > \"\$archive\";\
       sha256sum \"\$archive\" | cut -d\" \" -f1";\
    )

    if [ "$hash_remote" != "$hash_local" ] ; then
      # hash mismatch, remove remote archive
      ssh -ni "$private_key" "$ssh_userhost" "archive=\"\$HOME/backups/$label/${label}_$timestamp.tgz\"; rm -f \"$archive\""
      alert "Upload failed, hash mismatch"
      ret=1
    else
      # hash is ok, remove all but last $keep_recent archives and refresh prometheus metric
      ssh -ni "$private_key" "$ssh_userhost" \
        'archive="$HOME/backups/'$label'/'$label'_'$timestamp'.tgz"; \
         adir=$(dirname "$archive"); \
         ls -1v "$adir/"*.tgz | head -n -'$keep_recent'|while read fname; do rm -f "$fname"; done'

        [ -d "/var/lib/prometheus/node-exporter" ] && [ -w "/var/lib/prometheus/node-exporter" ] && echo -ne "# HELP last successfull backup time.\n# TYPE backup_to_ssh counter\nbackup_to_ssh{task=\"$label\"} $(date +%s)\n" > "/var/lib/prometheus/node-exporter/backup-to-ssh-$label.prom"
    fi
  fi

  rm -f "$archive_file"
  return $ret
}

echo "###############################################"
ls "$config_dir"/*.conf | while read fname; do
  parse_config "$fname"
done
