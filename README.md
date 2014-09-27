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
