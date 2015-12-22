package Ebook::Convert;

$Ebook::Convert::VERSION = "2015.12.22";
sub Version { $VERSION; }

=head1 NAME

Ebook::Convert.pm

=head1 USAGE

    use Ebook::Convert;

    $string = Ebook::Convert::dashes ($string);
    $string = Ebook::Convert::quotes ($string);
    $string = Ebook::Convert::canonical ($string);
    $string = Ebook::Convert::reserved ($string);
    $string = Ebook::Convert::hyphenated ($string);

All these functions also work in an array context.

=head1 DESCRIPTION

This package contains a number of subroutines which perform various
conversions on plain text to XHTML, according to commonly accepted
standards.

=cut

# set up various values -- these are for HTML. They are defined here
# to make it easy to change for other markup schema, such as TEI.

$strong  = 'strong';
$emph    = 'em';

$hr      = '<hr />';

$mdash   = '—';	# U+2013 &#8212;
$ndash   = '–';	# U+2014 &#8211;

$lsquo   = '‘';	# U+2018 &#8216;
$rsquo   = '’';	# U+2019 &#8217;
$apos    = '’';	# U+2019 &#8217;
$ldquo   = '“';	# U+201C &#8220;
$rdquo   = '”';	# U+201D &#8221;

=head2 reserved

Converts the HTML reserved characters &, < and > to character entities.

=cut

sub reserved {
    return unless defined wantarray;  # void context, do nothing
    my @parms = @_;
    for (@parms) {

	s/&/\&amp;/g;
	s/</\&lt;/g;
	s/>/\&gt;/g;

    }
    return wantarray ? @parms : $parms[0];
}

=head2 dashes

Converts dashes into appropriate HTML entities.

    # a line of just dashes --> HR
    # convert double hyphen to single em-dash
    # convert hyphen+space between words to em-dashes
    # convert single hyphen between numbers to en-dash
    # convert single hyphen between Capitalised words to en-dash
    # any other hyphen is just a hyphen

=cut

sub dashes {
    return unless defined wantarray;  # void context, do nothing
    my @parms = @_;
    for (@parms) {

	# a line of just dashes --> HR
	s/^\s*-+\s*$/${hr}/;	

	# convert double hyphen to single em-dash
	s/--/${mdash}/g;

	# ... and convert the last if we had an odd number of -'s
	s/${mdash}-/${mdash}${mdash}/g;

	# convert ':-' 
	s/:-/:${mdash}/g;

	# convert hyphen+space between words to em-dashes
	# i.e. "word -" or "word- "
	s/\s-/ ${mdash}/g;
	s/-\s/${mdash} /g;

	# convert single hyphen between numbers to en-dash
	s/(\d+)-(\d+)/$1${ndash}$2/g;

	# convert single hyphen between Capitalised words to en-dash
	s/([A-Z][a-z]+)-([A-Z][a-z]+)/$1${ndash}$2/g;

	# any other hyphen is just a hyphen

	# ... and we need to repair any HTML comments:
	s/<!${mdash}/<!--/g;
	s/${mdash}>/-->/g;

    }
    return wantarray ? @parms : $parms[0];
}

=head2 quotes

Convert single (') and double (") quotes to appropriate HTML entities
for "smart" or "curly" quotes, and apostrophes.

Note that we use the right single quote for apostrophe, rather than
&apos;, since that is just a single ascii quote.

Also checks for single quote used in common examples of "vernacular"
language, e.g. 'im for him, 'ouse for house, etc.

=cut

sub quotes {
    return unless defined wantarray;  # void context, do nothing
    my @parms = @_;
    for (@parms) {

	# doubled single-quote --> double-quote
	s/``/${ldquo}/gs;
	s/''/"/gs;

	# back-tick is always left-single-quote
	s/`/${lsquo}/gs;

	# Assume quotes before and after tagging
	s/>'/>${lsquo}/gs;
	s/'</${rsquo}</gs;

	# ... and start/end of lines
	s/^'/${lsquo}/;
	s/'$/${rsquo}/;

	# single quote inside word is (probably) an apostrophe
	s/\b'\b/${apos}/gs;

	# Assume quotes at start and end of words
	s/'\b/${lsquo}/gs;
	s/\b'/${rsquo}/gs;

	# ... and finally assume after/before space
	s/ '/ ${lsquo}/gs;
	s/' /${rsquo} /gs;

	# Fix special cases where it's really an apostrophe:
	# archaic forms ...
	s/${lsquo}(t\b|tis\b|twas\b|twere\b|twill\b|twould\b|twixt)/${apos}$1/igs;
	# "cockney"isms ...
	s/${lsquo}(e\b|em\b|ere\b|im\b|un\b)/${apos}$1/gs;
	s/${lsquo}(eart\b|ouse\b)/${apos}$1/gs;
	# broken 
	s/ ${lsquo}(ve\b|ll\b|re\b)/${apos}$1/gs;

	# Final check for ' followed by punctuation ...
	s/'(?=[,.:;!?"&])/${rsquo}/gs;

	# ... or following punctuation
	s/([,.!?])'/$1${rsquo}/gs;

	# Now do more or less the same with "
	s/>"/>${ldquo}/gs;
	s/"</${rdquo}</gs;

	s/^"/${ldquo}/;
	s/"$/${rdquo}/;

	s/"\b/${ldquo}/gs;
	s/\b"/${rdquo}/gs;

	s/ "/ ${ldquo}/gs;
	s/" /${rdquo} /gs;

	s/"(?=[,.:;'&])/${rdquo}/gs;
	s/([,.!?])"/$1${rdquo}/gs;

	# Any ' left is assumed to be right-single-quote
	s/'/${rsquo}/gs;

	# now, just in case the string contained HTML tagging, we need
	# to repair any attribute quotes:

	s/${rdquo} (.*?)=${ldquo}/: $1="/gs;
	s/=${ldquo}/="/gs;
	s/${rdquo}>/">/gs;
	s/^${ldquo}([^<]+>)/"$1/gs;

    }
    return wantarray ? @parms : $parms[0];
}

=head2 canonical

Converts "canonical" text formatting to HTML formatting, viz.:

    _word_ => emphasis (italic)
    /word/ => emphasis (italic)
    *word* => bold

and also converts lines starting with '*' or '#' to list items.

=cut

sub canonical {
    return unless defined wantarray;  # void context, do nothing
    my @parms = @_;
    for (@parms) {

	# First we protect anything we don't want to change ...
	# URLs:
	s/http:\/\//http:&#x2f;&#x2f;/g;
	# Slash inside a word:
	s!\b/\b!&#x2f;!g;

	# /word/ => emphasis (italic)
	# note that '/' is not part of Perl's list of word characters,
	# so '/\b' is a slash at the start of a word, etc.

	s#/\b#<${emph}>#g;

	# any other '/' marks the end of emphasis ...
	s#/#</${emph}>#g;

	#s#\b/#</${emph}>#g;
	#s#\s/#<${emph}>#g;
	#s#/\s#</${emph}>#g;
	#s#^/#<${emph}>#g;
	#s#/$#</${emph}>#g;

	# _word_ => emphasis (italic)
	# note that '_' is part of Perl's list of 'word' characters,
	# so '_/b' is an underscore at the END of a word, etc/

	s#\(_(.*?)_\)#(<em>$1</em>)#g;
	s#\(_#(<${emph}>#g;
	s#^_#<${emph}>#g;
	s# _# <${emph}>#g;

	s#_\b#</${emph}>#g;
	s#\b_#<${emph}>#g;
	s#\s_#<${emph}>#g;
	s#_\s#</${emph}>#g;
	s#^_#<${emph}>#g;
	s#_$#</${emph}>#g;
	s#_#</${emph}>#g;

	# remove any redundant tags ...
	s#</${emph}> <${emph}># #g;

	# a line of asterisks is just a transition
	#s/^(\s*\*)+$/<div class="section center">$&<\/div>/;
	s/^(\s*\*)+$/<div class="transition"><\/div>/;

	# unnumbered lists - line starts with '* '
	s/^\* /<li>/;

	# numbered lists - line starts with '# '
	s/^\# /<li>/;

	# *word* => bold

	s#\*\b#<${strong}>#g;
	s#\b\*#</${strong}>#g;
	s#\*#</${strong}>#g;

	# restore protected characters ...
	s/&#x2f;/\//g;

    }
    return wantarray ? @parms : $parms[0];
}

=head2 hyphenated

Removes hyphenation at line endings.

N.B. Requires that lines ending in hyphens have been concatenated with the next line

There is much room for improvement here!

=cut

sub hyphenated {
    return unless defined wantarray;  # void context, do nothing
    my @parms = @_;
    for (@parms) {

	# contract common hyphenated forms

	s/to-day/today/g;
	s/to-morrow/tomorrow/g;
	s/\b(ab|ac|ad|al|am|be|co|com|con|de|des|dis|em|en|ex|im|in|op|par|per|pre|pro|pur|re|rem|ren|res|trans|un)-/$1/g;
	s/-(able|ance|dence|ed|ence|ent|ing|ise|ize|ment|ness|ous|self|sion|tion|tude|ture|tures)\b/$1/g;

	s/-inlaw\b/-in-law/g;

	# anything else retains the hyphen

    }
    return wantarray ? @parms : $parms[0];
}

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

