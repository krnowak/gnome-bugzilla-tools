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
use Data::Dumper;

# location marker
package LM;

sub new
{
  my ($type) = @_;
  my $class = (ref ($type) or $type or 'LM');
  my $self =
  {
    'old_line_no' => undef,
    'old_line_count' => undef,
    'new_line_no' => undef,
    'new_line_count' => undef,
    'inline_context' => undef
  };

  $self = bless ($self, $class);

  return $self;
}

sub new_zero
{
  my ($type) = @_;
  my $class = (ref ($type) or $type or 'LM');
  my $self = $class->new ();

  $self->set_old_line_no (0);
  $self->set_old_line_count (0);
  $self->set_new_line_no (0);
  $self->set_new_line_count (0);

  return $self;
}

sub parse_line
{
  my ($self, $line) = @_;

  if ($line =~ /^@@\s+-(\d+),(\d+)\s+\+(\d+),(\d+)\s+@@(?:\s+(\S.*))?$/)
  {
    my $old_line_no = $1;
    my $old_line_count = $2;
    my $new_line_no = $3;
    my $new_line_count = $4;
    my $inline_context = $5;

    $self->set_old_line_no ($old_line_no);
    $self->set_old_line_count ($old_line_count);
    $self->set_new_line_no ($new_line_no);
    $self->set_new_line_count ($new_line_count);
    $self->set_inline_context ($inline_context);

    return 1;
  }

  return 0;
}

sub clone
{
  my ($self) = @_;
  my $class = (ref ($self) or $self or 'LM');
  my $clone = $class->new ();

  $clone->set_old_line_no ($self->get_old_line_no ());
  $clone->set_new_line_no ($self->get_new_line_no ());
  $clone->set_old_line_count ($self->get_old_line_count ());
  $clone->set_new_line_count ($self->get_new_line_count ());
  $clone->set_inline_context ($self->get_inline_context ());

  return $clone;
}

sub set_old_line_no
{
  my ($self, $old_line_no) = @_;

  $self->{'old_line_no'} = $old_line_no;
}

sub get_old_line_no
{
  my ($self) = @_;

  return $self->{'old_line_no'};
}

sub inc_old_line_no
{
  my ($self) = @_;

  ++$self->{'old_line_no'};
}

sub dec_old_line_no
{
  my ($self) = @_;

  ++$self->{'old_line_no'};
}

sub set_old_line_count
{
  my ($self, $old_line_count) = @_;

  $self->{'old_line_count'} = $old_line_count;
}

sub get_old_line_count
{
  my ($self) = @_;

  return $self->{'old_line_count'};
}

sub inc_old_line_count
{
  my ($self) = @_;

  ++$self->{'old_line_count'};
}

sub dec_old_line_count
{
  my ($self) = @_;

  ++$self->{'old_line_count'};
}

sub set_new_line_no
{
  my ($self, $new_line_no) = @_;

  $self->{'new_line_no'} = $new_line_no;
}

sub get_new_line_no
{
  my ($self) = @_;

  return $self->{'new_line_no'};
}

sub inc_new_line_no
{
  my ($self) = @_;

  ++$self->{'new_line_no'};
}

sub dec_new_line_no
{
  my ($self) = @_;

  ++$self->{'new_line_no'};
}

sub set_new_line_count
{
  my ($self, $new_line_count) = @_;

  $self->{'new_line_count'} = $new_line_count;
}

sub get_new_line_count
{
  my ($self) = @_;

  return $self->{'new_line_count'};
}

sub inc_new_line_count
{
  my ($self) = @_;

  ++$self->{'new_line_count'};
}

sub dec_new_line_count
{
  my ($self) = @_;

  ++$self->{'new_line_count'};
}

sub set_inline_context
{
  my ($self, $inline_context) = @_;

  $self->{'inline_context'} = $inline_context;
}

sub get_inline_context
{
  my ($self) = @_;

  return $self->{'inline_context'};
}

sub add_marker
{
  my ($self, $other) = @_;

  $self->set_old_line_no ($self->get_old_line_no () + $other->get_old_line_no ());
  $self->set_new_line_no ($self->get_new_line_no () + $other->get_new_line_no ());
  $self->set_old_line_count ($self->get_old_line_count () + $other->get_old_line_count ());
  $self->set_new_line_count ($self->get_new_line_count () + $other->get_new_line_count ());
}

1;

# section
package S;

sub new
{
  my ($type, $name, $description, $index) = @_;
  my $class = (ref ($type) or $type or 'S');
  my $self =
  {
    'name' => $name,
    'description' => $description,
    'index' => $index
  };

  $self = bless ($self, $class);

  return $self;
}

sub get_name
{
  my ($self) = @_;

  return $self->{'name'};
}

sub get_description
{
  my ($self) = @_;

  return $self->{'description'};
}

sub get_index
{
  my ($self) = @_;

  return $self->{'index'};
}

sub is_older_than
{
  my ($self, $other) = @_;
  my $index = $self->get_index ();
  my $other_index = $other->get_index ();

  # the lower the index the older the section is.
  return ($index < $other_index);
}

sub is_younger_than
{
  my ($self, $other) = @_;

  return $other->is_older_than ($self);
}

1;

# code line
package CL;

use constant
{
  P => 0, # plus, added line
  M => 1, # minus, removed line
  S => 2, # space, unchanged line
  B => 3  # binary line
};

my $type_to_char =
{
  P () => '+',
  M () => '-',
  S () => ' '
};
my $char_to_type =
{
  '+' => P,
  '-' => M,
  ' ' => S
};

sub get_char
{
  my ($type) = @_;

  if (exists ($type_to_char->{$type}))
  {
    return $type_to_char->{$type};
  }

  return undef;
}

sub get_type
{
  my ($char) = @_;

  if (exists ($char_to_type->{$char}))
  {
    return $char_to_type->{$char};
  }

  return undef;
}

sub new
{
  my ($type, $sigil, $line) = @_;
  my $class = (ref ($type) or $type or 'CL');
  my $self =
  {
    'sigil' => $sigil,
    'line' => $line
  };

  $self = bless ($self, $class);

  return $self;
}

sub get_sigil
{
  my ($self) = @_;

  return $self->{'sigil'};
}

sub get_line
{
  my ($self) = @_;

  return $self->{'line'};
}

1;

# code base
package CB;

sub new
{
  my ($type) = @_;
  my $class = (ref ($type) or $type or 'CB');
  my $self =
  {
    'lines' => []
  };

  $self = bless ($self, $class);

  return $self;
}

sub get_lines
{
  my ($self) = @_;

  return $self->{'lines'};
}

sub push_line
{
  my ($self, $sigil, $code_line) = @_;
  my $lines = $self->get_lines ();
  my $line = CL->new ($sigil, $code_line);

  push (@{$lines}, $line);
}

1;

# final code
package FC;

use parent -norequire, qw(CB);

sub new
{
  my ($type, $marker) = @_;
  my $class = (ref ($type) or $type or 'FC');
  my $self = $class->SUPER::new ();

  $self->{'marker'} = $marker;
  $self->{'bare_marker'} = undef;
  $self->{'before_context'} = [];
  $self->{'after_context'} = [];
  $self = bless ($self, $class);

  return $self;
}

sub get_marker
{
  my ($self) = @_;

  return $self->{'marker'};
}

sub get_before_context
{
  my ($self) = @_;

  return $self->{'before_context'};
}

sub set_before_context
{
  my ($self, $context) = @_;

  $self->{'before_context'} = $context;
}

sub get_after_context
{
  my ($self) = @_;

  return $self->{'after_context'};
}

sub push_after_context_line
{
  my ($self, $line) = @_;
  my $after = $self->get_after_context ();

  push (@{$after}, $line);
}

sub set_bare_marker
{
  my ($self, $marker) = @_;

  $self->{'bare_marker'} = $marker;
}

sub get_bare_marker
{
  my ($self) = @_;

  return $self->{'bare_marker'};
}

sub cleanup_context
{
  my ($self) = @_;
  my $initial_context_count = 0;
  my $final_context_count = 0;
  my $modification_met = 0;
  my $lines = $self->get_lines ();

  # Compute lengths of context in lines.
  foreach my $line (@{$lines})
  {
    if ($line->get_sigil () == CL::S)
    {
      if ($modification_met)
      {
        ++$final_context_count;
      }
      else
      {
        ++$initial_context_count;
      }
    }
    else
    {
      $modification_met = 1;
      $final_context_count = 0;
    }
  }

  # Append/prepend context to lines.
  my $before_context = $self->get_before_context ();
  my $after_context = $self->get_after_context ();
  my $marker = $self->get_marker ();
  my $additions = LM->new_zero ();
  my $count = @{$before_context} + @{$after_context};
  my $line_no = -@{$before_context};

  unshift (@{$lines}, @{$before_context});
  push (@{$lines}, @{$after_context});
  $initial_context_count += @{$before_context};
  $final_context_count += @{$after_context};

  # Reduce context to three lines.
  if ($initial_context_count > 3)
  {
    my $cut = $initial_context_count - 3;

    splice (@{$lines}, 0, $cut);
    $count -= $cut;
    $line_no += $cut;
    $initial_context_count = 3;
  }
  if ($final_context_count > 3)
  {
    my $cut = $final_context_count - 3;

    splice (@{$lines}, -$cut, $cut);
    $count -= $cut;
    $final_context_count = 3;
  }

  # Update marker.
  $additions->set_old_line_count ($count);
  $additions->set_old_line_no ($line_no);
  $additions->set_new_line_count ($count);
  $additions->set_new_line_no ($line_no);
  $marker->add_marker ($additions);

  # Setup bare marker (for easy computing whether two final codes can be merged).
  my $bare_marker = $marker->clone ();

  $additions->set_old_line_count (-$initial_context_count - $final_context_count);
  $additions->set_new_line_count (-$initial_context_count - $final_context_count);
  $additions->set_old_line_no ($initial_context_count);
  $additions->set_new_line_no ($initial_context_count);
  $bare_marker->add_marker ($additions);
  $self->set_bare_marker ($bare_marker);
}

sub merge_final_code
{
  my ($self, $other) = @_;
  my $bare_marker = $self->get_bare_marker ();
  my $other_bare_marker = $other->get_bare_marker ();
  my $length_of_context_in_between = $other_bare_marker->get_new_line_no () - $bare_marker->get_new_line_no () - $bare_marker->get_new_line_count ();

  return 0 if $length_of_context_in_between > 6;

  my $lines = $self->get_lines ();
  my $other_lines = $other->get_lines ();
  my $additions = LM->new_zero ();
  my $marker = $self->get_marker ();
  my $other_marker = $other->get_marker ();
  my @after = @{$self->_get_after_context_from_lines ()};
  my @before = reverse (@{$other->_get_before_context_from_lines ()});
  my @context_in_between = ();

  # Prepare new inside context if there is going to be one.
  if ($length_of_context_in_between > 0)
  {
    my $left = $length_of_context_in_between;
    my $to_take = ((@after > $left) ? $left : @after);

    push (@context_in_between, @after[0 .. $to_take - 1]);
    $left -= $to_take;

    if ($left > 0)
    {
      $to_take = ((@before > $left) ? $left : @before);
      push (@context_in_between, reverse (@before[0 .. $to_take - 1]));
      $left -= $to_take;

      die "SHOULD NOT HAPPEN" if $left > 0;
    }
  }

  # Remove the old inside context and insert new one.
  splice (@{$lines}, -@after) if (@after);
  splice (@{$other_lines}, 0, @before) if (@before);

  push (@{$lines}, @context_in_between, @{$other_lines});

  # Update marker.
  my $common_count = @context_in_between - @after - @before;
  my $old_count = $other_marker->get_old_line_count () + $common_count;
  my $new_count = $other_marker->get_new_line_count () + $common_count;

  $additions->set_old_line_count ($old_count);
  $additions->set_new_line_count ($new_count);
  $marker->add_marker ($additions);

  # Update bare marker.
  my $new_before_context = $self->_get_before_context_from_lines ();
  my $new_after_context = $self->_get_after_context_from_lines ();
  my $line_no = @{$new_before_context};
  my $count = -@{$new_before_context} - @{$new_after_context};

  $additions->set_old_line_count ($count);
  $additions->set_new_line_count ($count);
  $additions->set_old_line_no ($line_no);
  $additions->set_new_line_no ($line_no);
  $bare_marker = $marker->clone ();
  $bare_marker->add_marker ($additions);
  $self->set_bare_marker ($bare_marker);

  return 1;
}

# Usable after cleaning up context.
sub _get_before_context_from_lines
{
  my ($self) = @_;
  my $lines = $self->get_lines ();
  my @context = ();

  foreach my $line (@{$lines}[0 .. 2])
  {
    last unless (defined ($line));
    last if ($line->get_sigil () != CL::S);
    push (@context, $line);
  }

  return \@context;
}

# Usable after cleaning up context.
sub _get_after_context_from_lines
{
  my ($self) = @_;
  my $lines = $self->get_lines ();
  my @context = ();

  foreach my $line (reverse (@{$lines}[-3 .. -1]))
  {
    last unless (defined ($line));
    last if ($line->get_sigil () != CL::S);
    unshift (@context, $line);
  }

  return \@context;
}

1;

# section code
package SC;

use parent -norequire, qw(CB);

sub new
{
  my ($type, $section) = @_;
  my $class = (ref ($type) or $type or 'SC');
  my $self = $class->SUPER::new ();

  $self->{'section'} = $section;
  $self = bless ($self, $class);

  return $self;
}

sub get_section
{
  my ($self) = @_;

  return $self->{'section'};
}

1;

# location code cluster
package LCC;

sub new
{
  my ($type, $marker) = @_;
  my $class = (ref ($type) or $type or 'LCC');
  my $self =
  {
    'marker' => $marker,
    'section_codes' => []
  };

  $self = bless ($self, $class);

  return $self;
}

sub get_section_codes
{
  my ($self) = @_;

  return $self->{'section_codes'};
}

sub push_section_code
{
  my ($self, $new_code) = @_;
  my $codes = $self->get_section_codes ();

  push (@{$codes}, $new_code);
}

sub get_marker
{
  my ($self) = @_;

  return $self->{'marker'};
}

1;

# diff header
package DH;

sub new
{
  my ($type) = @_;
  my $class = (ref ($type) or $type or 'DH');
  my $self =
  {
    'a' => undef,
    'b' => undef,
    'action' => undef,
    'mode' => undef,
    'index_from' => undef,
    'index_to' => undef
  };

  $self = bless ($self, $class);

  return $self;
}

sub parse_diff_line
{
  my ($self, $line) = @_;

  if ($line =~ m!^diff --git a/(.*) b/(.*)$!)
  {
    $self->set_a ($1);
    $self->set_b ($2);

    return 1;
  }

  return 0;
}

sub parse_mode_line
{
  my ($self, $line) = @_;

  if ($line =~ /^(.*)\s+mode\s+(\d+)$/)
  {
    $self->set_action ($1);
    $self->set_mode ($2);

    return 1;
  }

  return 0;
}

sub parse_index_line
{
  my ($self, $line) = @_;

  if ($line =~ /^index\s+(\w+)\.\.(\w+)(?:\s+(\d+))?$/)
  {
    $self->set_index_from ($1);
    $self->set_index_to ($2);
    if (defined ($3))
    {
      $self->set_mode ($3);
    }

    return 1;
  }

  return 0;
}

sub get_a
{
  my ($self) = @_;

  return $self->{'a'};
}

sub set_a
{
  my ($self, $a) = @_;

  $self->{'a'} = $a;
}

sub get_b
{
  my ($self) = @_;

  return $self->{'b'};
}

sub set_b
{
  my ($self, $b) = @_;

  $self->{'b'} = $b;
}

sub get_action
{
  my ($self) = @_;

  return $self->{'action'};
}

sub set_action
{
  my ($self, $action) = @_;

  $self->{'action'} = $action;
}

sub get_mode
{
  my ($self) = @_;

  return $self->{'mode'};
}

sub set_mode
{
  my ($self, $mode) = @_;

  $self->{'mode'} = $mode;
}

sub get_index_from
{
  my ($self) = @_;

  return $self->{'index_from'};
}

sub set_index_from
{
  my ($self, $index_from) = @_;

  $self->{'index_from'} = $index_from;
}

sub get_index_to
{
  my ($self) = @_;

  return $self->{'index_to'};
}

sub set_index_to
{
  my ($self, $index_to) = @_;

  $self->{'index_to'} = $index_to;
}

1;

# diff base
package DB;

sub new
{
  my ($type) = @_;
  my $class = (ref ($type) or $type or 'DB');
  my $self =
  {
    'header' => undef
  };

  $self = bless ($self, $class);

  return $self;
}

sub get_header
{
  my ($self) = @_;

  return $self->{'header'};
}

sub set_header
{
  my ($self, $header) = @_;

  $self->{'header'} = $header;
}

sub postprocess
{
  my ($self, $sections_array, $sections_hash) = @_;

  return $self->_postprocess_vfunc ($sections_array, $sections_hash);
}

1;

# text diff
package TD;

use parent -norequire, qw(DB);

sub new
{
  my ($type) = @_;
  my $class = (ref ($type) or $type or 'TD');
  my $self = $class->SUPER::new ();

  $self->{'clusters'} = [];
  $self->{'from'} = undef;
  $self->{'to'} = undef;

  $self = bless ($self, $class);

  return $self;
}

sub get_to
{
  my ($self) = @_;

  return $self->{'to'};
}

sub set_to
{
  my ($self, $to) = @_;

  $self->{'to'} = $to;
}

sub get_from
{
  my ($self) = @_;

  return $self->{'from'};
}

sub set_from
{
  my ($self, $from) = @_;

  $self->{'from'} = $from;
}

sub get_clusters
{
  my ($self) = @_;

  return $self->{'clusters'};
}

sub push_cluster
{
  my ($self, $new_cluster) = @_;
  my $clusters = $self->get_clusters ();

  push (@{$clusters}, $new_cluster);
}

sub _postprocess_vfunc
{
  my ($self, $sections_array, $sections_hash) = @_;
  # Special header for sections doing the file creation or deletion.
  my $header_outer = $self->_get_unidiff_header_for_outer ();
  # Typical header for section doing some changes to a file.
  my $header_inner = $self->_get_unidiff_header_for_inner ();
  # Keeps arrays of final codes.
  my $for_raw = $self->_create_array_for_each_section ($sections_array);
  # Additions for markers in code clusters in file to propagate line
  # changes done in previous clusters.
  my $marker_additions = $self->_create_marker_additions_for_each_section ($sections_array);

  foreach my $cluster (@{$self->get_clusters ()})
  {
    my $marker = $cluster->get_marker ();
    # Markers for each section for single code cluster. Each section
    # ends up having different numbers in its markers for the same
    # code cluster.
    my $markers = $self->_create_markers_for_each_section ($marker, $sections_array, $marker_additions);
    # The initial contexts for each section. Each section ends up
    # having different context in code cluster.
    my $before_contexts = $self->_create_array_for_each_section ($sections_array);
    # Array of final codes for each section. One final code for each
    # chunk of code delimited with SECTION comments.
    my $final_codes = $self->_create_array_for_each_section ($sections_array);

    foreach my $code (@{$cluster->get_section_codes ()})
    {
      my $section = $code->get_section ();
      my $section_name = $section->get_name ();
      my $lines_of_end_context_count = 0;
      my $final_marker = $markers->{$section_name}->clone ();
      my $final_code = FC->new ($final_marker);

      # Setup initial context for final code - will be used when
      # cleaning up context of the final code later.
      {
        my @context_copy = @{$before_contexts->{$section_name}};

        $final_code->set_before_context (\@context_copy);
      }
      # Reset final code's marker line counts to zero. They will be
      # updated as we iterate through lines in code chunk.
      $final_marker->set_old_line_count (0);
      $final_marker->set_new_line_count (0);

      foreach my $line (@{$code->get_lines ()})
      {
        $final_code->push_line ($line->get_sigil (), $line->get_line ());
        # Adapt markers for other sections.
        $self->_adapt_markers ($section, $line, $markers, $sections_hash);
        # Adapt marker for current final code.
        $self->_adapt_final_marker ($line, $final_marker);
        # Adapt initial contexts for other sections.
        $self->_adapt_before_contexts ($section, $line, $before_contexts, $sections_hash);
        # Maybe push an after context to previous final codes. Will be
        # used when cleaning up context of each final code later.
        $self->_push_after_context ($section, $line, $final_codes, $sections_hash);
      }
      push (@{$final_codes->{$section_name}}, $final_code);
    }

    # Cleanup context of each final code and try to merge every
    # adjacent final code. Afterwards add them to array to create a
    # raw representation of final code.
    foreach my $section (@{$sections_array})
    {
      my $section_name = $section->get_name ();
      my $final_codes_for_section = $final_codes->{$section_name};

      foreach my $final_code (@{$final_codes_for_section})
      {
        $final_code->cleanup_context ();
      }

      my $new_final_codes_for_section = [];
      my $index = 0;

      while ($index < @{$final_codes_for_section})
      {
        my $final_code = $final_codes_for_section->[$index];
        my $next_index = $index + 1;

        while ($next_index < @{$final_codes_for_section})
        {
          my $next_final_code = $final_codes_for_section->[$next_index];

          last unless ($final_code->merge_final_code ($next_final_code));
          ++$next_index;
        }
        $index = $next_index;
        push (@{$new_final_codes_for_section}, $final_code);
      }

      if (@{$new_final_codes_for_section})
      {
        push (@{$for_raw->{$section_name}}, @{$new_final_codes_for_section});
      }
    }
  }

  # Prepare raw representations of final codes. When file is added or
  # deleted the code doing it has to have a different header - the
  # outer one. The rest of codes are making changes to already/still
  # existing file, so they need ordinary header - the inner one. Also,
  # for such files small corrections are needed to inner codes,
  # because of using special 0,0 marker value denoting file
  # creation/deletion. That special value is causing off-by-one errors
  # if not corrected in inner patches.
  my $header = $self->get_header ();
  my $action = $header->get_action ();
  my $inner_index_first = 0;
  my $inner_index_last = @{$sections_array} - 1;
  my $outer_section_index = undef;
  my $raw = {};
  my $final_inner_correction = LM->new_zero ();
  my $mode = $header->get_mode ();
  my $mode_section_index = 0;

  unless (defined ($action))
  {
    my $oldest_section_index_in_this_diff = 0;

    foreach my $section (@{$sections_array})
    {
      my $section_name = $section->get_name ();

      last if (@{$for_raw->{$section_name}});

      ++$oldest_section_index_in_this_diff;
    }

    die "SHOULD NOT HAPPEN" if $oldest_section_index_in_this_diff >= @{$sections_array};
    $mode_section_index = $oldest_section_index_in_this_diff;
  }
  elsif ($action eq "new file")
  {
    my $oldest_section_index_in_this_diff = 0;

    foreach my $section (@{$sections_array})
    {
      my $section_name = $section->get_name ();

      last if (@{$for_raw->{$section_name}});

      ++$oldest_section_index_in_this_diff;
    }

    die "SHOULD NOT HAPPEN" if $oldest_section_index_in_this_diff >= @{$sections_array};
    $inner_index_first = $oldest_section_index_in_this_diff + 1;
    $outer_section_index = $oldest_section_index_in_this_diff;
    $final_inner_correction->inc_old_line_no ();
    $mode_section_index = $oldest_section_index_in_this_diff;
  }
  elsif ($action eq "deleted file")
  {
    my $youngest_section_index_in_this_diff = -1;

    foreach my $section (reverse (@{$sections_array}))
    {
      my $section_name = $section->get_name ();

      last if (@{$for_raw->{$section_name}});

      --$youngest_section_index_in_this_diff;
    }

    die "SHOULD NOT HAPPEN" if -$youngest_section_index_in_this_diff > @{$sections_array};
    $inner_index_last = @{$sections_array} - 1 + $youngest_section_index_in_this_diff;
    $outer_section_index = $youngest_section_index_in_this_diff;
    $final_inner_correction->inc_new_line_no ();
    $mode = undef;
  }

  if (defined ($outer_section_index))
  {
    my $outer_section_name = $sections_array->[$outer_section_index]->get_name ();

    $raw->{$outer_section_name} = $self->_get_raw_text_for_final_codes ($header_outer, $for_raw->{$outer_section_name});

  }

  my @inner_sections_slice = @{$sections_array}[$inner_index_first .. $inner_index_last];

  foreach my $section (@inner_sections_slice)
  {
    my $section_name = $section->get_name ();
    my $final_codes = $for_raw->{$section_name};

    foreach my $final_code (@{$final_codes})
    {
      my $final_marker = $final_code->get_marker ();

      $final_marker->add_marker ($final_inner_correction);
    }

    next unless (@{$final_codes});
    $raw->{$section_name} = $self->_get_raw_text_for_final_codes ($header_inner, $final_codes);
  }

  if (defined ($mode))
  {
    my $section_name = $sections_array->[$mode_section_index]->get_name ();
    my $changed_file = $self->_get_changed_file ();

    return {'mode' => {'section' => $section_name, 'mode' => $mode, 'file' => $changed_file}, 'raw' => $raw};
  }

  return {'raw' => $raw};
}

sub _get_unidiff_header_for_outer
{
  my ($self) = @_;
  my $from = $self->_maybe_prefix ('a', $self->get_from ());
  my $to = $self->_maybe_prefix ('b', $self->get_to ());

  return join ("\n",
               "--- $from",
               "+++ $to");
}

sub _get_unidiff_header_for_inner
{
  my ($self) = @_;
  my $file = $self->_get_changed_file ();
  my $from = $self->_maybe_prefix ('a', $file);
  my $to = $self->_maybe_prefix ('b', $file);

  return join ("\n",
               "--- $from",
               "+++ $to");
}

sub _get_changed_file
{
  my ($self) = @_;
  my $file = $self->get_to ();

  if ($file eq '/dev/null')
  {
    $file = $self->get_from ();
  }

  return $file;
}

sub _maybe_prefix
{
  my ($self, $prefix, $path) = @_;

  if ($path eq '/dev/null')
  {
    return $path;
  }
  else
  {
    return $prefix . '/' . $path;
  }
}

sub _create_array_for_each_section
{
  my ($self, $sections_array) = @_;
  my %contexts = map { $_->get_name () => [] } @{$sections_array};

  return \%contexts;
}

sub _create_marker_additions_for_each_section
{
  my ($self, $sections_array) = @_;
  my %additions = map { $_->get_name () => LM->new_zero () } @{$sections_array};

  return \%additions;
}

sub _create_markers_for_each_section
{
  my ($self, $marker, $sections_array, $marker_additions) = @_;
  my $markers = {};

  foreach my $section (@{$sections_array})
  {
    my $section_name = $section->get_name ();
    my $addition = $marker_additions->{$section_name};
    my $section_marker = $marker->clone ();

    $section_marker->add_marker ($addition);
    $markers->{$section_name} = $section_marker;
  }

  return $markers;
}

sub _adapt_additions
{
  my ($self, $current_section, $current_line, $additions, $sections_hash) = @_;
  my @all_section_names = keys (%{$additions});
  my $sigil = $current_line->get_sigil ();

  foreach my $section_name (@all_section_names)
  {
    my $marker = $additions->{$section_name};
    my $section = $sections_hash->{$section_name};

    if ($sigil == CL::P)
    {
      if ($section->is_younger_than ($current_section))
      {
        # old line no + 1
        # new line no + 1
        $marker->inc_old_line_no ();
        $marker->inc_new_line_no ();
      }
      elsif ($section->is_older_than ($current_section))
      {
        # nothing changes
      }
      else # same section
      {
        $marker->inc_new_line_no ();
        # new line no + 1
      }
    }
    elsif ($sigil == CL::M)
    {
      if ($section->is_younger_than ($current_section))
      {
        $marker->dec_old_line_no ();
        $marker->dec_new_line_no ();
        # old line no - 1
        # new line no - 1
      }
      elsif ($section->is_older_than ($current_section))
      {
        # nothing changes
      }
      else # same section
      {
        $marker->dec_new_line_no ();
        # new line no - 1
      }
    }
  }
}

sub _adapt_markers
{
  my ($self, $current_section, $current_line, $markers, $sections_hash) = @_;
  my @all_section_names = keys (%{$markers});
  my $sigil = $current_line->get_sigil ();

  foreach my $section_name (@all_section_names)
  {
    my $marker = $markers->{$section_name};
    my $section = $sections_hash->{$section_name};

    if ($sigil == CL::P)
    {
      if ($section->is_younger_than ($current_section))
      {
        # old line no + 1
        # new line no + 1
        $marker->inc_old_line_no ();
        $marker->inc_new_line_no ();
      }
      elsif ($section->is_older_than ($current_section))
      {
        # nothing changes
      }
      else # same section
      {
        $marker->inc_new_line_no ();
        # new line no + 1
      }
    }
    elsif ($sigil == CL::M)
    {
      if ($section->is_younger_than ($current_section))
      {
        # nothing changes
      }
      elsif ($section->is_older_than ($current_section))
      {
        $marker->inc_old_line_no ();
        $marker->inc_new_line_no ();
        # old line no + 1
        # new line no + 1
      }
      else # same section
      {
        $marker->inc_old_line_no ()
        # old line no + 1
      }
    }
    elsif ($sigil == CL::S)
    {
      $marker->inc_old_line_no ();
      $marker->inc_new_line_no ();
      if ($section->is_younger_than ($current_section))
      {
        # old line no + 1
        # new line no + 1
      }
      elsif ($section->is_older_than ($current_section))
      {
        # old line no + 1
        # new line no + 1
      }
      else # same section
      {
        # old line no + 1
        # new line no + 1
      }
    }
  }
}

sub _adapt_final_marker
{
  my ($self, $current_line, $marker) = @_;
  my $sigil = $current_line->get_sigil ();

  if ($sigil == CL::P)
  {
    $marker->inc_new_line_count ();
  }
  elsif ($sigil == CL::M)
  {
    $marker->inc_old_line_count ();
  }
  elsif ($sigil == CL::S)
  {
    $marker->inc_old_line_count ();
    $marker->inc_new_line_count ();
  }
}

sub _adapt_before_contexts
{
  my ($self, $current_section, $current_line, $before_contexts, $sections_hash) = @_;
  my @all_section_names = keys (%{$before_contexts});
  my $sigil = $current_line->get_sigil ();

  foreach my $section_name (@all_section_names)
  {
    my $before_context = $before_contexts->{$section_name};
    my $section = $sections_hash->{$section_name};

    if ($sigil == CL::S or
        ($section->is_older_than ($current_section) and $sigil == CL::M) or
        ($section->is_younger_than ($current_section) and $sigil == CL::P))
    {
      $self->_append_context ($before_context, CL->new (CL::S, $current_line->get_line ()));
    }
  }
}

sub _push_after_context
{
  my ($self, $current_section, $current_line, $final_codes, $sections_hash) = @_;
  my @all_section_names = keys (%{$final_codes});
  my $sigil = $current_line->get_sigil ();

  foreach my $section_name (@all_section_names)
  {
    my $section = $sections_hash->{$section_name};

    if ($sigil == CL::S or
        ($section->is_older_than ($current_section) and $sigil == CL::M) or
        ($section->is_younger_than ($current_section) and $sigil == CL::P))
    {
      foreach my $final_code (@{$final_codes->{$section_name}})
      {
        $final_code->push_after_context_line (CL->new (CL::S, $current_line->get_line ()));
      }
    }
  }
}

sub _append_context
{
  my ($self, $context, $line) = @_;

  push (@{$context}, $line);
  while (@{$context} > 3)
  {
    shift (@{$context});
  }
}

sub _get_raw_text_for_final_codes
{
  my ($self, $header, $final_codes) = @_;
  my @raw_codes = map { $self->_get_raw_text_for_final_code ($_) } @{$final_codes};

  return join ("\n",
               $header,
               @raw_codes,
               '');
}

sub _get_raw_text_for_final_code
{
  my ($self, $final_code) = @_;
  my $marker = $final_code->get_marker ();
  my $lines = $final_code->get_lines ();
  my @raw_lines = $self->_lines_to_string ($lines);

  return join ("\n",
               $self->_marker_to_string ($marker),
               @raw_lines);
}

sub _lines_to_string
{
  my ($self, $lines) = @_;

  return map { CL::get_char ($_->get_sigil ()) . $_->get_line () } @{$lines};
}

sub _marker_to_string
{
  my ($self, $marker) = @_;
  my $raw = '@@ -' . $marker->get_old_line_no () . ',' . $marker->get_old_line_count () . ' +' . $marker->get_new_line_no () . ',' . $marker->get_new_line_count () . ' @@';
  my $inline_context = $marker->get_inline_context ();

  if (defined ($inline_context))
  {
    $raw .= ' ' . $inline_context;
  }

  return $raw;
}

1;

# binary diff
package BD;

use parent -norequire, qw(DB);

sub new
{
  my ($type) = @_;
  my $class = (ref ($type) or $type or 'BD');
  my $self = $class->SUPER::new ();

  $self->{'code'} = undef;
  $self = bless ($self, $class);

  return $self;
}

sub get_code
{
  my ($self) = @_;

  return $self->{'code'};
}

sub set_code
{
  my ($self, $code) = @_;

  $self->{'code'} = $code;
}

sub _postprocess_vfunc
{
  my ($self, $sections_array, $sections_hash) = @_;
  my $code = $self->get_code ();
  my $name = $code->get_section ()->get_name ();
  my $raw = join ("\n",
                  $self->_get_diff_git_header (),
                  "GIT binary patch",
                  @{$self->_get_raw_lines ($code->get_lines ())},
                  "");

  return {'raw' => {$name => $raw}};
}

sub _get_diff_git_header
{
  my ($self) = @_;
  my $header = $self->get_header ();
  my $a = 'a/' . $header->get_a ();
  my $b = 'b/' . $header->get_b ();
  my $action = $header->get_action ();
  my $mode = $header->get_mode ();
  my $index_from = $header->get_index_from ();
  my $index_to = $header->get_index_to ();

  # XXX: We probably don't have to worry about undefined action here -
  # probably binary patches are always additions or deletions. Not
  # sure, though. Still, no such case in my ordinary use.
  return join ("\n",
               "diff --git $a $b",
               "$action mode $mode",
               "index $index_from..$index_to");
}

sub _get_raw_lines
{
  my ($self, $lines) = @_;
  my @raw_lines = map { $_->get_line () } @{$lines};

  return \@raw_lines;
}

1;

# patch
package P;

sub new
{
  my ($type) = @_;
  my $class = (ref ($type) or $type or 'P');
  my $self =
  {
    'author' => undef,
    'diffs' => [],
    'sections_ordered' => [],
    'sections_unordered' => {},
    'raw_diffs_and_modes' => {}
  };

  $self = bless ($self, $class);

  return $self;
}

sub get_author
{
  my ($self, $author) = @_;

  return $self->{'author'};
}

sub set_author
{
  my ($self, $author) = @_;

  $self->{'author'} = $author;
}

sub get_diffs
{
  my ($self) = @_;

  return $self->{'diffs'};
}

sub add_diff
{
  my ($self, $diff) = @_;
  my $diffs = $self->get_diffs ();

  push (@{$diffs}, $diff);
}

sub get_last_diff
{
  my ($self) = @_;
  my $diffs = $self->get_diffs ();

  if (@{$diffs} > 0)
  {
    return @{$diffs}[-1];
  }

  return undef;
}

sub get_sections_ordered
{
  my ($self) = @_;

  return $self->{'sections_ordered'};
}

sub get_sections_unordered
{
  my ($self) = @_;

  return $self->{'sections_unordered'};
}

sub add_section
{
  my ($self, $section) = @_;
  my $ordered = $self->get_sections_ordered ();
  my $unordered = $self->get_sections_unordered ();
  my $name = $section->get_name ();

  if (exists ($unordered->{$name}))
  {
    return 0;
  }

  push (@{$ordered}, $section);
  $unordered->{$name} = $section;
  return 1;
}

sub get_raw_diffs_and_modes
{
  my ($self) = @_;

  return $self->{'raw_diffs_and_modes'};
}

sub add_raw_diffs_and_mode
{
  my ($self, $diffs_and_mode) = @_;
  my $raw_diffs_and_modes = $self->get_raw_diffs_and_modes ();
  my $diffs = $diffs_and_mode->{'raw'};

  foreach my $section_name (keys (%{$diffs}))
  {
    unless (exists ($raw_diffs_and_modes->{$section_name}))
    {
      $raw_diffs_and_modes->{$section_name} = {'diffs' => []};
    }

    push (@{$raw_diffs_and_modes->{$section_name}->{'diffs'}}, $diffs->{$section_name});
  }

  if (exists ($diffs_and_mode->{'mode'}))
  {
    my $mode = $diffs_and_mode->{'mode'};
    my $section_name = $mode->{'section'};
    my $file = $mode->{'file'};
    my $st_mode = $mode->{'mode'};

    unless (exists ($raw_diffs_and_modes->{$section_name}->{'modes'}))
    {
      $raw_diffs_and_modes->{$section_name}->{'modes'} = [];
    }

    my $chmod_mode = $self->_get_chmod_mode ($st_mode);

    push (@{$raw_diffs_and_modes->{$section_name}->{'modes'}}, {'mode' => $chmod_mode, 'file' => $file});
  }
}

sub _get_chmod_mode
{
  my ($self, $mode) = @_;

  if ($mode =~ /^\d{3}(\d{3})$/)
  {
    return $1;
  }

  die 'Invalid mode';
}

sub get_ordered_sectioned_raw_diffs_and_modes
{
  my ($self) = @_;
  my $sections_array = $self->get_sections_ordered ();
  my $raw_diffs_and_modes = $self->get_raw_diffs_and_modes ();
  my @sectioned_diffs_and_modes = ();

  foreach my $section (@{$sections_array})
  {
    my $section_name = $section->get_name ();

    if (exists ($raw_diffs_and_modes->{$section_name}))
    {
      my $diffs_and_modes =
      {
        'diffs' => $raw_diffs_and_modes->{$section_name}->{'diffs'},
        'section' => $section
      };
      if (exists ($raw_diffs_and_modes->{$section_name}->{'modes'}))
      {
        $diffs_and_modes->{'modes'} = $raw_diffs_and_modes->{$section_name}->{'modes'};
      }

      push (@sectioned_diffs_and_modes, $diffs_and_modes);
    }
  }

  return \@sectioned_diffs_and_modes;
}

1;

# parse context
package PC;

sub new
{
  my ($type, $initial_mode, $ops) = @_;
  my $class = (ref ($type) or $type or 'PC');
  my $self =
  {
    'file' => undef,
    'filename' => undef,
    'chunks' => [],
    'mode' => $initial_mode,
    'line_number' => 0,
    'current_chunk' => undef,
    'ops' => $ops,
    'line' => undef,
    'patch' => P->new (),
    'patches' => [],
    'current_diff_header' => undef
  };

  $self = bless ($self, $class);

  return $self;
}

sub setup_file
{
  my ($self, $file, $filename) = @_;

  $self->{'file'} = $file;
  $self->{'filename'} = $filename;
}

sub get_file
{
  my ($self) = @_;

  return $self->{'file'};
}

sub get_filename
{
  my ($self) = @_;

  return $self->{'filename'};
}

sub get_patch
{
  my ($self) = @_;

  return $self->{'patch'};
}

sub get_mode
{
  my ($self) = @_;

  return $self->{'mode'};
}

sub set_mode
{
  my ($self, $mode) = @_;

  $self->{'mode'} = $mode;
}

sub get_line
{
  my ($self) = @_;

  return $self->{'line'};
}

sub set_line
{
  my ($self, $line) = @_;

  $self->{'line'} = $line;
}

sub read_next_line
{
  my ($self) = @_;
  my $file = $self->get_file ();
  my $line = $file->getline ();

  if (defined ($line))
  {
    chomp ($line);
    $self->set_line ($line);
    $self->inc_line_no ();
  }
  elsif (defined ($self->get_line ()))
  {
    $self->set_line (undef);
    $self->inc_line_no ();
  }

  return defined ($self->get_line ());
}

sub run_op
{
  my ($self) = @_;
  my $ops = $self->{'ops'};
  my $mode = $self->get_mode ();

  unless (exists ($ops->{$mode}))
  {
    $self->die ("Unknown patch mode: '$mode'.");
  }

  $ops->{$mode} ();
}

sub get_line_no
{
  my ($self) = @_;

  return $self->{'line_number'};
}

sub inc_line_no
{
  my ($self) = @_;

  ++$self->{'line_number'};
}

sub die
{
  my ($self, $message) = @_;
  my $filename = $self->get_filename ();
  my $line_no = $self->get_line_no ();

  die "$filename:$line_no - $message";
}

sub get_last_diff_or_die
{
  my ($self) = @_;
  my $patch = $self->get_patch ();
  my $diff = $patch->get_last_diff ();

  unless (defined ($diff))
  {
    $self->die ("Expected a diff to exist.");
  }

  return $diff;
}

sub exhaust_the_file
{
  my ($self) = @_;
  my $file = $self->get_file ();

  while ($self->read_next_line ()) {};
}

sub get_patches
{
  my ($self) = @_;

  return $self->{'patches'};
}

sub get_current_diff_header
{
  my ($self) = @_;

  return $self->{'current_diff_header'};
}

sub set_current_diff_header
{
  my ($self, $current_diff_header) = @_;

  $self->{'current_diff_header'} = $current_diff_header;
}

sub get_current_diff_header_or_die
{
  my ($self) = @_;
  my $diff_header = $self->get_current_diff_header ();

  unless (defined ($diff_header))
  {
    $self->die ("Expected diff header to exist.");
  }

  return $diff_header;
}

1;

# gnome patch
package GP;

sub new
{
  my ($type) = @_;
  my $class = (ref ($type) or $type or 'GP');
  my $self =
  {
    'raw_diffs' => {}
  };

  $self = bless ($self, $class);

  return $self;
}

sub get_raw_diffs
{
  my ($self) = @_;

  return $self->{'raw_diffs'};
}

sub process
{
  my ($self, $filename) = @_;

  $self->_prepare_parse_context ();
  $self->_load_file ($filename);
  $self->_parse_file ();
  $self->_cleanup ();
}

sub _prepare_parse_context
{
  my ($self) = @_;
  my $ops =
  {
    'intro' => sub { $self->_on_intro (@_); },
    'listing' => sub { $self->_on_listing (@_); },
    'rest' => sub { $self->_on_rest (@_); }
  };

  $self->{'p_c'} = PC->new ('intro', $ops);
}

sub _load_file
{
  my ($self, $filename) = @_;
  my $pc = $self->_get_pc ();
  my $file = IO::File->new ($filename, 'r');

  unless (defined ($file))
  {
    die "Could not load '$filename'.";
  }

  $file->binmode (':utf8');
  $pc->setup_file ($file, $filename);
}

sub _parse_file
{
  my ($self) = @_;
  my $pc = $self->_get_pc ();

  while ($pc->read_next_line ())
  {
    $pc->run_op ();
  }
}

sub _on_intro
{
  my ($self) = @_;
  my $pc = $self->_get_pc ();
  my $patched = 0;

  while ((my $line = $pc->get_line ()) ne '')
  {
    if ($line =~ /^From:\s+(.*)$/)
    {
      my $author = $1;
      my $patch = $pc->get_patch ();

      if ($patched)
      {
        $pc->die ("Two 'From: ' lines in intro.");
      }
      $patch->set_author ($author);
    }
    $self->_read_next_line_or_die ();
  }
  $pc->set_mode ('listing');
}

sub _on_listing
{
  my ($self) = @_;
  my $pc = $self->_get_pc ();

  if ($pc->get_line () ne '---')
  {
    $pc->die ("Expected '---'.");
  }
  $self->_read_next_line_or_die ();

  my $listing_started = 0;
  my $patch = $pc->get_patch ();

  while ((my $line = $pc->get_line ()) ne '')
  {
    if ($line =~ /^# SECTION: (\w+)\s+-\s+(.+)$/)
    {
      my $name = $1;
      my $description = $2;

      if ($listing_started)
      {
        $pc->die ("SECTION comment mixed with listing.");
      }

      my $sections_array = $patch->get_sections_ordered ();
      my $section = S->new ($name, $description, scalar (@{$sections_array}));

      unless ($patch->add_section ($section))
      {
        $pc->die ("Section '$name' specified twice.");
      }
    }
    elsif ($line =~ /^ \S/)
    {
      my $sections = $patch->get_sections_ordered ();

      unless (@{$sections})
      {
        $pc->die ("No sections specified.");
      }
      $listing_started = 1;
    }
    else
    {
      $pc->die ("Unknown line in listing.");
    }
    $self->_read_next_line_or_die ();
  }
  $pc->set_mode ('rest');
}

sub _on_rest
{
  my ($self) = @_;
  my $loop = 1;

  while ($loop)
  {
    $self->_handle_index_lines ();
    $loop = $self->_handle_diff_lines ();
    $self->_postprocess_diff ();
  }
}

sub _handle_index_lines
{
  my ($self) = @_;
  my $pc = $self->_get_pc ();
  my $word = $self->_get_first_word ();

  if (defined ($word) and $word eq 'diff')
  {
    # XXX: This section of code is rather incorrect - there can be
    # more lines in this part of diff. But for my ordinary use no such
    # diffs existed.
    my $diff_header = DH->new ();
    my $line = $pc->get_line ();

    unless ($diff_header->parse_diff_line ($line))
    {
      $pc->die ("Malformed diff line.");
    }

    $self->_read_next_line_or_die ();
    $line = $pc->get_line ();
    if ($diff_header->parse_mode_line ($line))
    {
      $self->_read_next_line_or_die ();
      $line = $pc->get_line ();
    }

    unless ($diff_header->parse_index_line ($line))
    {
      $pc->die ("Expected 'index'.");
    }

    $self->_read_next_line_or_die ();
    $pc->set_current_diff_header ($diff_header);
  }
  else
  {
    $pc->die ("Expected 'diff --git'.");
  }
}

sub _handle_diff_lines
{
  my ($self) = @_;
  my $pc = $self->_get_pc ();
  my $continue_parsing_rest = 1;

  if ($pc->get_line () =~ /^---\s/)
  {
    $continue_parsing_rest = $self->_handle_text_patch ();
  }
  elsif ($pc->get_line () eq 'GIT binary patch')
  {
    $continue_parsing_rest = $self->_handle_binary_patch ();
  }
  else
  {
    $pc->die ("Expected '---' or 'GIT binary patch'.");
  }

  return $continue_parsing_rest;
}

sub _handle_text_patch
{
  my ($self) = @_;
  my $pc = $self->_get_pc ();
  my $diff_header = $pc->get_current_diff_header_or_die ();
  my $diff = TD->new ();

  $diff->set_header ($diff_header);
  if ($pc->get_line () =~ /^---\s+(.+)/)
  {
    my $from = $1;

    if ($from =~ m!^a/(.*)$!)
    {
      $from = $1;
    }
    $diff->set_from ($from);
  }
  else
  {
    $pc->die ("Expected '---'.");
  }
  $self->_read_next_line_or_die ();

  if ($pc->get_line () =~ /^\+\+\+\s+(.+)/)
  {
    my $to = $1;

    if ($to =~ m!^b/(.*)$!)
    {
      $to = $1;
    }
    $diff->set_to ($to);
  }
  else
  {
    $pc->die ("Expected '+++'.");
  }
  $self->_read_next_line_or_die ();

  my $initial_marker = LM->new ();

  if ($pc->get_line () =~ /^@@/)
  {
    unless ($initial_marker->parse_line ($pc->get_line ()))
    {
      $pc->die ("Failed to parse location marker.");
    }
  }
  else
  {
    $pc->die ("Expected '\@\@'.");
  }

  my $last_cluster = LCC->new ($initial_marker);
  my $continue_parsing_rest = 1;
  my $just_got_location_marker = 1;
  my $patch = $pc->get_patch ();
  my $sections_hash = $patch->get_sections_unordered ();
  my $sections_array = $patch->get_sections_ordered ();
  my $code = undef;

  while ($pc->read_next_line ())
  {
    my $line = $pc->get_line ();

    # Stupid line maybe denoting an end of patch - depends on whether
    # next line is still proper patch line or git's version number. In
    # latter case - it is end of patch.
    if ($line eq '-- ')
    {
      $self->_read_next_line_or_die ();
      if ($pc->get_line () =~ /^\d+\.\d+\.\d+$/)
      {
        if ($just_got_location_marker)
        {
          $pc->die ("End of patch just after location marker.");
        }
        $self->_push_section_code_to_cluster_or_die ($code, $last_cluster);
        $diff->push_cluster ($last_cluster);
        $continue_parsing_rest = 0;
        last;
      }
      if ($just_got_location_marker)
      {
        my $last = $sections_array->[-1];

        $code = SC->new ($last);
        $just_got_location_marker = 0;
      }
      $code->push_line (CL::M, '- ');
      redo;
    }
    elsif ($line =~ /^@@/)
    {
      if ($just_got_location_marker)
      {
        $pc->die ("Two location markers in a row.");
      }

      my $marker = LM->new ();

      $self->_push_section_code_to_cluster_or_die ($code, $last_cluster);
      $code = undef;
      $diff->push_cluster ($last_cluster);
      unless ($marker->parse_line ($line))
      {
        $pc->die ("Failed to parse location marker.");
      }
      $last_cluster = LCC->new ($marker);
      $just_got_location_marker = 1;
    }
    elsif ($line =~ /^#/)
    {
      if ($line =~ /^# SECTION: (\w+)$/)
      {
        my $name = $1;

        unless (exists ($sections_hash->{$name}))
        {
          $pc->die ("Unknown section '$name'.");
        }

        my $section = $sections_hash->{$name};

        if (defined ($code) and $code->get_section ()->get_name () eq $name)
        {
          # ignore the sections line.
        }
        else
        {
          if ($just_got_location_marker)
          {
            $just_got_location_marker = 0;
          }
          else
          {
            $self->_push_section_code_to_cluster_or_die ($code, $last_cluster);
          }
          $code = SC->new ($section);
        }
      }
      elsif ($line !~ /^# COMMENT: /)
      {
        $pc->die ("Malformed comment.");
      }
    }
    elsif ($line =~ /^([- +])(.*)$/)
    {
      my $sigil = $1;
      my $code_line = $2;
      my $type = CL::get_type ($sigil);

      unless (defined ($type))
      {
        $pc->die ("Unknown type of line: $sigil.");
      }

      if ($just_got_location_marker)
      {
        my $last = $sections_array->[-1];

        $code = SC->new ($last);
        $just_got_location_marker = 0;
      }
      $code->push_line ($type, $code_line);
    }
    else
    {
      $self->_push_section_code_to_cluster_or_die ($code, $last_cluster);
      $diff->push_cluster ($last_cluster);
      last;
    }
  }
  $patch->add_diff ($diff);

  unless ($continue_parsing_rest)
  {
    $pc->exhaust_the_file ();
  }

  return $continue_parsing_rest;
}

sub _push_section_code_to_cluster_or_die
{
  my ($self, $code, $cluster) = @_;
  my $pc = $self->_get_pc ();
  my $useless = 1;

  foreach my $line (@{$code->get_lines ()})
  {
    if ($line->get_sigil () != CL::S)
    {
      $useless = 0;
      last;
    }
  }
  if ($useless)
  {
    $pc->die ("Useless section.");
  }
  else
  {
    $cluster->push_section_code ($code);
  }
}

sub _handle_binary_patch
{
  my ($self) = @_;
  my $pc = $self->_get_pc ();
  my $continue_parsing_rest = 1;
  my $first_try = 1;
  my $code = undef;
  my $diff_header = $pc->get_current_diff_header_or_die ();
  my $diff = BD->new ();
  my $patch = $pc->get_patch ();

  $diff->set_header ($diff_header);
  while ($pc->read_next_line ())
  {
    my $line = $pc->get_line ();

    if ($first_try)
    {
      my $sections_hash = $patch->get_sections_unordered ();
      my $sections_array = $patch->get_sections_ordered ();

      if ($line =~ /^#/)
      {
        if ($line =~ /^# SECTION: (\w+)$/)
        {
          my $name = $1;

          $first_try = 0;
          unless (exists ($sections_hash->{$name}))
          {
            $pc->die ("Unknown section '$name'.");
          }

          $code = SC->new ($sections_hash->{$name});
        }
        elsif ($line !~ /^# COMMENT: /)
        {
          $pc->die ("Malformed comment.");
        }
        next;
      }
      $first_try = 0;
      $code = SC->new ($sections_array->[-1]);
      redo;
    }
    if ($line eq '-- ')
    {
      $continue_parsing_rest = 0;
      last;
    }
    elsif ($line =~ /^#/)
    {
      if ($line =~ /^# SECTION:/)
      {
        $pc->die ("Section comment in the middle of binary patch.");
      }
      elsif ($line =~ /\s/)
      {
        $pc->die ("Malformed comment in the middle of binary patch.");
      }
    }
    else
    {
      my $word = $self->_get_first_word ();

      if (defined ($word) and $word ne 'literal')
      {
        last;
      }

      $code->push_line (CL::B, $line);
    }
  }
  $diff->set_code ($code);
  $patch->add_diff ($diff);

  unless ($continue_parsing_rest)
  {
    $pc->exhaust_the_file ();
  }

  return $continue_parsing_rest;
}

sub _postprocess_diff
{
  my ($self) = @_;
  my $pc = $self->_get_pc ();
  my $diff = $pc->get_last_diff_or_die ();
  my $patch = $pc->get_patch ();
  my $sections_array = $patch->get_sections_ordered ();
  my $sections_hash = $patch->get_sections_unordered ();
  my $raw_diffs_and_mode = $diff->postprocess ($sections_array, $sections_hash);

  $patch->add_raw_diffs_and_mode ($raw_diffs_and_mode);
}

sub _get_first_word
{
  my ($self) = @_;
  my $pc = $self->_get_pc ();

  if ($pc->get_line () =~ /^(\w+)\s/a)
  {
    return $1;
  }

  return undef;
}

sub _read_next_line_or_die
{
  my ($self) = @_;
  my $pc = $self->_get_pc ();

  unless ($pc->read_next_line ())
  {
    $pc->die ("Unexpected EOF.");
  }
}

sub _cleanup
{
  my ($self) = @_;
  my $pc = $self->_get_pc ();
  my $patch = $pc->get_patch ();

  $self->{'raw_diffs'} = $patch->get_ordered_sectioned_raw_diffs_and_modes ();
  delete ($self->{'p_c'});
}

sub _get_pc
{
  my ($self) = @_;

  return $self->{'p_c'};
}

1;

package main;

my $filename = @ARGV ? $ARGV[0] : 'old-gnome-3.4.patch';
my $p = GP->new ();
my $list_name = 'patches.list';
my $patch_list_file = IO::File->new ($list_name, 'w');

unless (defined ($patch_list_file))
{
  die "Could not load '$list_name' for writing.";
}

$p->process ($filename);
foreach my $entry (@{$p->get_raw_diffs ()})
{
  my $diff = join ('', @{$entry->{'diffs'}});
  my $section = $entry->{'section'};
  my $section_name = $section->get_name ();
  my $patch_name = "$section_name.patch";
  my $file = IO::File->new ($patch_name, 'w');

  $file->binmode (':utf8');
  $file->print ($diff);

  $patch_list_file->binmode (':utf8');
  $patch_list_file->say ($patch_name);
  $patch_list_file->say ($section->get_description ());
  if (exists ($entry->{'modes'}))
  {
    my $modes = $entry->{'modes'};

    $patch_list_file->say (scalar (@{$modes}));
    foreach my $mode (@{$modes})
    {
      $patch_list_file->say ($mode->{'mode'});
      $patch_list_file->say ($mode->{'file'});
    }
  }
  else
  {
    $patch_list_file->say ('0');
  }
}
