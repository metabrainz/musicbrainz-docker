SCRIPT_NAME=$(basename "$0")

if ((BASH_VERSINFO[0] < 4))
then
  echo >&2 "$SCRIPT_NAME: at least version 4 of bash is required"
  echo >&2 "Make sure this version of bash comes first in \$PATH"
  exit 69 # EX_UNAVAILABLE
fi

MB_DOCKER_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)

cd "$MB_DOCKER_ROOT" || {
  echo >&2 "$SCRIPT_NAME: fail to change directory to '$MB_DOCKER_ROOT'"
  exit 70 # EX_SOFTWARE
}

# Set Docker/Compose commands

if [ -z ${DOCKER_CMD:+smt} ]
then
  case "$OSTYPE" in
    darwin*) # Mac OS X
      DOCKER_CMD='docker'
      ;;
    linux*)
      if groups | grep -Eqw 'docker|root'
      then
        DOCKER_CMD='docker'
      elif groups | grep -Eqw 'sudo|wheel'
      then
        DOCKER_CMD='sudo docker'
      else
        echo >&2 "$SCRIPT_NAME: cannot set docker command: please either"
        echo >&2 "  * add the user '$USER' to the group 'docker' or 'sudo'"
        echo >&2 "  * or set the variable \$DOCKER_CMD"
        exit 77 # EX_NOPERM
      fi
      ;;
    *)
      echo >&2 "$SCRIPT_NAME: cannot detect platform to set docker command"
      echo >&2 "Try setting the variable \$DOCKER_CMD appropriately"
      exit 71 # EX_OSERR
      ;;
  esac
fi

DOCKER_COMPOSE_CMD=${DOCKER_COMPOSE_CMD:-${DOCKER_CMD} compose}

# vi: set et sts=2 sw=2 ts=2 :
