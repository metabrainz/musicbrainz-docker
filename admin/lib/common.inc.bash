SCRIPT_NAME=$(basename "$0")

if ((BASH_VERSINFO[0] < 4))
then
  echo >&2 "$SCRIPT_NAME: at least version 4 of bash is required"
  echo >&2 "Make sure this version of bash comes first in \$PATH"
  exit 69
fi

MB_DOCKER_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)

cd "$MB_DOCKER_ROOT"

if [ -z ${DOCKER_CMD:+smt} ]
then
  if groups | grep -Eqw 'sudo|wheel'
  then
    DOCKER_CMD='sudo docker'
  elif groups | grep -Eqw 'docker|root'
  then
    DOCKER_CMD='docker'
  elif type sw_vers && [ "$(sw_vers -productName)" = "Mac OS X" ]
  then
    DOCKER_CMD='docker'
  else
    echo >&2 "$SCRIPT_NAME: cannot set docker command: please either"
    echo >&2 "  * add the user '$USER' to the group 'sudo' or 'wheel'"
    echo >&2 "  * or set the variable \$DOCKER_CMD"
    exit 77
  fi
fi

if [ -z ${DOCKER_COMPOSE_CMD:+smt} ]
then
  if groups | grep -Eqw 'sudo|wheel'
  then
    DOCKER_COMPOSE_CMD='sudo docker-compose'
  elif groups | grep -Eqw 'docker|root'
  then
    DOCKER_COMPOSE_CMD='docker-compose'
  elif type sw_vers && [ "$(sw_vers -productName)" = "Mac OS X" ]
  then
    DOCKER_COMPOSE_CMD='docker-compose'
  else
    echo >&2 "$SCRIPT_NAME: cannot set docker-compose command: please either"
    echo >&2 "  * add the user '$USER' to the group 'sudo' or 'wheel'"
    echo >&2 "  * or set the variable \$DOCKER_COMPOSE_CMD"
    exit 77
  fi
fi

# vi: set et sts=2 sw=2 ts=2 :
