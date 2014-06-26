use strict;

use Text::SimpleTable;
use Getopt::Long::Descriptive;
use List::Util qw/sum/;
use Data::Dump qw/dump/;

$\ = "\n"; $, = "\t";

my ($opt, $usage) = 
    describe_options(
		     'tabdisplay.pl %o <some-arg> - display data as text table',
 		     [ 'lengths|l=s', "field lengths (comma sep. list) " ],
 		     [ 'align|a=s', "alignments (comma sep. list) " ],
		     [ 'default_length|L=i', "default field length" ],
		     [ 'split|S=s', "regex to split fields with newlines" ],
		     [],
		     [ 'check|c', 'check fields and lengths' ], 
		     [ 'verbose|v',  "print extra stuff"            ],		     
		     [ 'debug|D',  "print extra stuff"            ],

		     [ 'help|h',       "print usage message and exit" ],
		    );

print($usage->text), exit if $opt->help;

my @lengths = split ',', $opt->lengths;
my @align   = split ',', $opt->align;

my @l = @lengths;
for (@align) { if (/r/i) { $_ = '%' . (shift @l) . 'd' } else { $_ = '%s'; shift @l } }

if ($opt->debug) {
print @lengths;
print @align; exit;
}

my @h = map { chomp; [ (shift @lengths || $opt->default_length) , $_ ] } split /\t/, <>;


if ($opt->check) {
    print ($_->[1], $_->[0]) for @h;
    print "Total: " . sum map { $_->[0] } @h; exit;
}


my $t3 = Text::SimpleTable->new(@h);
my $s = $opt->split;
while (<>) {
    chop;
    my @row = split /\t/;
    if (defined $s) { for (@row) { s/$s/\n/g } }


    if (@align) { my @a = @align; for (@row) { $_ = sprintf ((shift @a), $_) } } 
    $t3->row(@row);
}
		  

print $t3->draw;
