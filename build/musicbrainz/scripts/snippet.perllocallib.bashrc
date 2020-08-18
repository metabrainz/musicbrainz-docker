
# shellcheck shell=bash

# In interactive mode only
if [[ $- = *i* ]]; then
    # Enable locally installed Perl modules if not enabled already
    if [[ -z ${PERL_LOCAL_LIB_ROOT+set} ]]; then
        eval "$(perl -Mlocal::lib)"
    fi
    # Unset BASH_ENV which is for noninteractive scripts only
    if [[ -n ${BASH_ENV+set} ]]; then
        unset BASH_ENV
    fi
fi
