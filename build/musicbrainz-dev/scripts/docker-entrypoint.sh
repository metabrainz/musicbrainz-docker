#!/bin/bash

set -e -o pipefail

# liblocal-lib-perl < 2.000019 generates commands using unset variable
eval "$(perl -Mlocal::lib="${MUSICBRAINZ_PERL_LOCAL_LIB:?}")"

set -u

mkdir -p "${PERL_CPANM_HOME}" "${PERL_LOCAL_LIB_ROOT}"

export DEBIAN_FRONTEND=noninteractive

# shellcheck disable=SC2016
declare -p \
  | grep -P '^declare -x (?!(?:BASH_ENV|HOME|LESS_CLOSE|LESS_OPEN|LS_COLORS|OLDPWD|PWD|SHELL|SHLVL|TERM)=)' \
  | sed 's/^\(declare -x \)\([^=]*\)=\(.*\)$/\1\2=${\2-\3}/' \
  | sed 's/^\(declare -x PATH\)=\${PATH-\(.*\)}$/\1=\2/' \
  > /noninteractive.bash_env

# shellcheck disable=SC2016
echo '[[ -n ${BASH_ENV+set} ]] && unset BASH_ENV' \
  >> /noninteractive.bash_env

unset BASH_ENV

exec "$@"
