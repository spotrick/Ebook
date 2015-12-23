package Ebook::stopwords;
require Exporter;
@ISA = Exporter;
@EXPORT_OK = qw( @stopwords );
@EXPORT = qw( isStopword );

# really lc words -- needs a name change!

sub isStopword {
    my $word = shift;
    $word =~ tr [A-Za-z] []csd;
    if (grep /$word/i, @stopwords) {
	return 1;
    } else {
	return 0;
    }
}

# Verbs be, have, do, work 

# Nouns man, town, music 

# Adjectives a, the, 69, big 

# Adverbs loudly, well, often 

# Pronouns you, ours, some 

# Prepositions at, in, on, from 

# Conjunctions and, but, though 

# Interjections ah, dear, er, um 


@stopwords = qw(

a an the
is are was were
isn't aren't wasn't weren't
not 

and but or nor for yet so 

before during after when while
once since
till until

although as because how if than though whether
therefore 
then now never

here there where
anywhere everywhere nowhere somewhere elsewhere

in into 

can cannot can't could couldn't
will won't would wouldn't
shall shan't should shouldn't
do does doesn't done did didn't


me mine my myself
you your yours
he him himself his
she her herself hers
it its itself
we us our ours ourselves
they their them themselves 
this that these those
who whose


either neither 
little less least 
few fewer fewest 
what whatever which whichever 
both half 
several 
enough 


good better best
bad worse worst

high higher highest
low lower lowest

large largely larger largest
big bigger biggest
great greater greatest
small smaller smallest

long longer longest
short shorter shortest

far further furthest
near nearer nearest
close closer closest
up down 

new newer newest old older oldest young younger youngest

first last
soon sooner
late later latest
mostly
much many more most 

all any anybody anyone anything
each every everybody everyone everything
no non none nobody noone nothing
some somebody someone something


above below

about across again against almost alone along already
also always among another

area areas around at away
ask asked asking asks

back backed backing backs
became become becomes been
began behind
be being beings
between by

came
case cases
certain certainly
clear clearly come

differ different differently
downed downing
downs 

early 
end ended ending ends
even evenly
ever

face faces fact facts
felt find finds
from full fully
furthered furthering furthers

general generally
go going goods
group grouped grouping groups

get gets got gave give given gives
had has have having

however

important 
interest interested interesting interests

just

keep keeps kind
knew know known knows

let lets
like likely

made make making man may
member members men might
must

necessary need needed needing needs
next
number numbers

of off often on only
open opened opening opens

order ordered ordering orders
other others out over

part parted parting parts
per perhaps place places
point pointed pointing points
possible
present presents presented presenting
problem problems
put puts

quite

rather really right room rooms

said same saw say says
second seconds
see seem seemed seeming seems sees
show showed showing shows
side sides 
state states
still such sure

take taken
thing things think thinks
thought thoughts
through thus to today together too took toward
turn turned turning turns

one two three four five six seven eight nine ten 

under upon use used uses

very

want wanted wanting wants
way ways well wells went
whole why 
with within without
work worked working works 
year years 

    );

__END__

=head1 NAME

Ebook::stopwords.pm

=head1 USAGE

    use Ebook::stopwords;

    if ( isStopword( $word ) { ...

=head1 DESCRIPTION

A list of "stop" words or common words, and a function to test for them.

=head1 REFERENCES

http://wordlist.sourceforge.net/
http://www.dcs.shef.ac.uk/research/ilash/Moby/

=head1 AUTHOR

Steve Thomas

=head1 VERSION

This is version 2015-12-23

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

