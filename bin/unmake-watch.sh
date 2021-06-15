#!/usr/bin/env bash

set -eu;
set +x;

inotifywait -qmre CREATE,DELETE,CLOSE_WRITE --format '%e %w%f' . | while read LINE; do {

	echo "${LINE}" | grep -q ".unmake" && continue;

	EVENT=$(echo ${LINE} | cut -d' ' -f1);
	FILE=$(echo ${LINE} | cut -d' ' -f2);

	INDEX=.unmake/index/${FILE#./}.unmak;

	[[ "${EVENT}" != "CLOSE_WRITE,CLOSE" ]] && {
		echo "Rebuilding index on ${EVENT} ${FILE}.";
		make unmake-index > /dev/null || true;
	};

	[[ -f ${INDEX} ]] || continue;

	LIST=$(cat "${INDEX}");

	echo "Rebuilding ${LIST} on ${EVENT} ${FILE}.";
	[[ -f ${INDEX} ]] && make ${LIST} > /dev/null 2> /dev/null || true;

}; done;
