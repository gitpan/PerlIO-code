package PerlIO::code;

use warnings;
use strict;

our $VERSION = '0.01';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=head1 NAME

PerlIO::code - Makes a simple I/O filter

=head1 VERSION

This document describes PerlIO::code version 0.01

=head1 SYNOPSIS

	use PerlIO::code; # need to say explicitly

	# make an input filter
	open my $in, '<', sub{ uc scalar <> };
	print while <$in>;

	# make an output filter
	open my $out, '>', sub{ print uc shift };
	print $out while <>;

=head1 DESCRIPTION

C<PerlIO::code> helps to make an I/O filter. It is easier than C<tie>, but
provides very limited functions. All it can do is to C<readline> and C<print>.

=head1 NOTES

=over 4

=item *

For some reason, the actual layer name of C<PerlIO::code> is C<:Code>, not C<:code>.

=item *

C<PerlIO::code> is slower than the C<tie> interface.

=item *

C<< open my $in, '<', sub{ "foo" }; my $s = <$in>; >> makes an endless loop, because
the internal C<readline> routine reads C<$in> on until reaching EOF.

=back

=head1 CONFIGURATION AND ENVIRONMENT

No configuration files or environment variables.

=head1 DEPENDENCIES

Perl 5.8.1 or later, and a C compiler.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-perlio-code@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<Tie::Handle>.

L<PerlIO::via>.

L<PerlIO>.

=head1 AUTHOR

Goro Fuji C<< <gfuji (at) cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Goro Fuji C<< <gfuji (at) cpan.org> >>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
