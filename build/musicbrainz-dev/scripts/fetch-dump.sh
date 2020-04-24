#!/usr/bin/env bash

set -e -o pipefail -u

DB_DUMP_DIR=/media/dbdump
BASE_FTP_URL='ftp://ftp.eu.metabrainz.org/pub/musicbrainz'
TARGET=''
WGET_CMD=(wget)

SCRIPT_NAME=$(basename "$0")
HELP=$(cat <<EOH
Usage: $SCRIPT_NAME [<options>] <target>

Fetch dump files of the MusicBrainz database.

Targets:
  replica       Fetch latest database's replicated tables only.
  sample        Fetch latest database's sample only.

Options:
  --base-ftp-url <url>          Specify URL to MetaBrainz/MusicBrainz FTP directory.
                                (Default: '$BASE_FTP_URL')
  --wget-options <wget options> Specify additional options to be passed to wget,
                                these should be separated with whitespace,
                                the list should be a single argument
                                (escape whitespaces if needed).

  -h, --help                    Print this help message.
EOH
)

# Parse arguments

while [[ $# -gt 0 ]]
do
	case "$1" in
		replica | sample )
			if [[ -n $TARGET ]]
			then
				echo >&2 "$SCRIPT_NAME: only one target argument can be given"
				echo >&2 "Try '$SCRIPT_NAME --help' for usage."
				exit 64 # EX_USAGE
			fi
			TARGET=$1
			;;
		--base-ftp-url )
			shift
			BASE_FTP_URL="$1"
			;;
		--wget-options )
			shift
			IFS=' ' read -r -a WGET_OPTIONS <<< "$1"
			WGET_CMD+=("${WGET_OPTIONS[@]}")
			unset WGET_OPTIONS
			;;
		-h | --help )
			echo "$HELP"
			exit 0 # EX_OK
			;;
		-* )
			echo >&2 "$SCRIPT_NAME: unrecognized option '$1'"
			echo >&2 "Try '$SCRIPT_NAME --help' for usage."
			exit 64 # EX_USAGE
			;;
		* )
			echo >&2 "$SCRIPT_NAME: unrecognized argument '$1'"
			echo >&2 "Try '$SCRIPT_NAME --help' for usage."
			exit 64 # EX_USAGE
			;;
	esac
	shift
done

if [[ -z $TARGET ]]
then
	echo >&2 "$SCRIPT_NAME: no dump type has been specified"
	echo >&2 "Try '$SCRIPT_NAME --help' for usage."
	exit 64 # EX_USAGE
fi

# Prepare to fetch database dump

echo "$(date): Fetching database dump..."

rm -rf "${DB_DUMP_DIR:?}"/*

case "$TARGET" in
	replica )
		DB_DUMP_REMOTE_DIR=data/fullexport
		DB_DUMP_FILES=(
			mbdump.tar.bz2
			mbdump-cdstubs.tar.bz2
			mbdump-cover-art-archive.tar.bz2
			mbdump-derived.tar.bz2
			mbdump-stats.tar.bz2
			mbdump-wikidocs.tar.bz2
		)
		;;
	sample )
		DB_DUMP_REMOTE_DIR=data/sample
		DB_DUMP_FILES=(
			mbdump-sample.tar.xz
		)
		;;
esac

"${WGET_CMD[@]}" -nd -nH -P "$DB_DUMP_DIR" \
	"$BASE_FTP_URL/$DB_DUMP_REMOTE_DIR/LATEST"
DUMP_TIMESTAMP=$(cat /media/dbdump/LATEST)

# Actually fetch database dump

if [[ $TARGET == replica ]]
then
	for F in MD5SUMS "${DB_DUMP_FILES[@]}"
	do
		"${WGET_CMD[@]}" -P "$DB_DUMP_DIR" \
			"$BASE_FTP_URL/$DB_DUMP_REMOTE_DIR/$DUMP_TIMESTAMP/$F"
	done
	cd "$DB_DUMP_DIR"
	for F in "${DB_DUMP_FILES[@]}"
	do
		MD5SUM=$(md5sum -b "$F")
		grep -Fqx "$MD5SUM" MD5SUMS || {
			echo >&2 "$0: unmatched MD5 checksum: $MD5SUM *$F" &&
			exit 70 # EX_SOFTWARE
		}
	done
	cd -
elif [[ $TARGET == sample ]]
then
	for F in "${DB_DUMP_FILES[@]}"
	do
		"${WGET_CMD[@]}" -P "$DB_DUMP_DIR" \
			"$BASE_FTP_URL/$DB_DUMP_REMOTE_DIR/$DUMP_TIMESTAMP/$F"
	done
fi

echo "$(date): Done fetching dump files."
# vi: set noexpandtab softtabstop=0:
