use Getopt::Long::Descriptive;
use Data::Dump qw/dump/;

$\ = "\n"; $, = "\t";

my ($opt, $usage) = describe_options(
				     'fix_columns.pl %o <some-arg>',
				     [ 'edit|e',     "edit in place"                  ],
				     [ 'report|r',   "report on the number of columns "],
				     [ 'auto|A',   "go on autopilot"],
				     [],
				     [ 'separator|s=s',            "field separator", { default => "\t" } ],
				     [ 'sampling_percentage|p=i',  "percentage of rows sampled"            ],
				     [ 'skip_rows|k=i',            "number of rows to skip"            ],
				     [ 'fix|f=i',                  "number of columns to force"            ],
				     [ 'verbose|v',                  "verbose"            ],
				     [ 'help|h',                   "print usage message and exit" ],
				    );

print($usage->text), exit if $opt->help;

my $sep = $opt->separator || "\t";
my $fix = $opt->fix;

if ($opt->auto) {
    open FILE, $ARGV[0];
    my $c;
    while (<FILE>) {
	$l->{$_}++ for grep { !/\w| / } split '', $_;
	last if $c++ > 100;
    };

    $sep = [ sort { $l->{$b} <=> $l->{$a} } keys %$l ]->[0];
    printf STDERR "using separator \"%s\"\n", $sep
	if $opt->verbose;
    close FILE;
}

if ($opt->report || $opt->auto) {
    my $t;
    open FILE, $ARGV[0];
    while (<FILE>) {
	chop; 
	my @d = split $sep;
	$t->{scalar @d}++;
    }
    close FILE;
    my @n = sort { $t->{$b} <=> $t->{$a} } keys %$t;
    $fix = [ sort { $t->{$b} <=> $t->{$a} } keys %$t ]->[0];

    unless ($opt->auto && $opt->fix) {
	print $_, $t->{$_} for @n;
	printf "best choice is %d with %d records\n", $fix, $t->{$fix}; 
    }
    # $fix = $n[0];
}

use File::Copy qw/move/;
if ($opt->fix || $opt->edit) { 
    $fix = $opt->fix unless $opt->auto;
    $fix--;  # from column count to max index
    # print STDERR $fix; exit;
    if ($opt->edit) {
	my $file = $ARGV[0];
	my $backup = "$file~";
	printf STDERR "backing up to file \"%s\"\n", $backup
	    if $opt->verbose;
	move ($file, $backup); 
	open FILE, '<', $backup;
	open STDOUT, '>', $file;
    } else {
	my $file = $ARGV[0];
	open FILE, $file;
    }


    my $k = $opt->skip_rows;
    while (<FILE>) {
	next unless $. >= $k;
	chop;
	s/\t/ /g unless $sep eq "\t";
	s/\s+$//;
	my @d = split $sep, $_;
	s/\\\"|\"//g for @d;
	$#d = $fix;
	print @d;
    }
}
