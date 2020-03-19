#!/usr/bin/env bash

set -e -o pipefail -u

DB_DUMP_DIR=/media/dbdump
SEARCH_DUMP_DIR=/media/searchdump
BASE_FTP_URL='ftp://ftp.eu.metabrainz.org/pub/musicbrainz'
TARGET=''
WGET_CMD=(wget)

SCRIPT_NAME=$(basename "$0")
HELP=$(cat <<EOH
Usage: $SCRIPT_NAME [<options>] <target>

Fetch dump files of the MusicBrainz database and/or search indexes.

Targets:
  both          Fetch latest search dump with replica dump of the same day.
  replica       Fetch latest database's replicated tables only.
  sample        Fetch latest database's sample only.
  search        Fetch latest search indexes only.

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
		both | replica | sample | search )
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

# Fetch latest search indexes

if [[ $TARGET =~ ^(both|search)$ ]]
then
	echo "$(date): Fetching search indexes dump..."
	cd "$SEARCH_DUMP_DIR" && find . -delete && cd -
	"${WGET_CMD[@]}" -nd -nH -P "$SEARCH_DUMP_DIR" \
		"$BASE_FTP_URL/data/search-indexes/LATEST"
	DUMP_TIMESTAMP=$(cat /media/searchdump/LATEST)
	"${WGET_CMD[@]}" -nd -nH -r -P "$SEARCH_DUMP_DIR" \
		"$BASE_FTP_URL/data/search-indexes/$DUMP_TIMESTAMP/"
	cd "$SEARCH_DUMP_DIR" && md5sum -c MD5SUMS && cd -
	if [[ $TARGET == search ]]
	then
		echo 'Done fetching search indexes dump'
		exit 0 # EX_OK
	fi
fi

# Prepare to fetch database dump

if [[ $TARGET != search ]]
then
	echo "$(date): Fetching database dump..."

	rm -rf "${DB_DUMP_DIR:?}"/*
fi

case "$TARGET" in
	both | replica )
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

if [[ $TARGET == both ]]
then
	# Find latest database dump corresponding to search indexes

	SEARCH_DUMP_DAY="${DUMP_TIMESTAMP/-*}"
	"${WGET_CMD[@]}" --spider --no-remove-listing -P "$DB_DUMP_DIR" \
		"$BASE_FTP_URL/$DB_DUMP_REMOTE_DIR"
	DUMP_TIMESTAMP=$(
		grep -E "\\s${SEARCH_DUMP_DAY}-\\d*" "$DB_DUMP_DIR/.listing" \
			| sed -e 's/\s*$//' -e 's/.*\s//'
	)
	rm -f "$DB_DUMP_DIR/.listing"
	echo "$DUMP_TIMESTAMP" >> "$DB_DUMP_DIR/LATEST-WITH-SEARCH-INDEXES"
elif [[ $TARGET != search ]]
then
	# Just find latest database dump

	"${WGET_CMD[@]}" -nd -nH -P "$DB_DUMP_DIR" \
		"$BASE_FTP_URL/$DB_DUMP_REMOTE_DIR/LATEST"
	DUMP_TIMESTAMP=$(cat /media/dbdump/LATEST)
fi

# Actually fetch database dump

if [[ $TARGET =~ ^(both|replica)$ ]]
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
