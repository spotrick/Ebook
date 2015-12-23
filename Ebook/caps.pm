package Ebook::caps;

require Exporter;
@ISA = Exporter;
@EXPORT = qw( caps2italic caps2bold changeCase );

$Ebook::caps::VERSION = "2015.12.22";
sub Version { $VERSION; }

=head1 NAME

Ebook::caps.pm

=head1 USAGE

    use Ebook::caps;

    $string = caps2italic ($string);
    $string = caps2bold ($string);
    $string = changeCase ($string);

All these functions also work in an array context.

=head1 DESCRIPTION

This package contains subroutines which perform various
conversions on plain text to XHTML, according to commonly accepted
standards.

=head2 caps2italic and caps2bold

In transcriptions of books to plain text, it is common to code italic
text as all UPPER CASE.  Given a string (or an array of strings),
these routines convert any run(s) of UPPER CASE into lower case, and
enclose the converted string in an html em (or strong) tag.

An UPPER CASE run of characters begins on a word boundary with A-Z, and
ends at the next lower case letter, full stop or A-Z on a word boundary
(end).

E.g.

    AARDVAARK => <em>aardvaark</em>
    My HOVERCRAFT is full of EELS!
    => My <em>hovercraft</em> is full of <em>eels</em>!

=cut


# set up various values -- these are for HTML. They are defined here
# to make it easy to change for other markup schema, such as TEI.

use lib "/ebooks/bin";
use Ebook::stopwords;

$strong  = 'strong';
$emph    = 'em';

my $lcwords = join '|', qw(
	A AN AND ARE AS AT BUT BY FROM FOR HAS HAD HAVE HE SHE
	HIS HER HIM NOT BE
	IN INTO IS IT ITS OF OFF ON ONTO OR THAN THAT THE THEN THIS TO
	UP UPTO WAS WHAT WHEN WHENCE WHERE WHICH WITH WHO WHY
    );

sub caps2italic {
    return unless defined wantarray;  # void context, do nothing
    my @params = @_;
    for (@params) {

	s/\b([A-Z][^a-z.()!?]+[A-Z]\b)/<${emph}>\L$1\E<\/${emph}>/g;

    }
    return wantarray ? @params : $params[0];
}

sub caps2bold {
    return unless defined wantarray;  # void context, do nothing
    my @params = @_;
    for (@params) {

	s/\b([A-Z][^a-z.]+[A-Z]\b)/<${strong}>\L$1\E<\/${strong}>/g;

    }
    return wantarray ? @params : $params[0];
}

sub changeCase {
    return unless defined wantarray;  # void context, do nothing

    my @params = @_;
    for (my $i = 0; $i le $#params; $i++ ) {

	my @words = split ' ', $params[$i];		# split on space(s)
	my @new = ();
	my $m = 0;					# flag for sentence start

	foreach my $word (@words) {

	    if ( $m and isStopword($word) ) {		# lower-case words
		push @new, "\L$word\E";

	    } elsif ($word =~ /^[IVXLC.]+\.{0,1}$/) {	# Roman numerals -> lower
		push @new, "\L$word\E";

	    } elsif ($word =~ /^S$/) {			# apostrophe-s
		push @new, "\L$word\E";

	    } else {					# default: capitalise
		push @new, "\u\L$word\E";
	    }

	    $m++;
	    $m = 0 if /\.$/;				# period starts a new sentence
	}

	$params[$i] =  join ' ', @new;

    }
    return wantarray ? @params : $params[0];
}

1;

__END__

=head1 AUTHOR

Steve Thomas 

=head1 VERSION

This is version 2015.12.22

=head1 LICENCE

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

