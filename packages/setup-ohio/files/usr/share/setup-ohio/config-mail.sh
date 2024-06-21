#!/bin/bash

import_file="$1"

if [ -z "$import_file" ] || [ ! -s "$import_file" ] ; then
  echo "No mail secrets file specified or it is empty"
  echo "Secrets file should look like:"
  echo '#################'
  echo 'fromname="InfoBot"'
  echo 'from="mybot@yandex.ru"'
  echo 'smarthost="smtp.yandex.ru"'
  echo 'smarthost_port="587"'
  echo 'passwd="smtp-password"'
  echo 'adminmail="admin@example.com"'
  echo '#################'

  exit 1
fi

if ! source "$import_file" ; then
  echo "Something is wrong with $import_file"
  exit 1
fi


conf="/etc/exim4/update-exim4.conf.conf"
if [ -f "$conf" ] && [ -w "$conf" ] ; then
  grep -qs '^[ \t]*dc_smarthost[ \t]*=' "$conf" || echo "dc_smarthost='$smarthost::$smarthost_port'" >> "$conf"
else
  echo "Cannot write to $conf file"
fi

conf="/etc/exim4/passwd.client"
if [ -f "$conf" ] && [ -w "$conf" ] ; then
  grep -qs "^[ \t]*$smarthost:$from:" "$conf" || echo "$smarthost:$from:$passwd" >> "$conf"
else
  echo "Cannot write to $conf file"
fi

conf="/etc/email-addresses"
if [ -f "$conf" ] && [ -w "$conf" ] ; then
  grep -qs "^[ \t]*\*:" "$conf" || echo "*: $fromname <$from>" >> "$conf"
else
  echo "Cannot write to $conf file"
fi

conf="/etc/prometheus/alertmanager.yml"
if [ -f "$conf" ] && [ -w "$conf" ] ; then
  sed --follow-symlinks -i "/^\W*#/ ! s/'configohioadminmailaddress@example.com'/\'$adminmail\'/" "$conf"
else
  echo "Cannot write to $conf file"
fi

deb-systemd-invoke restart exim4
deb-systemd-invoke restart prometheus-alertmanager
