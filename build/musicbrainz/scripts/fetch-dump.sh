#!/usr/bin/env bash

set -e -o pipefail -u

DB_DUMP_DIR=/media/dbdump
SEARCH_DUMP_DIR=/media/searchdump
BASE_FTP_URL=''
BASE_DOWNLOAD_URL="$MUSICBRAINZ_BASE_DOWNLOAD_URL"
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
  --base-download-url <url>     Specify URL of a MetaBrainz/MusicBrainz download server.
                                (Default: '$BASE_DOWNLOAD_URL')
  --base-ftp-url <url>          Specify URL of a MetaBrainz/MusicBrainz FTP server.
                                (Note: this option is deprecated and will be removed in a future release)
  --wget-options <wget options> Specify additional options to be passed to wget,
                                these should be separated with whitespace,
                                the list should be a single argument
                                (escape whitespaces if needed).

  -h, --help                    Print this help message and exit.
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
		--base-download-url )
			shift
			BASE_DOWNLOAD_URL="${1%/data/fullexport/}"
			if ! [[ $BASE_DOWNLOAD_URL =~ ^(ftp|https?):// ]]
			then
				echo >&2 "$SCRIPT_NAME: --base-download-url must begin with ftp://, http:// or https://"
				exit 64 # EX_USAGE
			fi
			;;
		--base-ftp-url )
			shift
			echo >&2 "Warning: --base-ftp-url is deprecated and will be removed in a future release"
			BASE_FTP_URL="$1"
			if ! [[ $BASE_FTP_URL =~ ^ftp:// ]]
			then
				BASE_FTP_URL="ftp://$BASE_FTP_URL"
			fi
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

# Keep support for (deprecated) FTP option (which still takes precedence)

BASE_DOWNLOAD_URL="${BASE_FTP_URL:-$BASE_DOWNLOAD_URL}"

# Fetch latest search indexes

if [[ $TARGET =~ ^(both|search)$ ]]
then
	echo "$(date): Fetching search indexes dump..."
	PREVIOUS_DUMP_TIMESTAMP=$(
		if [[ -a "$SEARCH_DUMP_DIR/LATEST" ]]
		then
			cat "$SEARCH_DUMP_DIR/LATEST"
		fi
	)
	rm -f "$SEARCH_DUMP_DIR/LATEST"
	"${WGET_CMD[@]}" -nd -nH -P "$SEARCH_DUMP_DIR" \
		"${BASE_DOWNLOAD_URL}/data/search-indexes/LATEST"
	DUMP_TIMESTAMP=$(cat "$SEARCH_DUMP_DIR/LATEST")
	if [[ $PREVIOUS_DUMP_TIMESTAMP != "$DUMP_TIMESTAMP" ]]
	then
		find "$SEARCH_DUMP_DIR" \
			! -path "$SEARCH_DUMP_DIR" \
			! -path "$SEARCH_DUMP_DIR/LATEST" \
			-delete
	fi
	"${WGET_CMD[@]}" -nd -nH -c -r -P "$SEARCH_DUMP_DIR" \
		--accept 'MD5SUMS,*.tar.zst' --no-parent --relative \
		"${BASE_DOWNLOAD_URL}/data/search-indexes/$DUMP_TIMESTAMP/"
	echo "$(date): Checking MD5 sums..."
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

	PREVIOUS_DUMP_TIMESTAMP=$(
		if [[ -a "$DB_DUMP_DIR/LATEST" ]]
		then
			cat "$DB_DUMP_DIR/LATEST"
		fi
	)
	rm -f "$DB_DUMP_DIR/LATEST"
	if [[ -a "$DB_DUMP_DIR/LATEST-WITH-SEARCH-INDEXES" ]]
	then
		PREVIOUS_DUMP_TIMESTAMP=$(cat "$DB_DUMP_DIR/LATEST-WITH-SEARCH-INDEXES")
		rm -f "$DB_DUMP_DIR/LATEST-WITH-SEARCH-INDEXES"
	fi
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
	rm -f "$DB_DUMP_DIR/index.html"
	"${WGET_CMD[@]}" --force-html -O "$DB_DUMP_DIR/index.html" -P "$DB_DUMP_DIR" \
		"${BASE_DOWNLOAD_URL}/$DB_DUMP_REMOTE_DIR/"
	cat "$DB_DUMP_DIR/index.html"
	DUMP_TIMESTAMP=$(
		sed -n "s#.*href=\"[^\"]*\\($SEARCH_DUMP_DAY-[0-9]*\\).*#\\1#p" \
			"$DB_DUMP_DIR/index.html" | head -1
	)
	rm -f "$DB_DUMP_DIR/index.html"
	echo "$DUMP_TIMESTAMP" >> "$DB_DUMP_DIR/LATEST-WITH-SEARCH-INDEXES"
elif [[ $TARGET != search ]]
then
	# Just find latest database dump

	"${WGET_CMD[@]}" -nd -nH -P "$DB_DUMP_DIR" \
		"${BASE_DOWNLOAD_URL}/$DB_DUMP_REMOTE_DIR/LATEST"
	DUMP_TIMESTAMP=$(cat "$DB_DUMP_DIR/LATEST")
fi

# Remove previously downloaded files if obsolete

if [[ $TARGET != search ]]
then
	if [[ $PREVIOUS_DUMP_TIMESTAMP != "$DUMP_TIMESTAMP" ]]
	then
		find "$DB_DUMP_DIR" \
			! -path "$DB_DUMP_DIR" \
			! -path "$DB_DUMP_DIR/LATEST" \
			! -path "$DB_DUMP_DIR/LATEST-WITH-SEARCH-INDEXES" \
			-delete
	fi
fi

# Actually fetch database dump

if [[ $TARGET =~ ^(both|replica)$ ]]
then
	for F in MD5SUMS "${DB_DUMP_FILES[@]}"
	do
		"${WGET_CMD[@]}" -c -P "$DB_DUMP_DIR" \
			"${BASE_DOWNLOAD_URL}/$DB_DUMP_REMOTE_DIR/$DUMP_TIMESTAMP/$F"
	done
	echo "$(date): Checking MD5 sums..."
	cd "$DB_DUMP_DIR"
	for F in "${DB_DUMP_FILES[@]}"
	do
		echo -n "$F: "
		MD5SUM=$(md5sum -b "$F")
		if grep -Fqx "$MD5SUM" MD5SUMS
		then
			echo OK
		else
			echo FAILED
			echo >&2 "$0: unmatched MD5 checksum: $MD5SUM *$F"
			exit 70 # EX_SOFTWARE
		fi
	done
	cd -
elif [[ $TARGET == sample ]]
then
	for F in "${DB_DUMP_FILES[@]}"
	do
		"${WGET_CMD[@]}" -c -P "$DB_DUMP_DIR" \
			"${BASE_DOWNLOAD_URL}/$DB_DUMP_REMOTE_DIR/$DUMP_TIMESTAMP/$F"
	done
fi

echo "$(date): Done fetching dump files."
# vi: set noexpandtab softtabstop=0:
