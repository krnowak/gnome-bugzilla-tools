#!/usr/bin/perl
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

package main;

use strict;
use warnings;
use IO::File;
use DBI;
use Getopt::Long qw(GetOptionsFromArray :config no_ignore_case);
#use Term::ReadKey;
use List::MoreUtils qw(any first_index);
use Data::Dumper;
#use Array::Utils qw(intersect array_minus);

sub intersect(\@\@) {
  my %e = map { $_ => undef } @{$_[0]};
  return grep { exists( $e{$_} ) } @{$_[1]};
}

sub array_minus(\@\@) {
  my %e = map{ $_ => undef } @{$_[1]};
  return grep( ! exists( $e{$_} ), @{$_[0]} );
}

sub print_optional
{
  my ($desc, $value) = @_;

  if (defined($value))
  {
    print($desc, ": ", $value, "\n");
  }
  else
  {
    print("No ", $desc, "\n");
  }
}
#
#sub read_password
#{
#  print("Type your password:");
#  ReadMode('noecho');
#  chomp(my $password = <STDIN>);
#  ReadMode('restore');
#  print("\n");
#
#  $password;
#}
#
sub get_real_tables
{
  my ($dbh) = @_;
  my $cols = $dbh->selectcol_arrayref("SHOW TABLES");

  return @{$cols};
}

sub get_real_schema_for_table
{
  my ($dbh, $table) = @_;
  my $rows = $dbh->selectall_arrayref("SHOW COLUMNS FROM $table");
  my $field = 0;
  my $type = 1;
  my $null = 2;
  my $key = 3;
  my $default = 4;
  my $extra = 5;
  my $type_mapping =
  {
    'tinyint(4)' => 'INT1', # can be BOOLEAN too
    'smallint(6)' => 'INT2',
    'mediumint(9)' => 'INT3',
    'int(11)' => 'INT4',

    'tinytext' => 'TINYTEXT',
    'mediumtext' => 'MEDIUMTEXT', # can be LONGTEXT

    'longblob' => 'LONGBLOB',

    'datetime' => 'DATETIME',

    'double' => 'real'
  };
  my $serial_mapping =
  {
    'INT2' => 'SMALLSERIAL',
    'INT3' => 'MEDIUMSERIAL',
    'INT4' => 'INTSERIAL'
  };
  my $table_schema = {'FIELDS' => [], 'INDEXES' => []};
  my $fields = $table_schema->{'FIELDS'};

  foreach my $row (@{$rows})
  {
    my $col_name = $row->[$field];
    my $col_type = $row->[$type];
    my $col_extra = $row->[$extra];

    if (exists($type_mapping->{$col_type}))
    {
      $col_type = $type_mapping->{$col_type};
    }
    if ($col_extra eq 'auto_increment')
    {
      die unless exists($serial_mapping->{$col_type});

      $col_type = $serial_mapping->{$col_type};
    }

    push(@{$fields}, $col_name, {'TYPE' => $col_type});
  }

  return $table_schema;
}

sub compare_schemas
{
  my ($real, $bz) = @_;
  my %real_fields = @{$real->{'FIELDS'}};
  my @real_keys = keys(%real_fields);
  my %bz_fields = @{$bz->{'FIELDS'}};
  my @bz_keys = keys(%bz_fields);
  my @common_fields = intersect(@real_keys, @bz_keys);
  my @only_in_real = array_minus(@real_keys, @bz_keys);
  my @only_in_bz = array_minus(@bz_keys, @real_keys);

  if (@only_in_bz > 0)
  {
    print("COLUMNS ONLY IN BZ SCHEMA: ", join(', ', @only_in_bz), "\n");
  }

  if (@only_in_real > 0)
  {
    print("COLUMNS ONLY IN REAL SCHEMA: ", join(', ', @only_in_real), "\n");
  }
  foreach my $key (@common_fields)
  {
    my $real_desc = $real_fields{$key};
    my $bz_desc = $bz_fields{$key};
    my $real_type = $real_desc->{'TYPE'};
    my $bz_type = $bz_desc->{'TYPE'};

    if ($real_type ne $bz_type)
    {
      unless (($real_type eq 'INT1' and $bz_type eq 'BOOLEAN') or
              ($real_type eq 'MEDIUMTEXT' and $bz_type eq 'LONGTEXT'))
      {
        print("REAL TYPE (", $real_type, ") IS DIFFERENT FROM BZ TYPE (", $bz_type, ")\n");
      }
    }
  }
}

sub main
{
  my @args = @_;
  my $user = undef;
  my $password = undef;
  my $host = undef;
  my $port = undef;
  my $driver = "mysql";
  my $name = undef;
  my $ret = GetOptionsFromArray(\@args,
                                "user|u=s" => \$user,
                                "password|p:s" => \$password,
                                "host|h=s" => \$host,
                                "port|P=i" => \$port,
                                "driver|d=s" => \$driver,
                                "name|n=s" => \$name);

  die("Error in command line arguments") unless $ret;
  die("No user given") unless defined($user);
  die("No database name given") unless defined($name);

  my @drivers = DBI->available_drivers();

  unless (any {$_ eq $driver} @drivers)
  {
    print("Available drivers: ", join(", ", @drivers), "\n");
    die "'", $driver, "' is not one of available drivers";
  }

  if ($driver ne 'mysql')
  {
    die "'", $driver, "' driver is unsupported for now, only 'mysql' driver is supported";
  }

  if (defined($password) and $password eq '')
  {
#    $password = read_password();
    die;
  }

  print("User: ", $user, "\n");
  print_optional("Password", $password);
  print_optional("Host", $host);
  print_optional("Port", $port);
  print("Driver: ", $driver, "\n");

  my @data_sources = DBI->data_sources($driver, {'host' => $host, 'port' => $port, 'database' => $name, 'user' => $user, 'password' => $password});

  die "No data sources" unless @data_sources;

  print("Data sources:\n", join("\n", @data_sources), "\n");

  my $dsn_index = first_index { $_ =~ /\b$name\b/ } @data_sources;

  die "No suitable data source" if $dsn_index < 0;

  my $dsn = $data_sources[$dsn_index];

  print "Using DSN: ", $dsn, "\n";

  my $dbh = DBI->connect($dsn, $user, $password);

  my $rows = $dbh->selectall_arrayref("SELECT schema_data FROM bz_schema");

  die unless @{$rows} > 0 and @{$rows->[0]} > 0;

  my $perl_code = 'my $VAR1; ' . $rows->[0][0];
  my $schema = eval ($perl_code);
  my @bz_tables = keys(%{$schema});
  my @real_tables = get_real_tables($dbh);
  my @common_tables = intersect(@bz_tables, @real_tables);
  my @tables_only_in_bz = array_minus(@bz_tables, @real_tables);
  my @tables_only_in_real = array_minus(@real_tables, @bz_tables);

  if (@tables_only_in_bz > 0)
  {
    print("TABLES ONLY IN BZ: ", join(', ', @tables_only_in_bz), "\n");
  }

  if (@tables_only_in_real > 0)
  {
    print("TABLES ONLY IN REAL: ", join(', ', @tables_only_in_real), "\n");
  }

  foreach my $table(sort @common_tables)
  {
    print "TABLE ", $table, "\n";

    my $real_schema = get_real_schema_for_table($dbh, $table);
    my $bz_schema = $schema->{$table};

    compare_schemas($real_schema, $bz_schema);
  }

  $dbh->disconnect();
}

main(@ARGV);
