#!/usr/bin/perl
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

use strict;
use warnings;
use IO::File;
use v5.16;
use File::Basename;
use List::MoreUtils;
use Data::Dumper;

sub get_schema_perl_dump
{
  my ($filename) = @_;
  my $fd = IO::File->new ($filename, 'r');

  while (defined (my $line = $fd->getline ()))
  {
    if ($line =~ /^INSERT INTO `bz_schema` VALUES \('(.*)','?3.00'?\);$/)
    {
      my $perl_code = $1;

      $perl_code =~ s/\\'/'/g;
      $perl_code =~ s/\\n/\n/g;
      $perl_code =~ s/\\\\/\\/g;

      my $dump_fd = IO::File->new ($filename . '.pl', 'w');

      $dump_fd->print ($perl_code);
      $dump_fd->close ();

      my $VAR1;

      return eval ($perl_code);
    }
  }

  return undef;
}

sub usage
{
  say "schemadumpdiff schemadump1.sql[:table_name1] schemadump2.sql[:table_name2]";
  exit (1);
}

sub no_table_for
{
  my ($table, $data) = @_;

  say ('Table \'' . $table . '\' does not exist in ' . $data->{'basename'});
}

sub dump_table_for
{
  my ($table, $data) = @_;

  say ('Table \'' . $table . '\' is only in ' . $data->{'basename'});
  say (Dumper ($data->{'dump'}{$table}));
}

sub simple_diffs
{
  my ($h_1, $h_2, $keys, $key_types, $diffs) = @_;

  foreach my $key (@{$keys})
  {
    my $v_1 = delete ($h_1->{$key});
    my $v_2 = delete ($h_2->{$key});

    if (defined ($v_1) and defined ($v_2))
    {
      my $type = $key_types->{$key};
      my $diff = 0;

      if ($type eq 'n')
      {
        if ($v_1 != $v_2)
        {
          $diff = 1;
        }
      }
      elsif ($type eq 's')
      {
        if ($v_1 ne $v_2)
        {
          $diff = 1;
        }
      }
      if ($diff)
      {
        $diffs->{'both'}{$key} = [$v_1, $v_2];
      }
    }
    elsif (defined ($v_1))
    {
      $diffs->{'1'}{$key} = $v_1;
    }
    elsif (defined ($v_2))
    {
      $diffs->{'2'}{$key} = $v_2;
    }
    else
    {
      # nothing to do
    }
  }
}

my @known_references_keys = ('COLUMN','TABLE', 'DELETE', 'UPDATE', 'created');
my %known_references_key_types = ('COLUMN' => 's',
                                  'TABLE' => 's',
                                  'DELETE' => 's',
                                  'UPDATE' => 's',
                                  'created' => 'n');

sub diffs_empty
{
  my ($diffs) = @_;

  foreach my $key ('1', '2', 'both')
  {
    if (keys (%{$diffs->{$key}}) > 0)
    {
      return 0;
    }
  }

  return 1;
}

sub diffs_init
{
  {'1' => {}, '2' => {}, 'both' => {}};
}

sub diffs_cleanup
{
  my ($diffs) = @_;

  if (diffs_empty ($diffs))
  {
    $diffs = undef;
  }
  else
  {
    foreach my $key ('1', '2', 'both')
    {
      if (keys (%{$diffs->{$key}}) == 0)
      {
        delete ($diffs->{$key});
      }
    }
  }
  $diffs
}

sub sort_distinct
{
  List::MoreUtils::distinct (sort @_);
}

sub references_diffs
{
  my ($ref_1, $ref_2) = @_;
  my %rh_1 = (%{$ref_1});
  my %rh_2 = (%{$ref_2});
  my $diffs = diffs_init ();

  simple_diffs (\%rh_1, \%rh_2, \@known_references_keys, \%known_references_key_types, $diffs);

  my @leftover_keys = sort_distinct (keys (%rh_1), keys (%rh_2));

  foreach my $leftover (@leftover_keys)
  {
    say ("LEFTOVER REFERENCES KEY: $leftover");
  }
  die if (@leftover_keys > 0);

  diffs_cleanup ($diffs);
}

my @known_field_simple_keys = ('NOTNULL', 'PRIMARYKEY', 'TYPE');
my %known_field_simple_key_types = ('NOTNULL' => 'n',
                                    'PRIMARYKEY' => 'n',
                                    'TYPE' => 's');

sub handle_references
{
  my ($sh_1, $sh_2, $diffs) = @_;
  my $key = 'REFERENCES';
  my $fk_1 = delete ($sh_1->{$key});
  my $fk_2 = delete ($sh_2->{$key});

  if (defined ($fk_1) and defined ($fk_2))
  {
    my $diff = references_diffs ($fk_1, $fk_2);

    if (defined ($diff))
    {
      $diffs->{'both'}{$key} = $diff;
    }
  }
  elsif (defined ($fk_1))
  {
    $diffs->{'1'}{$key} = $fk_1;
  }
  elsif (defined ($fk_2))
  {
    $diffs->{'2'}{$key} = $fk_2;
  }
  else
  {
    # nothing to do
  }
}

my %abstract_types = ('BOOLEAN' => 's',
                      'INT1' => 'n',
                      'INT2' => 'n',
                      'INT3' => 'n',
                      'INT4' => 'n',
                      'SMALLSERIAL' => 'n',
                      'MEDIUMSERIAL' => 'n',
                      'INTSERIAL' => 'n',
                      'TINYTEXT' => 's',
                      'MEDIUMTEXT' => 's',
                      'LONGTEXT' => 's',
                      #no default value allowed
                      'LONGBLOB' => 'x',
                      'DATETIME' => 'x');

sub get_scalar_type_for_sql_type
{
  my ($sql_type) = @_;
  my $type = '-';

  die unless (defined ($sql_type));
  if (exists ($abstract_types{$sql_type}))
  {
    $type = $abstract_types{$sql_type};
  }
  elsif ($sql_type =~ /^varchar/)
  {
    $type = 's';
  }
  elsif ($sql_type =~ /^decimal/)
  {
    $type = 'n';
  }
  elsif ($sql_type =~ /^char/)
  {
    $type = 's';
  }
  die if ($type eq 'x');
  if ($type eq '-')
  {
    say ('Unknown type ' . $sql_type);
    die;
  }

  $type
}

sub handle_default
{
  my ($sh_1, $sh_2, $diffs) = @_;
  my $key = 'DEFAULT';
  my $fk_1 = delete ($sh_1->{$key});
  my $fk_2 = delete ($sh_2->{$key});

  if (defined ($fk_1) and defined ($fk_2))
  {
    my $type_1 = get_scalar_type_for_sql_type ($sh_1->{'TYPE'});
    my $type_2 = get_scalar_type_for_sql_type ($sh_2->{'TYPE'});
    my $diff = 0;

    if ($type_1 eq $type_2)
    {
      if ($type_1 eq 's')
      {
        $diff = ($fk_1 ne $fk_2);
      }
      elsif ($type_1 eq 'n')
      {
        $diff = ($fk_1 != $fk_2);
      }
      else
      {
        die;
      }
    }
    else
    {
      $diff = 1;
    }
    if ($diff)
    {
      $diffs->{'both'}{$key} = [$fk_1, $fk_2];
    }
  }
  elsif (defined ($fk_1))
  {
    $diffs->{'1'}{$key} = $fk_1;
  }
  elsif (defined ($fk_2))
  {
    $diffs->{'2'}{$key} = $fk_2;
  }
  else
  {
    # nothing to do
  }
}

sub spec_diffs
{
  my ($spec_1, $spec_2) = @_;
  my $diffs = diffs_init ();
  my %sh_1 = (%{$spec_1});
  my %sh_2 = (%{$spec_2});

  handle_references (\%sh_1, \%sh_2, $diffs);
  # has to be called before simple_diffs, because we need 'TYPE' key
  handle_default (\%sh_1, \%sh_2, $diffs);
  simple_diffs (\%sh_1, \%sh_2, \@known_field_simple_keys, \%known_field_simple_key_types, $diffs);


  my @leftover_keys = sort_distinct (keys (%sh_1), keys (%sh_2));

  foreach my $leftover (@leftover_keys)
  {
    say ("LEFTOVER FIELDS KEY: $leftover");
  }
  die if (@leftover_keys > 0);

  diffs_cleanup ($diffs);
}

sub fields_diffs
{
  my ($tdump_1, $tdump_2) = @_;
  my %fh_1 = (@{$tdump_1->{'FIELDS'}});
  my %fh_2 = (@{$tdump_2->{'FIELDS'}});
  my @cols_1 = do { my $i = 0; grep {not $i++ % 2} @{$tdump_1->{'FIELDS'}} };
  my $diffs = diffs_init ();

  foreach my $col_1 (@cols_1)
  {
    my $spec_1 = delete ($fh_1{$col_1});
    my $spec_2 = delete ($fh_2{$col_1});

    if (defined ($spec_2))
    {
      my $diff_spec = spec_diffs ($spec_1, $spec_2);
      if (defined ($diff_spec))
      {
        $diffs->{'both'}{$col_1} = $diff_spec;
      }
    }
    else
    {
      $diffs->{'1'}{$col_1} = $spec_1;
    }
  }

  foreach my $col_2 (keys (%fh_2))
  {
    my $spec_1 = delete ($fh_1{$col_2});
    my $spec_2 = delete ($fh_2{$col_2});

    if (defined ($spec_1))
    {
      my $diff_spec = spec_diffs ($spec_1, $spec_2);
      if (defined ($diff_spec))
      {
        $diffs->{'both'}{$col_2} = $diff_spec;
      }
    }
    else
    {
      $diffs->{'2'}{$col_2} = $spec_2;
    }
  }

  diffs_cleanup ($diffs);
}

sub is_in
{
  my $needle = shift;

  foreach (@_)
  {
    if ($needle eq $_)
    {
      return 1;
    }
  }

  return 0;
}

sub relative_complement
{
  my ($a_1, $a_2) = @_;
  my @c = grep {not is_in ($_, @{$a_2})} @{$a_1};

  \@c;
}

sub ispec_array_diff
{
  my ($ispec_1, $ispec_2) = @_;
  my $only_in_1 = relative_complement ($ispec_1, $ispec_2);
  my $only_in_2 = relative_complement ($ispec_2, $ispec_1);
  my $diffs = diffs_init ();

  if (@{$only_in_1} > 0)
  {
    $diffs->{'1'} = $only_in_1;
  }
  if (@{$only_in_2} > 0)
  {
    $diffs->{'2'} = $only_in_2;
  }

  diffs_cleanup ($diffs);
}

sub ispec_hash_diff
{
  my ($ispec_1, $ispec_2) = @_;
  my $f_1 = $ispec_1->{'FIELDS'};
  my $f_2 = $ispec_2->{'FIELDS'};
  my $a_diff = ispec_array_diff ($f_1, $f_2);
  my $ispec_hash_diff = {};

  if (defined ($a_diff))
  {
    $ispec_hash_diff->{'FIELDS'} = $a_diff;
  }
  if ($ispec_1->{'TYPE'} ne $ispec_2->{'TYPE'})
  {
    $ispec_hash_diff->{'TYPE'} = [$ispec_1->{'TYPE'}, $ispec_2->{'TYPE'}];
  }

  if (keys (%{$ispec_hash_diff}) == 0)
  {
    $ispec_hash_diff = undef;
  }
  $ispec_hash_diff;
}

sub ispec_diff
{
  my ($ispec_1, $ispec_2) = @_;
  my $t_1 = ref ($ispec_1);
  my $t_2 = ref ($ispec_2);
  my $diffs;

  if ($t_1 eq 'ARRAY' and $t_2 eq 'ARRAY')
  {
    $diffs = ispec_array_diff ($ispec_1, $ispec_2);
  }
  elsif ($t_1 eq 'HASH' and $t_2 eq 'HASH')
  {
    $diffs = ispec_hash_diff ($ispec_1, $ispec_2);
  }
  elsif ($t_1 ne $t_2)
  {
    $diffs = [$ispec_1, $ispec_2];
  }
  else
  {
    die;
  }
  $diffs;
}

sub indexes_specs_diffs
{
  my ($idump_1, $idump_2) = @_;
  my %ih_1 = (@{$idump_1});
  my %ih_2 = (@{$idump_2});
  my @names_1 = do { my $i = 0; grep {not $i++ % 2} @{$idump_1} };
  my $diffs = diffs_init ();

  foreach my $name_1 (@names_1)
  {
    my $ispec_1 = delete ($ih_1{$name_1});
    my $ispec_2 = delete ($ih_2{$name_1});

    if (defined ($ispec_2))
    {
      my $diff_spec = ispec_diff ($ispec_1, $ispec_2);
      if (defined ($diff_spec))
      {
        $diffs->{'both'}{$name_1} = $diff_spec;
      }
    }
    else
    {
      $diffs->{'1'}{$name_1} = $ispec_1;
    }
  }

  foreach my $name_2 (keys (%ih_2))
  {
    my $ispec_1 = delete ($ih_1{$name_2});
    my $ispec_2 = delete ($ih_2{$name_2});

    if (defined ($ispec_1))
    {
      my $diff_spec = ispec_diff ($ispec_1, $ispec_2);
      if (defined ($diff_spec))
      {
        $diffs->{'both'}{$name_2} = $diff_spec;
      }
    }
    else
    {
      $diffs->{'2'}{$name_2} = $ispec_2;
    }
  }

  diffs_cleanup ($diffs);
}

sub indexes_diffs
{
  my ($tdump_1, $tdump_2) = @_;
  my $diffs = diffs_init ();
  my $has_1 = exists ($tdump_1->{'INDEXES'});
  my $has_2 = exists ($tdump_2->{'INDEXES'});

  if ($has_1 and $has_2)
  {
    $diffs->{'both'} = indexes_specs_diffs ($tdump_1->{'INDEXES'}, $tdump_2->{'INDEXES'});
  }
  elsif ($has_1)
  {
    $diffs->{'1'} = $tdump_1->{'INDEXES'};
  }
  elsif ($has_2)
  {
    $diffs->{'2'} = $tdump_2->{'INDEXES'};
  }
  else
  {
    # nothing to do.
  }

  diffs_cleanup ($diffs);
}

sub maybe_dump_diffs_for_tables
{
  my ($table_1, $data_1, $table_2, $data_2) = @_;
  my $tdump_1 = $data_1->{'dump'}{$table_1};
  my $tdump_2 = $data_2->{'dump'}{$table_2};
  my $fd = fields_diffs ($tdump_1, $tdump_2);
  my $id = indexes_diffs ($tdump_1, $tdump_2);

  if (defined ($fd) or defined ($id))
  {
    say ('Diffs between ' . $data_1->{'basename'} . ' in table ' . $table_1 . ' (1) and ' . $data_2->{'basename'} . ' in table ' . $table_2 . ' (2)');
    if (defined ($fd))
    {
      say ('Fields');
      say (Dumper ($fd));
    }
    if (defined ($id))
    {
      say ('Indexes');
      say (Dumper ($id));
    }
  }
}

sub maybe_dump_diffs
{
  my ($table_1, $data_1, $table_2, $data_2) = @_;
  my $dump_1 = $data_1->{'dump'};
  my $dump_2 = $data_2->{'dump'};
  my $in_d1 = exists ($dump_1->{$table_1});
  my $in_d2 = exists ($dump_2->{$table_2});

  if ($in_d1 and not $in_d2)
  {
    no_table_for ($table_2, $data_2);
    dump_table_for ($table_1, $data_1);
  }
  elsif ($in_d2 and not $in_d1)
  {
    no_table_for ($table_1, $data_1);
    dump_table_for ($table_2, $data_2);
  }
  else
  {
    maybe_dump_diffs_for_tables ($table_1, $data_1, $table_2, $data_2);
  }

}

sub diff_dump
{
  my ($datas, $tables) = @_;
  my $data_1 = $datas->[0];
  my $data_2 = $datas->[1];

  foreach my $table (@{$tables})
  {
    maybe_dump_diffs ($table, $data_1, $table, $data_2);
  }
}

$Data::Dumper::Sortkeys = 1;
if (@ARGV != 2)
{
  usage ();
}

my @datas = ();
my $with_table = undef;
my %filenames = ();

foreach my $option (@ARGV)
{
  my @parts = split (':', $option);

  if (@parts > 2)
  {
    usage ();
  }
  if (@parts == 1)
  {
    push (@parts, undef);
  }

  my $file = $parts[0];
  my $table = $parts[1];

  die if (exists ($filenames{$file}));
  $filenames{$file} = 1;

  unless (defined ($with_table))
  {
    $with_table = defined ($table);
  }
  die unless ($with_table == defined ($table));
  push (@datas, {'file' => $file,
                 'basename' => basename($file),
                 'table' => $table,
                 'dump' => get_schema_perl_dump ($file)});
}

if ($with_table)
{
  my $data_1 = $datas[0];
  my $data_2 = $datas[1];

  maybe_dump_diffs ($data_1->{'table'}, $data_1, $data_2->{'table'}, $data_2);
}
else
{
  my @tables = ();

  foreach my $data (@datas)
  {
    push (@tables, keys (%{$data->{'dump'}}));
  }

  @tables = sort_distinct (@tables);
  diff_dump (\@datas, \@tables);
}
