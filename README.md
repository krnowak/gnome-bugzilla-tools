GNOME Bugzilla tools
====================

There are some perl scripts I hacked when working on gnome-bugzilla. I
generally made no effort in having nice output or in being useful to
anyone but me.

in schemadumpdiff:
------------------

`schemadumpdiff.pl` reads two SQL dump files which contain dumps of
`bz_schema` table and outputs differences between them. It either
compares table by table or selectively can compare a table in one dump
with different table in other dump.

Usage:
- `schemadumpdiff.pl BZ_SCHEMA_SQL_DUMP_FILE_1 BZ_SCHEMA_SQL_DUMP_FILE_2`
- `schemadumpdiff.pl BZ_SCHEMA_SQL_DUMP_FILE_1:TABLE_1 BZ_SCHEMA_SQL_DUMP_FILE_2:TABLE_2`

in patch-splitter:
------------------

`split.pl` reads a given file being a git patch with some additional
annotations, slices it into several other patches (writes them to
files) and writes a file being a list of generated patches and commit
messages. Annotations are simply comments with some structure.

Usage:
- `split.pl ANNOTATED_GIT_PATCH`

`process_patches_list.sh` reads a file list generated by split.pl and
applies them to git repo.

Usage:
- `process_patches_list.sh <patches.list`

in assemble-bugzilla:
---------------------

`assemble-bugzilla.sh` clones or updates bgo-upstream and
bgo-customizations repos, checkouts to given branches and copies them
over to /var/www/html/bugzilla. Highly specific for my own setup.

in schema-integrity-checker:
----------------------------

`schema-integrity-checker.pl` is an unfinished tool for checking if
database schema is really correctly described by `bz_schema`. It is
currently working partially for mysql.
