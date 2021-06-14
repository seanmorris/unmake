#!/usr/bin/env bash

MOD_LIST=./unmake-mods.list;

cat ${MOD_LIST} | while read LINE; do {

	grep -q ^\# <<< "${LINE}" && continue;

	DIR=$(echo "${LINE}" | cut -d' ' -f1);
	MOD=$(echo "${LINE}" | cut -d' ' -f2);
	BRANCH=$(echo "${LINE}" | cut -d' ' -f3);

	URL=$(echo "${MOD}" | cut -d@ -f1);
	TAG=$(echo "${MOD}" | cut -d@ -f2);
	
	VERSION="";

	[[ -z ${TAG} ]] || {
		VERSION=" ${TAG}";
	}

	echo -ne "\e[1mInstalling ${DIR}${VERSION}...";
	echo -ne "\e[0m\n\e[2m";

	GIT_ARGS="";

	[[ -z "${BRANCH}" ]] || GIT_ARGS="${GIT_ARGS} -b ${BRANCH}}";
	
	[[ -d "${DIR}" ]] || {
		GIT_ARGS="${GIT_ARGS} --force ${URL} ${DIR}";
		git submodule add ${GIT_ARGS};
	};

	[[ -z "${TAG}" ]] || {
		pushd "${DIR}";
		git checkout "${TAG}";
		popd;
	}
	echo -ne "\e[0m";

	echo -ne "\e[32mdone.\n";
	
	echo -ne "\e[0m\n";

}; done;
