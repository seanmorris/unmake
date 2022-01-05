#!/usr/bin/env make

.PHONY: unmake-index unmake-install unmake-watch

UNMAKE_TARGETS=

define IMPORT_MODULE
$(eval UNMAKE_TARGETS+=$(shell .unmake/modules/${1}/list-sources.sh | .unmake/modules/${1}/list-artifacts.sh | sed 's/ /\\\ /g'))
$(eval include .unmake/modules/${1}/${1}.make)
endef

unmake-index:
	@ bash .unmake/unmake/bin/unmake-index.sh

unmake-install:
	@ bash .unmake/unmake/bin/unmake-install.sh

unmake-watch:
	@ bash .unmake/unmake/bin/unmake-watch.sh
