SCRIPT_NAME=$(basename "$0")

MB_DOCKER_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)

cd "$MB_DOCKER_ROOT"

if [ -z ${DOCKER_CMD:+smt} ]
then
  if groups | grep -qw sudo
  then
    DOCKER_CMD='sudo docker'
  elif groups | grep -Pqw 'docker|root'
  then
    DOCKER_CMD='docker'
  else
    echo >&2 "$SCRIPT_NAME: cannot set docker command: please either"
    echo >&2 "  * add the user '$USER' to the group 'sudo'"
    echo >&2 "  * or set the variable \$DOCKER_CMD"
    exit 77
  fi
fi

if [ -z ${DOCKER_COMPOSE_CMD:+smt} ]
then
  if groups | grep -qw sudo
  then
    DOCKER_COMPOSE_CMD='sudo docker-compose'
  elif groups | grep -Pqw 'docker|root'
  then
    DOCKER_COMPOSE_CMD='docker-compose'
  else
    echo >&2 "$SCRIPT_NAME: cannot set docker-compose command: please try"
    echo >&2 "  * either adding the user '$USER' to the group 'sudo',"
    echo >&2 "  * or setting the variable \$DOCKER_COMPOSE_CMD."
    exit 77
  fi
fi

# vi: set et sts=2 sw=2 ts=2 :
