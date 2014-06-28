use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Color::Swatch::ASE::Writer;

our $VERSION = '0.001000';

# ABSTRACT: Low level ASE ( Adobe Swatch Exchange ) file Writer.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use if $ENV{AUTHOR_TESTING} => 'warnings::pedantic';







sub write_string {
  my ( $class, $struct ) = @_;

}







sub write_filehandle {
  my ( $class, $filehandle, $structure ) = @_;

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

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
