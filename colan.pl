use Getopt::Long::Descriptive;
use Set::IntSpan;
use Data::Dump qw/dump/;
use List::MoreUtils qw/uniq/;
use String::Truncate qw(elide);

use strict;

my ($opt, $usage) = describe_options(
				     "$0 %o <some-arg> - manipulate tab separated files and their headers",
				     [ 'print|p', "print headers"],
				     [ 'excel|X', "print tabular output"],
				     [],
				     [ 'summarize|s', "print column summary"],
				     [ 'examples|x', "print column content examples"],
				     [ 'output|o', "output columns"],
				     [ 'perl|P', "output perl program"],
				     [],
				     [ 'verbose|v',  "print extra stuff"            ],
				     [ 'help|h',       "print usage message and exit" ],
				    );

print($usage->text), exit if $opt->help;


$\ = "\n"; $, = "\t";


my @x; my $j;
my $head = <>; $head =~ s/\s$//;
if ($opt->examples) {
    while (<>) {
	chop; my $i = 0;
	for (split /\t/) { push @{$x[$i++]}, $_ }
	last if $j++ > 30000;
    }
    @x = map { $_ = elide($_, 96); s/(.*),;.+/$1/; $_ } map { join '; ', uniq grep { !/^\s*$/ } @$_ } @x;
}

if ($opt->print) {
    my $i = 0;
    if ($opt->examples) {
	do { printf "%02d. %s (%s)\n", $i++, $_, (shift @x) } for split /\t/, $head;
    } else {
	do { printf "%02d. %s\n", $i++, $_ } for split /\t/, $head;
    }
    exit;
}

if ($opt->excel) {
    my $i = 0;
    if ($opt->examples) {
	do { printf "%02d\t%s\t%s\n", $i++, $_, (shift @x) } for split /\t/, $head;
    } else {
	do { printf "%02d\t%s\n", $i++, $_ } for split /\t/, $head;
    }

    exit;
}


my $l;

if ($opt->summarize) {
    my @fields;
    while (<>) {
	chop;
	my ($field, $name, $keep) = split /\t/;
	next unless $keep;
	push @fields, $field;
    }

    $l = Set::IntSpan->new(\@fields);
    unless ($opt->output || $opt->perl) {
	print $l;
	exit;
    }
    print $l;
}

use File::Slurp qw/read_file/;

if ($opt->output) {
    my $c;
    if (scalar $l->elements) {
	print STDERR $l;
	$c = $l;
    } else {
	if (-e $opt->output) {
	    $c = Set::IntSpan->new(read_file($opt->output));
	} else {
	    $c = Set::IntSpan->new($opt->output);
	}
    }
    my @c = $c->elements;

    while (<>) {
    	chop;
    	my @d = split /\t/;
    	@d = @d[@c];
    	print @d;
    }
}

if ($opt->perl) {
    my $c;
    if (scalar $l->elements) {
	print STDERR $l;
	$c = $l;
    } else {
	if (-e $opt->output) {
	    $c = Set::IntSpan->new(read_file($opt->perl));
	} else {
	    $c = Set::IntSpan->new($opt->perl);
	}
    }
    $c = join ', ', $c->elements;
    print <<EOP
\$\\ = "\\n"; \$, = "\\t"; while (<>) { chop; my \@d = split \/\\t\/; \@d = \@d[$c]; print \@d }
EOP
;


}
