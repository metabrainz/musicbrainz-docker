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

rabbitmqctl add_user sir sir
rabbitmqctl set_user_tags sir management
rabbitmqctl add_vhost /search-index-rebuilder
rabbitmqctl set_permissions -p /search-index-rebuilder sir '.*' '.*' '.*'

echo "Done."
