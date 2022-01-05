#!/usr/bin/env bash
set -euxo pipefail
# set -a; . lib/init.sh; set +a;

FILES=false;

shopt -s dotglob extglob;
rm -rf ./.unmake/unmake/index/!(.gitignore|..|.) || true;
shopt -u dotglob extglob;

find ./.unmake/modules/* -type d \
| while read MODULE; do {

	bash "${MODULE}/list-sources.sh" \
	| while read PREREQ; do {

		mkdir -p $(dirname "./.unmake/unmake/index/${PREREQ}");

		# echo "${PREREQ}" 1>&2;

		bash "${MODULE}/list-artifacts.sh" <<< "${PREREQ}" \
		| while read TARGET; do {

			# echo -ne "\t${TARGET}\n" 1>&2;

			echo "${TARGET}" >> "./.unmake/unmake/index/${PREREQ}.unmak";

		} done;

	} done;

} done;

exit 0;
