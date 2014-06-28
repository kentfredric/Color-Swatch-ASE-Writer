use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Color::Swatch::ASE::Writer;

our $VERSION = '0.001000';

# ABSTRACT: Low level ASE ( Adobe Swatch Exchange ) file Writer.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use warnings::pedantic;







use Encode qw(encode);

## no critic (ValuesAndExpressions::ProhibitEscapedCharacters)
my $BLOCK_GROUP_START = "\x{c0}\x{01}";
my $BLOCK_GROUP_END   = "\x{c0}\x{02}";
my $BLOCK_COLOR       = "\x{00}\x{01}";
my $UTF16NULL         = "\x{00}\x{00}";
## use critic

sub write_string {
  my ( $class, $struct ) = @_;
  my $out = '';
  $class->_write_signature( \$out, $struct->{signature} );
  $class->_write_version( \$out, @{ $struct->{version} || [ 1, 0 ] } );
  my @blocks = @{ $struct->{blocks} };

  $class->_write_num_blocks( \$out, scalar @blocks );

  for my $block ( 0 .. $#blocks ) {
    $class->_write_block( \$out, $block, $blocks[$block] );
  }

  return $out;
}







sub write_filehandle {
  my ( $class, $filehandle, $structure ) = @_;
  return print {$filehandle} $class->write_string($structure);
}





sub write_file {
  my ( $class, $filename, $structure ) = @_;
  require Path::Tiny;
  return Path::Tiny::path($filename)->spew_raw( $class->write_string($structure) );
}

sub _write_signature {
  my ( $self, $string, $signature ) = @_;
  $signature = 'ASEF' if not defined $signature;
  if ( 'ASEF' ne $signature ) {
    die "Signature must be ASEF";
  }
  ${$string} .= $signature;
  return;
}

sub _write_bytes {
  my ( $self, $string, $length, $bytes, $format ) = @_;
  my @bytes;
  if ( ref $bytes ) {
    @bytes = @{$bytes};
  }
  else {
    @bytes = ($bytes);
  }
  my $append = '';
  if ( not defined $format ) {
    $append .= $_ for @bytes;
  }
  else {
    $append = pack $format, @bytes;
  }
  if ( ( length $append ) ne $length ) {
    warn 'Pack length did not match expected pack length!';
  }
  $$string .= $append;
  return;
}

sub _write_version {
  my ( $self, $string, $version_major, $version_minor ) = @_;
  $version_major = 1 if not defined $version_major;
  $version_minor = 0 if not defined $version_minor;
  $self->_write_bytes( $string, 4, [ $version_major, $version_minor ], q[nn] );
  return;
}

sub _write_num_blocks {
  my ( $self, $string, $num_blocks ) = @_;
  $self->_write_bytes( $string, 4, [$num_blocks], q[N] );
  return;
}

sub _write_block_group {
  my ( $self, $string, $group, $default ) = @_;
  $group = $default if not defined $group;
  $self->_write_bytes( $string, 2, [$group], q[n] );
  return;
}

sub _write_block_label {
  my ( $self, $string, $label ) = @_;
  $label = '' if not defined $label;
  my $label_chars = encode( $label, 'UTF16-BE', Encode::FB_CROAK );
  $label_chars .= $UTF16NULL;
  ${$string}   .= $label_chars;
  return;
}

sub _write_group_start {
  my ( $self, $string, $block_id, $block ) = @_;
  $self->_write_block_group( $string, $block->{group}, 13 );
  $self->_write_block_label( $string, $block->{label} );
}

sub _write_group_end {
  my ( $self, $string, $block_id, $block ) = @_;
  $$string .= q[];
  return;
}

my $color_table = {
  q[RGB ] => '_write_rgb',
  q[LAB ] => '_write_lab',
  q[CMYK] => '_write_cymk',
  q[Gray] => '_write_gray',
};

sub _write_color_model {
  my ( $self, $string, $model ) = @_;
  die "Color model not definde"   if not defined $model;
  die "Uknown color model $model" if not exists $color_table->{$model};
  $self->_write_bytes( $string, 4, [$model] );
  return;
}

sub _write_rgb {
  my ( $self, $string, $red, $green, $blue ) = @_;
  $self->_write_bytes( $string, 12, [ $red, $green, $blue ], q[f>f>f>] );
  return;
}

sub _write_lab {
  my ( $self, $string, $lightness, $alpha, $beta ) = @_;
  $self->_write_bytes( $string, 12, [ $lightness, $alpha, $beta ], q[f>f>f>] );
  return;
}

sub _write_cmyk {
  my ( $self, $string, $cyan, $magenta, $yellow, $key ) = @_;
  $self->_write_bytes( $string, 16, [ $cyan, $magenta, $yellow, $key ], q[f>f>f>f>] );
  return;
}

sub _write_gray {
  my ( $self, $string, $gray ) = @_;
  $self->_write_bytes( $string, 4, [$gray], q[f>] );
  return;
}

sub _write_color_type {
  my ( $self, $string, $type ) = @_;
  $type = 2 if not defined $type;
  $self->_write_bytes( $string, 2, [$type], q[n] );
  return;
}

sub _write_color {
  my ( $self, $string, $block_id, $block ) = @_;
  $self->_write_block_group( $string, $block->{group}, 1 );
  $self->_write_block_label( $string, $block->{label} );
  $self->_write_color_model( $string, $block->{model} );
  my $color_writer = $self->can( $color_table->{ $block->{model} } );
  $self->$color_writer( $string, @{ $block->{values} } );
  $self->_write_color_type( $string, $block->{color_type} );
}

sub _write_block_payload {
  my ( $self, $string, $block_id, $block_body ) = @_;
  $self->_write_bytes( $string, 2, [$block_id] );
  $self->_write_bytes( $string, 4, [ length ${$block_body} ], q[N] );
  ${$string} .= ${$block_body};
  return;
}

sub _write_block {
  my ( $self, $string, $block_id, $block ) = @_;

  my $block_body = '';
  if ( $block->{type} eq 'group_start' ) {
    $self->_write_group_start( \$block_body, $block_id, $block );
    $self->_write_block_payload( \$string, $BLOCK_GROUP_START, \$block_body );
    return;
  }
  if ( $block->{type} eq 'group_end' ) {
    $self->_write_group_end( \$block_body, $block_id, $block );
    $self->_write_block_payload( \$string, $BLOCK_GROUP_END, \$block_body );
    return;
  }
  if ( $block->{type} eq 'color' ) {
    $self->_write_color( \$block_body, $block_id, $block );
    $self->_write_block_payload( \$string, $BLOCK_COLOR, \$block_body );
    return;
  }
  die "Unknown block type " . $block->{type};
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Color::Swatch::ASE::Writer - Low level ASE ( Adobe Swatch Exchange ) file Writer.

=head1 VERSION

version 0.001000

=head1 METHODS

=head2 C<write_string>

  my $string = Color::Swatch::ASE::Writer->write_string($structure);

=head2 C<write_filehandle>

  Color::Swatch::ASE::Writer->write_filehandle($fh, $structure);

=head2 C<write_file>

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
