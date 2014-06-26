use Text::CSV_XS;
use Data::Dump qw/dump/;

use Getopt::Long::Descriptive;

$\ = ",\n"; $, = "\t";

my ($opt, $usage) =
    describe_options(
		     'xltoperl %o <some-arg>',
		     [ 'ssconvert|s=s', "ssconvert locations"      ],
		     [ 'columns|c',     "print column names and exit" ],
		     [ 'debug|d',       "debug output (only print CSV)" ],
		     [ 'schema|q',      "output column names as first element" ],
		     [],
		     [ 'verbose|v',  "print extra stuff"            ],
		     [ 'help',       "print usage message and exit" ],
		    );

print($usage->text), exit if $opt->help;

my $ssconvert = 'ssconvert';
my $file = $ARGV[0];

my $t = qx|$ssconvert -T Gnumeric_stf:stf_csv "$file" fd://1 2> /dev/null|;

if ($opt->debug) { print $t; exit };
@data = split /\n/, $t;


my $csv = Text::CSV_XS->new()  # should set binary attribute.
    or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

$csv->parse($data[0]);
my @cols = $csv->fields();
for (@cols) { 
    my $c = $_;

    s/^\s|\s+$//g;
    s/\#/nr/g;
    s/%/perc/g;
    s/\s+|\W+/_/g;
    s/^[0-9]//;
    s/^_|_$//g;
    s/_+/_/g;
    s/\(|\)//g;

    $_ = lc;
    if ($opt->columns) { print $c, $_ }
}
exit if $opt->columns;

my $r;

push @out, \@cols if $opt->schema;

for (1..$#data) {
    next unless $csv->parse($data[$_]);
    my $r;
    @{$r}{@cols} = $csv->fields();
    push @out, $r;
    # print dump $r;
}

print dump \@out;
