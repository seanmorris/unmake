#!/usr/bin/env make

unmake-index:
	@ bash .unmake/unmake/bin/unmake-index.sh
# 	@ bash bin/unmake-index.sh

unmake-install:
	@ bash .unmake/unmake/bin/unmake-install.sh
# 	@ bash bin/unmake-install.sh

unmake-watch:
	@ bash .unmake/unmake/bin/unmake-watch.sh
# 	@ bash bin/unmake-watch.sh
