#!/bin/bash

set -e -u

exec &> >(while read -r line; do echo; echo "$0: $line"; done)

echo "Waiting for rabbitmq-server ..."

max_waiting_time=30
remaining_time=$max_waiting_time
while :; do
  if [ $remaining_time -eq 0 ]; then
    echo "Error: Cannot connect to rabbitmq server after ${max_waiting_time}s."
    exit 1
  fi
  rabbitmqctl -q node_health_check &>/dev/null && break || sleep 1s
  remaining_time=$(($remaining_time - 1))
done

if ! (rabbitmqctl list_users \
  | grep -q '^sir\s')
then
  rabbitmqctl add_user sir sir
fi

if ! (rabbitmqctl list_users \
  | grep -q '^sir\s\+\[management\]$')
then
  rabbitmqctl set_user_tags sir management
fi

if ! (rabbitmqctl list_vhosts \
  | grep -q '^/search-index-rebuilder$')
then
  rabbitmqctl add_vhost /search-index-rebuilder
fi

if ! (rabbitmqctl list_permissions -p /search-index-rebuilder \
  | grep -q '^sir\s\+\.\*\s\+\.\*\s\+\.\*$')
then
  rabbitmqctl set_permissions -p /search-index-rebuilder sir '.*' '.*' '.*'
fi

echo "Done."
