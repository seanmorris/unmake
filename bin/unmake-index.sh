#!/usr/bin/env bash
set -euo pipefail

FILES=false;

shopt -s dotglob extglob;
rm -rf ./.unmake/unmake/index/!(.gitignore|..|.) || true;
shopt -u dotglob extglob;

find ./.unmake/modules/* -type d \
| while read MODULE; do {
	
	#echo -ne "${MODULE}\n" 1>&2;

	bash "${MODULE}/list-sources.sh" \
	| while read PREREQ; do {

		mkdir -p $(dirname "./.unmake/unmake/index/${PREREQ}");

		#echo -ne "\t${PREREQ}\n" 1>&2;

		bash "${MODULE}/list-artifacts.sh" <<< "${PREREQ}" \
		| while read TARGET; do {

			#echo -ne "\t\t${TARGET}\n" 1>&2;

			echo "${TARGET}" >> "./.unmake/unmake/index/${PREREQ}.unmak";

		} done;

	} done;

} done;

exit 0;
