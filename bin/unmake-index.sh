#!/usr/bin/env bash
set -euo pipefail

FILES=false;

shopt -s dotglob extglob;
rm -rf ./.unmake/unmake/index/!(.gitignore|..|.) || true;
shopt -u dotglob extglob;

find ./.unmake/modules/* -maxdepth 0 -type d \
| while read MODULE; do {
	bash "${MODULE}/list-sources.sh" \
	| while read PREREQ; do {

		mkdir -p $(dirname "./.unmake/unmake/index/${PREREQ}");

		bash "${MODULE}/list-artifacts.sh" <<< "${PREREQ}" \
		| while read TARGET; do {

			echo "${TARGET}" >> "./.unmake/unmake/index/${PREREQ}.unmak";

		} done;

	} done;

} done;

exit 0;
