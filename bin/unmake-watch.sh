#!/usr/bin/env bash
inotifywait -qmre CREATE,DELETE,CLOSE_WRITE --format '%e %w%f' . | while read LINE; do {

	echo "${LINE}";

	EVENT=$(echo ${LINE} | cut -d' ' -f1);
	FILE=$(echo ${LINE} | cut -d' ' -f2);

	INDEX=.unmake/index/${FILE#./}.unmak;

	echo "${INDEX}";

	[ "${EVENT#,CLOSE}" = "CLOSE_WRITE" ] && {
		echo "Rebuilding index on ${EVENT%,CLOSE}...";
		make unmake-index
	};

	[[ -f ${INDEX} ]] || continue;

	LIST=$(cat "${INDEX}");

	echo "Rebuilding ${LIST}...";
	[[ -f ${INDEX} ]] && make ${LIST};

}; done;