#!/usr/bin/perl -w
#
# etext2html.pl : convert plain text to html
# For documentation, run ./etext2html.pl --help

use Getopt::Long;
use Pod::Usage;

use lib "/ebooks/bin";
use Ebook::Convert;
use Ebook::caps;

use English;

init();

# default wrapper for the work
print qq|<div class="frontmatter">\n|;

# Chug thru the text line by line, converting as we go

LINE: while (<>) {
    chomp;

    # Strip any messy CR's from PC users
    s/\r//;

    # Remove Gutenberg header and tail
    if ($gutenberg_text) {

	# (Try to) remove Gutenberg header and tail
	# New style
	next LINE if (/^The Project Gutenberg EBook/i .. /\*\*\* {0,1}START OF THE PROJECT GUTENBERG/);
	next LINE if (/\*\*\* {0,1}END OF THE PROJECT GUTENBERG/ .. /\*END THE SMALL PRINT/);

	# Old style
	next LINE if (/^\**(The ){0,1}Project Gutenberg('s){0,1} /
	           .. /\*END[ *]THE SMALL PRINT/);
	next LINE if /End of (The ){0,1}Project Gutenberg/ .. /^XYZZY/;
	next LINE if /Project Gutenberg Etext/;
    }

    # Ignore blank lines ...
    if (/^\s*$/) {
	next LINE
	    unless ( # ...  we're inside a block quote

		($#block_list >= 0 and $block_list[$#block_list] eq $bq_tag)

	    or # ... blank line is the new para re.

		/$new_para_re/o

	    );
    }

    if ($collapse_multiple_blanks) {        # skip multiple blank lines
	if (/^\s*$/) {
	    next LINE if $blankprev == 1;
	    $blankprev = 1;
	} else {
	    $blankprev = 0;
	}
    }

    # we can delete any lines matching a regular expression (re)
    if ($delete_re and /$delete_re/o) { next }

    # While we expect plain text, we can recognise <pre> sections
    # which we pass thru unchanged
    if (/<pre/i .. /<\/pre>/i) {
	print $_, "\n";
	next LINE;
    }

    # deal with lines broken by hyphenation
    if ($remove_hyphenation) { remove_hyphenation(); }

    # convert HTML reserved chars., &, <, >.
    $_ = Ebook::Convert::reserved($_) if ($convert_reserved);

    # convert plain to curly quotes
    if ($convert_quotes) { $_ = Ebook::Convert::quotes($_); }

    # automatically generate tables
    # note that there must be at least two columns (duh!)
    # assume one line = one row
    if ( $make_tables and /( {2,}|\||\t)/ )
    {
	unless ($#block_list >= 0 and $block_list[$#block_list] eq 'table') {
	    close_block();		# close previous block
	    open_block('table summary=""');
	}
	s/^\s*\|*/<tr><td>/;		# first non-space starts first cell
	s/\|*\s*$/<\/td><\/tr>/;	# terminate row : assume one line = one row
	s/( {2,}|\||\t)/<\/td><td>/g;	# 2 or more blanks or pipe or tab --> cell start
	print $_, "\n";
	next LINE;
    }

    if ($h5_re and /$h5_re/o) { convert_heading('h5'); }

    if ($h4_re and /$h4_re/o) { convert_heading('h4'); }

    if ($h3_re and /$h3_re/o) { 
	close_block();	# close previous block
	convert_heading('h3');
    }

    # change _italic_, /italic/, and *bold* appropriately
    if ($canonical) { Ebook::Convert::canonical(); }

    # change UPPERCASE words to bold, capitalised
    if ($all_caps_bold) { $_ = caps2bold($_); }

    # change UPPERCASE words to italic, lowercase
    if ($all_caps_italic) { $_ = caps2italic($_); }

    # Convert (foot)notes
    if ($note_re) {
	if ( /^$note_re/o ) {
	    # line starting with note re is actual note
	    $nn++;
	    if ($numbered_notes) {
		s{$note_re}{<p class="note" id="fn$nn"><a href="#nr$nn"><sup>$nn</sup></a>};
	    } else {
		s{$note_re}{<p class="note" id="fn$1"><sup>$1</sup>};
	    }
	    close_block();	# close previous block
	    push @block_list, 'p';
	}
	else
	{
	    # process note references
	    while ( /$note_re/o ) { # allow for more than one per line
		$nr++;
		if ($numbered_notes) {
		    s{$note_re}{<a class="fn" href="$notes_path#fn$nr"><sup id="nr$nr">$nr</sup></a>};
		} else {
		    s{$note_re}{<a class="fn" href="$notes_path#fn$1"><sup>$1</sup></a>};
		}
	    }
	}
    }

    # convert tab to 8 spaces
    s/\t/        /g;

    # blockquote lines matching the bq re (default is /^  /)
    if ($bq_re and /$bq_re/o) {
	unless ($#block_list >= 0 and $block_list[$#block_list] eq $bq_tag) {
	    close_block();	# close previous block
	    open_block($bq_tag, $bq_class);
	    print "\n<p>";
	}
    }

    if (s/$new_para_re/<$ptag>/o) {	# paragraph processing
	close_block();
	push @block_list, $ptag;
    }

    # convert character entities
    if ($convert_8bit) {
	s/([\x7F-\xFF])/$char_ent{$1}/g;
    }

    # remove trailing spaces
    s/\s*$//;

    $_ = Ebook::Convert::dashes($_) if $convert_dashes;

    # finished conversions on this line -- print it
    if ($#block_list >= 0 and $block_list[$#block_list] eq $bq_tag) {
	# if it's in a blockquote, replace the indent with ...
	if (/^( +)/) {
	    my $indent = $1;
	    $indent =~ s/$bq_re//;
	    if ($bq_start eq '<p>')
	    # ... an indent class if the line is a <p>aragraph
	    {
		my $i = length($indent);
		s/^ +/<p class="i$i">/;
		print $_, $bq_end, "\n";
	    }
	    else
	    {
	    # ... an appropriate number of nbsp's otherwise
		$indent =~ s/  /&nbsp; /g;
		s/^ +/$indent/;
		print $bq_start, $_, $bq_end, "\n";
	    }
	} else {
	    print $_, "\n";
	}
    }
    else
    {
	print $_, "\n";
    }
}

# close any and all open blocks
while ($#block_list >= 0) { close_block(); }

print qq|</div>
</body>
</html>\n|;

exit;

##----------------------------------------------------------------------

sub open_block {
	# open a new block, printing the HTML tag and saving the tag
	my $tag = shift;
	my $class = shift;
	print "<$tag";
	print qq| class="$class"| if $class;
	print ">";

	push @block_list, $tag;
}

sub close_block {
	# close whatever block is currently open
	my $tag;
	if ($tag = pop @block_list) {
		print "</$tag>\n";
	}
}

sub convert_canonical {

    # a line of just spaces and asterisks -> hr
    if ( s {^\s*\*[ *]+$} {<hr />} ) { return }

    # unnumbered lists - line starts with '* '
    if (/^\s*\* /) {
	unless ($#block_list >= 0 and $block_list[$#block_list] eq 'ul') {
	    close_block();	# close previous block
	    open_block('ul');
	    print "\n";
	}
    }

    # numbered lists - line starts with '# '
    if (/^\s*# /) {
	unless ($#block_list >= 0 and $block_list[$#block_list] eq 'ol') {
	    close_block();	# close previous block
	    open_block('ol');
	    print "\n";
	}
    }

    $_ = Ebook::Convert::canonical($_);
}

sub convert_heading {
    # convert line into a header
    my $tag = shift;
    my $prev = '';
    if ($#block_list >= 0) {
	$prev = $block_list[$#block_list];
    }
    #if ($#block_list >= 0 and $block_list[$#block_list] eq $tag) {
    if ($prev eq $tag) {
	# join consecutive headings with a break
	print $break;
    } else {
	close_block();	# close previous block
	open_block($tag);
    }
    # strips leading and trailing spaces
    s/^\s*(.*)\s*$/$1/;        

    # strip canonicals -- we don't want italic headings
    s/^_(.+)_$/$1/;

    $_ = changeCase($_);
}

sub remove_hyphenation {
    # join lines ending in a hyphen with next line
    while ( /-\s*$/ and (not eof ()) ) {
	s/\s+$//;		# ignore trailing space
	my $next = <>;		# get another line
	chomp $next;
	$next =~ s/^\s+//;	# remove any leading white-space
	$_ .= "$next";		# glue it to the current line
    }
    # now try removing unwanted hyphenations
    $_ = Ebook::Convert::hyphenated($_);
}

##----------------------------------------------------------------------

sub init {

    @block_list = ();

    $break = '<br />';

    $ptag = 'p';

    # set up a table of character entities
    # chars. 128 .. 255 will be converted to '&#nnn;'
    %char_ent = ();
    for (0..255) {
        $char_ent{chr($_)} = sprintf("&#%3u;",$_);
    }

    $nr = 0;                 # footnote reference count
    $nn = 0;                 # footnote count

    $blankprev = 0;          # flag for collapsing mult. blank lines

    # set defaults for all control variables
    $gutenberg_text = 0;
    $new_para_re = '^$';	# ie. blank line
    $bq_re = '^\s{2}';		# ie 2 space indent
    $bq_tag = 'div';
    $bq_class = 'stanza';
    $bq_start = '<p>';
    $bq_end = '';
    $make_tables = 0;
    #$table_re = '(\t|\s{3,})';
    $notes_path = '';
    $note_re = '\[\d+\]';
    $numbered_notes = 1;
    #$numbered_paras = 0;
    $all_caps_bold = 0;
    $all_caps_italic = 0;
    $h3_re = '^\s*(CHAPTER|Chapter|ACT|VOLUME|BOOK|PART |PREFA|PROLOGUE|EPILOGUE|CONCLUSION|INTRODUCT|APPENDIX|INDEX|GLOSSARY|BIBLIOGRAPHY|NOTES)';
    $h4_re = '^\s*[IVXLC]+\.{0,1}\s*$';
    $h5_re = '^\s*_{0,1}[A-Z][^a-z]+$';
    $delete_re = '^\.$';	# ie. a line with a single full stop
    $collapse_multiple_blanks = 1;
    $convert_quotes = 1;
    $canonical = 1;
    $convert_reserved = 1;
    $convert_urls = 1;
    $convert_8bit = 0;
    $convert_dashes = 1;
    $remove_hyphenation = 1;

    &GetOptions(
	"new_para_re:s"		=> \$new_para_re,
	"bq_re:s"		=> \$bq_re,
	"bq_tag:s"		=> \$bq_tag,
	"bq_class:s"		=> \$bq_class,
	"bq_start:s"		=> \$bq_start,
	"bq_end:s"		=> \$bq_end,
	"make_tables!"		=> \$make_tables,
	"all_caps_bold!"	=> \$all_caps_bold,
	"all_caps_italic!"	=> \$all_caps_italic,
	"notes_path:s"		=> \$notes_path,
	"note_re:s"		=> \$note_re,
	"numbered_notes!"	=> \$numbered_notes,
	"h3_re:s"		=> \$h3_re,
	"h4_re:s"		=> \$h4_re,
	"h5_re:s"		=> \$h5_re,
	"delete_re:s"		=> \$delete_re,
	"collapse_multiple_blanks!"	=> \$collapse_multiple_blanks,
	"convert_quotes!"	=> \$convert_quotes,
	"canonical!"		=> \$canonical,
	"convert_reserved!"	=> \$convert_reserved,
	"convert_urls!"		=> \$convert_urls,
	"convert_8bit!"		=> \$convert_8bit,
	"convert_dashes!"	=> \$convert_dashes,
	"remove_hyphenation!"	=> \$remove_hyphenation,
	"gutenberg_text!"	=> \$gutenberg_text,
	"help!"			=> \$help
    );

    pod2usage(-exitval => 0, -verbose => 2) if $help;

}

__END__

=head1 NAME

etext2html.pl

=head1 USAGE

cat source.txt | etext2html.pl [ --help \| [options] ] > text.html

=head1 DESCRIPTION

etext2html.pl is a perl script for converting plain text files to HTML.
Options allow for identification and appropriate tagging of paragraphs,
footnotes, headings, pre-formatted text and other elements of the
source text. See below for more details of available options.

The script will also convert: 

    - HTML "reserved" characters (<, >, and &),
    - eight-bit characters to HTML character entities (&#nnn;)
    - URLs to links
    - hyphens to em and en dashes

=head1 OPTIONS

There are lots of options [defaults shown thus]:

=head2 Paragraphs:

    --new_para_re=string ['^$']
	a regular expression to match the start of a new paragraph
	The default is a blank (empty) line

=head2 Pre-formatting:

    --bq_re=string ['']
	a regular expression to match lines to be 'blockquoted'; useful if
	the text contains pre-formatted lines, e.g. poetry or tables
	Default is '^\s{2}' ie 2-space indent

    --bq_tag=string ['div']
	block-level HTML tag to enclose a 'blockquote' block of lines

    --bq_class=string ['stanza']
	class attribute for the bq_tag

    --bq_start=string ['<p>']
    --bq_end=string ['</p>']
	strings to start and end a blockquoted line

    The default case is to assume poetry, with each line representing a line of verse.

=head2 Footnotes:

    --note_re=string ['\[\d+\]']
	a regular expression identifying (foot)notes
	      '\[(\\d+)\]'	ie. '[n]'
	      '\((\\d+)\*\)'	ie. '(n*)'
	      '(\*)'		ie. '*'

    --[no]numbered_notes [yes]
	set this if you want notes to be numbered sequentially
	otherwise the match to the note re will be used as the anchor

    --notes_path=filepath ['']
	if notes are in a separate file, enter the path to the page
	containing notes 

=head2 Headings:

    --h3_re=string ['$h3_re']
    --h4_re=string ['$h4_re']
    --h5_re=string ['$h4_re']
	regular expressions to match headings (start of sections/chapters/etc)
	e.g.:
	 'PREFACE\|INTRODUCTION\|CHAPTER\|SECTION\|APPENDIX\|CONCLUSION'
	 '^  [IVX]+\.' (ie. roman-numbered lines)
	 '^\\s*[A-Z][^a-z]+$' (ie. all UPPERCASE)
	 '^    ' (ie. a line starting with four spaces)

=head2 Table Processing:

    --[no]make_tables [no]
	set this to have lines matching table_re converted to table rows;
	this is always likely to require some manual cleanup!

=head2 Character Conversion:

    --[no]canonical [yes]
	convert canonical formatting (_word_, *word* or /word/)

    --[no]convert_reserved [yes]
	convert HTML reserved characters (>, <, and &)

    --[no]convert_urls [no]
	convert URLs to HTML links

    --[no]convert_quotes [yes]
	convert quotes to HTML curly quotes

    --[no]convert_8bit [no]
	convert 8bit to HTML character entities (&#nnn;)

    --[no]convert_dashes [yes]
	convert dashes to HTML character entities (&#nnn;)
	single dash converts to em-dash, double to en-dash, line of
	dashes to <hr>

    --[no]remove_hyphenation [yes]
	remove hyphenation (word split at line break)

    --[no]all_caps_bold [no]
	set this if you want words which are all upper-case made bold
	(will also be capitalised, e.g. 'BRUCE' --> 'Bruce')

    --[no]all_caps_italic [no]
	set this if you want words which are all upper-case made italic
	(will also be capitalised, e.g. 'BRUCE' --> 'Bruce')

=head2 General:

    --delete_re=string ['^\.$']
	a re to match lines to be deleted

    --[no]collapse_multiple_blanks [yes]
	set this to skip repeated blank lines

    --[no]gutenberg_text [yes]
	set if source is a Project Gutenberg text and you want the
	header removed

    --help
	if you want to see these instructions.

=head1 VERSION

Version 2015.12.22

=head1 AUTHOR

Steve Thomas <steve.thomas\@internode.on.net>

=head1 LICENCE

This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

