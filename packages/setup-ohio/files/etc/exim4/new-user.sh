#!/bin/bash

# apt install whois

username="user"
passwd='xx'

echo "$username:"$(echo -n "$passwd" |mkpasswd -sm sha512crypt)
