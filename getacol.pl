use Getopt::Long::Descriptive;
use List::MoreUtils qw/indexes/;
use List::Util qw/max/;
use IO::Uncompress::Unzip qw(unzip $UnzipError) ;
use IO::File;
use Data::Dump qw/dump/;
use JSON;

use strict;
use warnings; no warnings qw/uninitialized/;
 
$\ = "\n"; $, = "\t";

my ($opt, $usage) =
    describe_options(
		     $0 . ' %o get a column from input',
		     [ 'regex|r:s',      "column regex filter" ],
		     [ 'grep|g:s',       "grep regex filter" ],
		     [ 'add_data|D=s%',  "additional data" ],
		     [ 'filename|n',  "add file name" ],
		     [ 'separator|S',  "print separator and exit" ],
		     [],
		     [ 'fields|f',      "print fields and exit" ],
		     [ 'header|H',      "print header" ],
		     [ 'no-fields|F',      "do not print fields" ],
		     [ 'conf|C',      "print config as json and exit" ],
		     [],
		     [ 'verbose|v',  "print extra stuff"            ],
		     [ 'version|V',  "print version and exit" ],
		     [ 'help|h',       "print usage message and exit" ],

		    );

print($usage->text), exit if $opt->help;
printf("script is %0.2f days old\n", int(-M $0)), exit if $opt->version;

if ($opt->conf) {
    my $opt = { %$opt };
    delete $opt->{conf};
    print to_json({ %$opt }, { pretty => 1}) ; exit;
}
$\ = "\n"; $, = "\t";
# -----------------------------------------------
# opening the file
# -----------------------------------------------

printf STDERR "processing file %s\n" if $opt->verbose;
my $file = $ARGV[0];

my $fh = IO::File->new;

for ($ARGV[0]) {
    /zip$/ && do {
	my $file = $ARGV[0];
	open ZIP, "unzip -qc \"$file\" | ";
	$fh->fdopen(fileno(ZIP),"r");
	last;
    };
    /^$/ && do {
	$fh->fdopen(fileno(STDIN),"r");
	last;
    };
    $fh->open($_,  '<')
}

# -----------------------------------------------
# initialization
# -----------------------------------------------

my $head = $fh->getline(); chomp $head; $head =~ s/\W+$//;
my %freq;

# -------------- separator ---------------------- 
for (grep { /[^a-z0-9 ]/i } split '', $head) { $freq{$_}++ };

my $sep = (sort { $freq{$b} <=> $freq{$a} } keys %freq)[0];

do { 
    printf "\"%s\"\n", $sep; 
    exit
} if $opt->separator;

# ---------------- head ------------------------- 
my @head = split $sep, $head;
# print @head; exit;
 
my $re = $opt->regex;   $re   = qr/$re/i;
my $grep = $opt->grep;  $grep = qr/$grep/i;

# -----------------------------------------------
# headers
# -----------------------------------------------
if ($opt->fields) { print for grep { /$re/ } @head; exit }

if ($opt->header) {
    my $l = max map { length } @head;
    my $i;
    for (@head) {
	printf "%3d. %-${l}s %s\n", $i++, $_, /$re/ ? 'x' : '-';
    }
    exit;
}

my @addfields;
my @addvals;

if ($opt->filename) {
    push @addfields, 'source';
    push @addvals, $ARGV[0];
}

# -----------------------------------------------
# the real thing
# -----------------------------------------------

my @fields = indexes { /$re/ } @head;
# print @fields; exit;
print (@head[@fields], @addfields) unless $opt->no_fields;
if ($opt->grep) {
    while ($_ = $fh->getline()) {
	chop; s/\W+$//;
	s/\t/ /g unless $sep eq "\t";
	next unless /$grep/;
	print @{[split $sep, $_]}[@fields], @addvals;
    }
} else {
    while ($_ = $fh->getline()) {
	chop; s/\W+$//;
	s/\t/ /g unless $sep eq "\t";
	print @{[split $sep, $_]}[@fields], @addvals;
    }
}
