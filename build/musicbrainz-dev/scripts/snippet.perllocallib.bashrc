
# Enable locally installed Perl modules for interactive shell
if [[ $- = *i* ]]; then
    eval "$(perl -Mlocal::lib="${MUSICBRAINZ_PERL_LOCAL_LIB}")"
fi
