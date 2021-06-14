#!/usr/bin/env bash
# set -a; . lib/init.sh; set +a;

FILES=false;

shopt -s dotglob extglob;
rm -rf ./.unmake/index/!(.gitignore|..|.) || true;
shopt -u dotglob extglob;

make -npq | grep -v '^\s' | while read LINE || [[ $LINE ]]; do {

	[[ "# Files" == "${LINE}" ]] && {
		FILES=true;
		continue;
	}

	$FILES && {
		[[ -z ${LINE} ]] && continue;

		grep -q ^\# <<< "${LINE}" && continue;
		grep -q : <<< "${LINE}"   || continue;

		TARGET=$(echo ${LINE} | cut -d ':' -f1)
		PREREQS=$(echo ${LINE} | cut -d ':' -f2)

		
		grep -q \? <<< "${TARGET}"  && continue;
		grep -q \? <<< "${PREREQS}" && continue;

		[[ -z ${PREREQS} ]] && continue;

		[[ 'all' == ${TARGET} ]] && continue;
		[[ 'clean' == ${TARGET} ]] && continue;
		[[ '.PHONY' == ${TARGET} ]] && continue;
		[[ '.DEFAULT' == ${TARGET} ]] && continue;
		[[ '.SUFFIXES' == ${TARGET} ]] && continue;

		for PREREQ in ${PREREQS}; do {
			mkdir -p $(dirname ".unmake/index/${PREREQ}");
			echo "${TARGET}" >> ".unmake/index/${PREREQ}.unmak";
		} done;

		echo -ne "\n";
	} || true;

} done | sort | grep -v ^$ || true

true;
