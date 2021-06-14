# Unmake
*Artifact indexer*

The `unmake` project exploitd the nature of GNU Make to create indexes of by their source files. The purpose of this is to allow fast forward propagation of changes from source files to any generated files.

The nature of a makefile allows one to specify relationships between source files and artifacts using patterns. Unmake provides a method to build this into an index relating source files to their artifact lists. Once any given file is is updated, one can then simply check to see if it has an entry in the index. If so, you immediately know what files are now state and must be updates.

In an extremely convenient turn of events, GNU Make provides a simple interface to pair build scripts with representations of the artifact-source relationship. GNU Make refers to these as TARGETS and PREREQUISITES. Their formatting is laid out like so:

TARGET: PREREQ2 PREREQ2 PREREQ3
	echo "build scripts here"

Cropping an image could be representing like so:

images/cropped/%.jpeg: images/source/%.jpeg
	convert $< -trim +repage $@

The above allows GNU Make to scan the `images/cropped/` and `images/source/` directories, and if there are and source jpegs newer than their cropped counterparts, they will be re-cropped. The entire makefile would look like:

```make
#!/usr/bin/env make
JPEG_SOURCES=$(shell find images/source -type f | grep -v '\/\.') # List the sources.
JPEG_TARGETS=${MESSAGE_SOURCES:images/source%=images/cropped%}    # List the targets.

all: ${JPEG_TARGETS} # Build them by default when running 'make' with no arguments.

images/cropped/%.jpeg: images/source/%.jpeg
	convert $< -trim +repage $@
```

## Where Unmake comes in:

Given the source file `images/source/lorem.jpg`, a file would be produced at `.unmake/index/images/source/lorem.jpg.unmak` that would contain:

```plaintext
images/cropped/lorem.jpg
```

Thus, if one ever edited `lorem.jpg`, they could simply rebuild all dependant files by running `make`. However, this would update any artifacts that are older than their source files. What if you only wanted to update the dependants of `lorem.jpg`? Just run something like:

```bash
make $(cat .unmake/index/images/source/lorem.jpg);
```

## Including unmake in your project

```bash

```


```make
#!/usr/bin/env make

include .unmake/unmake/Makefile

```

`cat .unmake/index/images/source/lorem.jpg` will list all the files in the index for `lorem.jpg`, and `$()` will list them out as arguments for `make`. If some are already up to date, make will see that they won't need to be rebuilt and move on.

This does not stop at a single level. GNU Make will detect cascading dependencies, meaning the index files will contain ALL artifacts that GNU Make detects as dependent on a given source file. Thankfully as explained above GNU Make will only rebuild artifacts older than their sources.

## unmake watcher

Once an Unmake index is built for a given makefile, running the following bash script in its directory would cause all of its files to be watched for changes, and any artifacts to be rebuilt as soon as their source files were closed:

```bash
#!/usr/bin/env bash
inotifywait -qmre CREATE,DELETE,CLOSE_WRITE --format '%e %w%f' . | while read LINE; do {

	echo "${LINE}";

	EVENT=$(echo ${LINE} | cut -d' ' -f1);
	FILE=$(echo ${LINE} | cut -d' ' -f2);

	INDEX=.unmake/index/${FILE#./}.unmak;

	echo "${INDEX}";

	[[ "${EVENT#,CLOSE}" -eq "CLOSE_WRITE" ]] || {
		echo "Rebuilding index on ${EVENT%,CLOSE}...";
		make unmake-index
	};

	[[ -f ${INDEX} ]] || continue;

	LIST=$(cat "${INDEX}");

	echo "Rebuilding ${LIST}...";
	[[ -f ${INDEX} ]] && make ${LIST};

}; done;
```

This can be found under the bash script `bin/unmake-watcher.sh`.

## unmake installer

This is not a fully fleged aspect of the utility and is provided only for convenience's sake as a simple wrapper around git submodules.

Write a file named `unmake-mods.list` with the following format pairing directories and repository urls, optionally tagged with @ followed by a commit or tag:

```plaintext
.unmake/modules/seanmorris/hello-world https://github.com/seanmorris/hello-world.git
.unmake/modules/seanmorris/project https://github.com/seanmorris/project.git@v0.0.1
```

Run `make unmake-install` to add the projects as git submodules at their given locations.