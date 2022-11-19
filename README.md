# Unmake
*Automatic Artifact indexer*

The `unmake` project exploits the nature of GNU Make to create indexes of artifacts by their source files. Unmake uses inotify under the hood to watch source changes and automatically generate artifacts as soon as sources change.

## Including unmake in your project

Add the project as a git submodule under `.unmake/unmake/`.

```bash
git submodule add https://github.com/seanmorris/unmake.git .unmake/unmake/
```

Add `include .unmake/unmake/Makefile` to your makefile:


```make
#!/usr/bin/env make

include .unmake/unmake/Makefile

```

## Modules

### Including modules

Add the following line to your make file to import the module under `.unmake/modules/foobar`. Note the lack of a space after the comma.

```
$(call IMPORT_MODULE,foobar)
```

### Writing Modules

You'll want to organize your code into modules for use with Unmake. You can create a module by creating a folder under `.unmake/modules/` in the root of the project. A `.make` file should be created with the same name, along with a `list-sources.sh`, and a  `list-artifacts.sh` file.

```plaintext
+ your_project
 + .unmake
  + modules
   + foobar
   | foobar.make
   | list-sources.sh
   | list-artifacts.sh
```

Once you've got this structure, you can start writing the code.

* `foobar.make` should define the relationships between sources and their artifacts. It is recommended to write targets and prerequisites with `%` based stems.
* `list-sources.sh` should search the filesystem for your source files.
* `list-artifacts.sh` should take **ONE** source file on STDIN, and print the filename for each artifact it should produce.

#### Example Module: SHA File Hasher

##### Makefile (project root)

This is a sample makefile the includes the example `digest` module:


```makefile
#!/usr/bin/env make
SHELL=/usr/bin/env bash -euo pipefail
MAKEFLAGS += --no-builtin-rules --warn-undefined-variables --no-print-directory

all: targets

include .unmake/unmake/Makefile

$(call IMPORT_MODULE,digest)

targets: unmake-index ${UNMAKE_TARGETS}
```

##### unmake/modules/digest/digest.mak

The module's makefile contains a rule to build a file names `outbox/%.digest.json` for every file names `inbox/%` where `%` is the original filename, cut after `inbox/`.

**Note:**

This example also specifies one source file: `.salt` as a prerequisite for all artifact files built from this rule. If your artifacts only depend on a single file each, you can ignore the `.salt` parts.

```makefile
#!/usr/bin/env make

outbox/%.digest.json: inbox/% .salt
	jq -n \
		--arg algo "SHA" \
		--arg file "$<" \
		--arg salt "$$(cat .salt)" \
		--arg hash "$$(sha256sum <( cat .salt "$<" ) | cut -d' ' -f1)" \
		'{"file":$$file, "hash": $$hash, "salt": $$salt, "algo": $$algo}' > "$@"
```

##### unmake/modules/digest/list-sources.sh

This script simply lists every file under `inbox/`, then the `.salt` file (which would be found in the project root).

```bash
#!/usr/bin/env bash
set -euo pipefail;

find ./inbox/ -type f | grep -v '\/\.'

echo ".salt"
```

##### unmake/modules/digest/list-artifacts.sh

There's a bit of recursion here but there's nothing to worry about! It won't even apply unless you're using an additional file as a prerequisite (like the `.salt` file in this example).

The script below will produce an artifact name (ending in `.digest.json`) given the name of an artifact on `STDIN`.

If it receives the `.salt` file, it will then call the `list-sources.sh` file from above, and return all artifacts, since we use the salt when producing all of our artifacts.

```bash
#!/usr/bin/env bash
set -euo pipefail;

while read -r FILENAME; do

	## If we're listing the salt's artifacts, list everything (except the salt)
	[[ ${FILENAME} == ".salt" ]] && {
		.unmake/modules/digest/list-sources.sh \
		| grep -v .salt \ # skip .salt
		| .unmake/modules/digest/list-artifacts.sh;
		continue;
	}

	# Produce the artifact name, given a source filename:

	BASENAME=`basename "${FILENAME}"`;

	echo  "./outbox/${BASENAME}.digest.json";

done

```

## Parts

### unmake-watch

Once an Unmake index is built for a given makefile, running the following bash script in its directory would cause all of its files to be watched for changes, and any artifacts to be rebuilt as soon as their source files were closed:

### unmake-index

Unmake will automatically build its indexes during `unmake-watch`, but you can run the following to rebuild the index manually.

```bash
make unmake-index
```

### unmake-install

Unmake modules can be installed as git submodules from any repository.

Write a file named `unmake-mods.list` with the following format pairing directories and repository urls, optionally tagged with @ followed by a commit or tag:

```plaintext
./.unmake/modules/seanmorris/hello-world https://github.com/seanmorris/hello-world.git
./.unmake/modules/seanmorris/project https://github.com/seanmorris/project.git@v0.0.1
```

Run `make unmake-install` to add the projects as git submodules at their given locations.


## How it works

The nature of a makefile allows one to specify relationships between source files and artifacts using patterns. Unmake provides a method to build this into an index relating source files to their artifact lists. Once any given file is is updated, one can then simply check to see if it has an entry in the index. If so, you immediately know what files are now state and must be updates.

In an extremely convenient turn of events, GNU Make provides a simple interface to pair build scripts with representations of the artifact-source relationship. GNU Make refers to these files as TARGETS and PREREQUISITES respectively. Their formatting is laid out like so:

```make
TARGET: PREREQ2 PREREQ2 PREREQ3
	echo "build scripts here"
```

Cropping an image could be represented like so:

```make
images/cropped/%.jpeg: images/source/%.jpeg
	convert $< -trim +repage $@
```

Once paired with Unmake, the above allows GNU Make to scan the `images/cropped/` and `images/source/` directories, and if there are and source jpegs newer than their cropped counterparts, they will be re-cropped. The entire makefile would look like:

```make
#!/usr/bin/env make
JPEG_SOURCES=$(shell find images/source -type f | grep -v '\/\.') # List the sources.
JPEG_TARGETS=${MESSAGE_SOURCES:images/source%=images/cropped%}    # List the targets.

all: ${JPEG_TARGETS} # Build them by default when running 'make' with no arguments.

images/cropped/%.jpeg: images/source/%.jpeg
	convert $< -trim +repage $@
```

### Where Unmake comes in:

Given the source file `images/source/lorem.jpg`, a file would be produced at `.unmake/index/images/source/lorem.jpg.unmak` that would contain:

```plaintext
images/cropped/lorem.jpg
```

Thus, if one ever edited `lorem.jpg`, they could simply rebuild all dependant files by running `make`. However, this would update any artifacts that are older than their source files. What if you only wanted to update the dependants of `lorem.jpg`? Just run something like:

```bash
make $(cat .unmake/index/images/source/lorem.jpg);
```

`cat .unmake/index/images/source/lorem.jpg` will list all the files in the index for `lorem.jpg`, and wrapping them with `$()` will list them out as arguments for the `make` command above. If some are already up to date, make will see that they won't need to be rebuilt and move on.

This does not stop at a single level. GNU Make will detect cascading dependencies, meaning the index files will contain ALL artifacts that GNU Make detects as dependent on a given source file. Thankfully as explained above GNU Make will only rebuild artifacts older than their sources.
