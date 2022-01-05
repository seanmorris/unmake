#!/usr/bin/env bash
set -euo pipefail;

make unmake-index 1>&2;

inotifywait -qmre CREATE,DELETE,CLOSE_WRITE --format '%e %w%f' . | while read LINE; do {

	echo "${LINE}" | grep -q ".unmake" && continue;

	EVENT=$(echo ${LINE} | cut -d' ' -f1);
	FILE=$(echo ${LINE} | cut -d' ' -f2);

	INDEX=.unmake/unmake/index/${FILE#./}.unmak;

	[[ "${INDEX}" -nt "${FILE}" ]] && continue;

	[[ -f ${INDEX} ]] || make unmake-index;
	[[ -f ${INDEX} ]] || continue;

	LIST=$(cat "${INDEX}" | sed -e "s|^|\t|g");

	[[ -z LIST ]] && continue;

	echo -ne "Rebuilding ${FILE} on ${EVENT}\n${LIST}.\n" 1>&2;
	[[ -f ${INDEX} ]] && make ${LIST} || true;
	# [[ -f ${INDEX} ]] && make -s --dry-run ${LIST} || true;

}; done;
