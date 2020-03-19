#!/usr/bin/env bash

set -e -o pipefail -u

DUMP_DIR=/media/searchdump
DATA_DIR=/opt/solr/server/solr/data
OVERWRITE_FLAG=0

SCRIPT_NAME=$(basename "$0")
HELP=$(cat <<EOH
Usage: $SCRIPT_NAME [<options>]

Load MusicBrainz Solr search indexes from fetched dump files.

Options:
  -f, --force   Delete any existing data before loading search indexes
  -h, --help    Print this help message

Note:
  The Docker Compose service 'search' must be stopped beforehand.
EOH
)

# Parse arguments

if [[ $# -gt 0 && $1 =~ ^-*h(elp)?$ ]]
then
	echo "$HELP"
	exit 0 # EX_OK
elif [[ $# -eq 1 && $1 =~ ^-*f(orce)?$ ]]
then
	OVERWRITE_FLAG=1
elif [[ $# -gt 0 ]]
then
	echo >&2 "$SCRIPT_NAME: unrecognized arguments"
	echo >&2 "Try '$SCRIPT_NAME help' for usage."
	exit 64 # EX_USAGE
fi

# Check existing Solr data and extract search indexes from dump files

cd "$DUMP_DIR"

for dump_file in *.tar.zst
do
	collection=${dump_file/.tar.zst}
	echo "$(date): Load $collection search index..."
	if [[ $(find "$DATA_DIR/$collection" -type f 2>/dev/null | wc -c) -ne 0 ]]
	then
		if [[ $OVERWRITE_FLAG -eq 1 ]]
		then
			find "$DATA_DIR/$collection" -type f -delete
		else
			echo >&2 "$SCRIPT_NAME: '$collection' has data already"
			echo >&2 "To delete it first, add the option '--force'."
			exit 73 # EX_CANTCREAT
		fi
	fi
	tar -x --zstd -f "$DUMP_DIR/$dump_file" -C "$DATA_DIR"
done

echo "$(date): Done loading search indexes."
# vi: set noexpandtab softtabstop=0:
