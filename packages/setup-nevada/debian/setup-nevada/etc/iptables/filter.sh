#!/bin/bash

IPS=$(which ipset)
IPT=$(which iptables)
IPT6=$(which ip6tables)

function clearfw () {
  $IPT -t filter -F
  $IPT -t nat -F
  $IPT -t mangle -F

  $IPS -quiet destroy vpnnets
  $IPS create vpnnets hash:net -exist

  $IPT -t filter -P INPUT ACCEPT
  $IPT -t filter -P OUTPUT ACCEPT
  $IPT -t filter -P FORWARD ACCEPT

  $IPT6 -t filter -F
  $IPT6 -t nat -F
  $IPT6 -t mangle -F

  $IPT6 -t filter -P INPUT ACCEPT
  $IPT6 -t filter -P OUTPUT ACCEPT
  $IPT6 -t filter -P FORWARD ACCEPT
}

if [ ! -f "$IPT" ] || [ ! -x "$IPT" ] || [ ! -f "$IPT6" ] || [ ! -x "$IPT6" ] ||[ ! -f "$IPS" ] || [ ! -x "$IPS" ] ; then
  echo "Need iptables and ipset installed"
  exit 1
fi

if [ "$1" == "clearfw" ] ; then
  clearfw
  exit 0
fi


clearfw

######## IPV4 ##############

$IPS add vpnnets 192.168.192.0/22
$IPT -t filter -A FORWARD -m set --match-set vpnnets src -j ACCEPT
$IPT -t filter -A FORWARD -m set --match-set vpnnets dst -m state --state ESTABLISHED  -j ACCEPT
$IPT -t filter -A FORWARD -m set --match-set vpnnets dst -m state --state RELATED  -j ACCEPT
#$IPT -t filter -A FORWARD -m set --match-set vpnnets dst -m state --state INVALID  -j DROP
#$IPT -t filter -A FORWARD -m set --match-set vpnnets dst -j DROP
$IPT -t filter -A FORWARD -j DROP

$IPT -t filter -A OUTPUT -j ACCEPT

$IPT -t filter -A INPUT -i lo -j ACCEPT
$IPT -t filter -A INPUT -m state --state ESTABLISHED -j ACCEPT
$IPT -t filter -A INPUT -m state --state RELATED -j ACCEPT
$IPT -t filter -A INPUT -m state --state INVALID -j DROP
$IPT -t filter -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
$IPT -t filter -A INPUT -p udp -m set --match-set vpnnets src -m multiport --dport 53 -j ACCEPT
$IPT -t filter -A INPUT -p tcp -m set --match-set vpnnets src -m multiport --dport 53 -j ACCEPT
$IPT -t filter -A INPUT -p tcp -m multiport --dport 22,80,443,993 -j ACCEPT
$IPT -t filter -A INPUT -p udp -m multiport --dport 500,4500 -j ACCEPT
$IPT -t filter -A INPUT -p esp -j ACCEPT
$IPT -t filter -A INPUT -j DROP

$IPT -t nat -A POSTROUTING -m set --match-set vpnnets src -m set ! --match-set vpnnets dst -j MASQUERADE

######## IPV6 ##############

# add vpnnets rules here if ipv6 clients are supported

$IPT6 -t filter -A FORWARD -j DROP

$IPT6 -t filter -A OUTPUT -j ACCEPT

$IPT6 -t filter -A INPUT -i lo -j ACCEPT
$IPT6 -t filter -A INPUT -m state --state ESTABLISHED -j ACCEPT
$IPT6 -t filter -A INPUT -m state --state RELATED -j ACCEPT
$IPT6 -t filter -A INPUT -m state --state INVALID -j DROP
$IPT6 -t filter -A INPUT -p icmpv6 -m icmpv6 --icmpv6-type 8 -j ACCEPT
$IPT6 -t filter -A INPUT -p tcp -m multiport --dport 22,80,443,993 -j ACCEPT
$IPT6 -t filter -A INPUT -p udp -m multiport --dport 500,4500 -j ACCEPT
$IPT6 -t filter -A INPUT -p esp -j ACCEPT
$IPT6 -t filter -A INPUT -j DROP


exit 0
