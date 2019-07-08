#!/bin/bash

set -e
set -o pipefail

config_keepalived() {
  if ! compgen -A variable | grep -q -E 'KEEPALIVED_VIRTUAL_IPADDRESS_[0-9]{1,3}'; then
    echo "[$(date)][KEEPALIVED] No KEEPALIVED_VIRTUAL_IPADDRESS_ varibles detected."
    return 1
  fi

  KEEPALIVED_STATE=${KEEPALIVED_STATE:-MASTER}

  if [[ "${KEEPALIVED_STATE^^}" == 'MASTER' ]]; then
    KEEPALIVED_PRIORITY=${KEEPALIVED_PRIORITY:-101}
  elif [[ "${KEEPALIVED_STATE^^}" == 'BACKUP' ]]; then
    KEEPALIVED_PRIORITY=${KEEPALIVED_PRIORITY:-100}
  fi
  
  KEEPALIVED_CHECK_SCRIPT=${KEEPALIVED_CHECK_SCRIPT:-"</dev/tcp/127.0.0.1/80"}
  KEEPALIVED_CHECK_INTERVAL=${KEEPALIVED_CHECK_INTERVAL:-1}
  KEEPALIVED_CHECK_WEIGHT=${KEEPALIVED_CHECK_WEIGHT:--5}
  KEEPALIVED_CHECK_FALL=${KEEPALIVED_CHECK_FALL:-3}
  KEEPALIVED_CHECK_RISE=${KEEPALIVED_CHECK_RISE:-2}
  KEEPALIVED_INTERFACE=${KEEPALIVED_INTERFACE:-eth0}
  KEEPALIVED_VIRTUAL_ROUTER_ID=${KEEPALIVED_VIRTUAL_ROUTER_ID:-1}
  KEEPALIVED_ADVERT_INT=${KEEPALIVED_ADVERT_INT:-3}
  KEEPALIVED_AUTH_PASS=${KEEPALIVED_AUTH_PASS:-"pwd$KEEPALIVED_VIRTUAL_ROUTER_ID"}
  KEEPALIVED_UNICAST_AUTOCONF=${KEEPALIVED_UNICAST_AUTOCONF:-false}
  
  if [[ ! $KEEPALIVED_UNICAST_SRC_IP && ${KEEPALIVED_UNICAST_AUTOCONF,,} == 'true' ]]; then
    bind_target="$(ip addr show "$KEEPALIVED_INTERFACE" | \
      grep -m 1 -E -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk '{print $2}')"
    KEEPALIVED_UNICAST_SRC_IP="$bind_target"
  fi

  {
    echo 'vrrp_script check_service {'
    echo "  script \"$KEEPALIVED_CHECK_SCRIPT\""
    echo "  interval $KEEPALIVED_CHECK_INTERVAL"
    echo "  weight $KEEPALIVED_CHECK_WEIGHT"
    echo "  fall $KEEPALIVED_CHECK_FALL"
    echo "  rise $KEEPALIVED_CHECK_RISE"
    echo '}'
  } > "$KEEPALIVED_MAIN_CONF"

  {
    echo 'vrrp_instance MAIN {'
    echo "  state $KEEPALIVED_STATE"
    echo "  interface $KEEPALIVED_INTERFACE"
    echo "  virtual_router_id $KEEPALIVED_VIRTUAL_ROUTER_ID"
    echo "  priority $KEEPALIVED_PRIORITY"
    echo "  advert_int $KEEPALIVED_ADVERT_INT"
  } >> "$KEEPALIVED_MAIN_CONF"
 
  if [[ $KEEPALIVED_UNICAST_SRC_IP ]]; then
    echo "  unicast_src_ip $KEEPALIVED_UNICAST_SRC_IP" >> "$KEEPALIVED_MAIN_CONF"
  fi
 
  if compgen -A variable | grep -q -E 'KEEPALIVED_UNICAST_PEER_[0-9]{1,3}'; then
    echo '  unicast_peer {' >> "$KEEPALIVED_MAIN_CONF"
	  for peer in $(compgen -A variable | grep -E "KEEPALIVED_UNICAST_PEER_[0-9]{1,3}"); do
		echo "    ${!peer}" >> "$KEEPALIVED_MAIN_CONF"
	  done
	echo '  }' >> "$KEEPALIVED_MAIN_CONF"
  fi

  {
    echo '  authentication {'
    echo '    auth_type PASS'
    echo "    auth_pass $KEEPALIVED_AUTH_PASS"
    echo '  }'
    echo '  virtual_ipaddress {'
  }  >> "$KEEPALIVED_MAIN_CONF"
  for vip in $(compgen -A variable | grep -E 'KEEPALIVED_VIRTUAL_IPADDRESS_[0-9]{1,3}'); do
    echo "    ${!vip}" >> "$KEEPALIVED_MAIN_CONF"
  done
  echo '  }' >> "$KEEPALIVED_MAIN_CONF"

  if compgen -A variable | grep -q -E 'KEEPALIVED_TRACK_INTERFACE_[0-9]{1,3}'; then
    echo '  track_interface {' >> "$KEEPALIVED_MAIN_CONF"
    for interface in $(compgen -A variable | grep -E 'KEEPALIVED_TRACK_INTERFACE_[0-9]{1,3}'); do
      echo "    ${!interface}" >> "$KEEPALIVED_MAIN_CONF"
    done
    echo '  }' >> "$KEEPALIVED_MAIN_CONF"
  else
    {
      echo '  track_interface {'
      echo "    $KEEPALIVED_INTERFACE"
      echo '  }'
    } >> "$KEEPALIVED_MAIN_CONF"
 fi
 if [[ ${KEEPALIVED_CHECK_SERVICE,,} == 'true' ]]; then
   {
     echo '  track_script {'
     echo '    check_service'
     echo '  }'
   } >> "$KEEPALIVED_MAIN_CONF"
 fi

  echo '}' >> "$KEEPALIVED_MAIN_CONF"

  return 0
}

init_vars() {
  KEEPALIVED_AUTOCONF=${KEEPALIVED_AUTOCONF:-true}
  KEEPALIVED_DEBUG=${KEEPALIVED_DEBUG:-false}
  KEEPALIVED_CONF=${KEEPALIVED_CONF:-/etc/keepalived/keepalived.conf}
  KEEPALIVED_MAIN_CONF=${KEEPALIVED_MAIN_CONF:-/etc/keepalived/conf.d/main.conf}
  KEEPALIVED_VAR_RUN=${KEEPALIVED_VAR_RUN:-/var/run/keepalived}
  if [[ ${KEEPALIVED_DEBUG,,} == 'true' ]]; then
    local kd_cmd="/usr/sbin/keepalived -n -l -D -f $KEEPALIVED_CONF"
  else
    local kd_cmd="/usr/sbin/keepalived -n -l -f $KEEPALIVED_CONF"
  fi
  KEEPALIVED_CMD=${KEEPALIVED_CMD:-"$kd_cmd"}
}

main() {
  init_vars
  if [[ ${KEEPALIVED_AUTOCONF,,} == 'true' ]]; then
    config_keepalived
  fi
  rm -fr "$KEEPALIVED_VAR_RUN"
  # shellcheck disable=SC2086
  exec $KEEPALIVED_CMD
}
main
