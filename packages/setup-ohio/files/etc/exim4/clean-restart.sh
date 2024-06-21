#!/bin/bash

find /var/spool/exim4 -type f -delete

# restart exim
update-exim4.conf ; systemctl restart exim4


