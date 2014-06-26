use Text::CSV_XS;
use Try::Tiny;
use Data::Dump qw/dump/;
use Set::IntSpan;
use Getopt::Long::Descriptive;
use Path::Class;
use Fcntl;

use strict; use warnings;

$\ = "\n"; $, = "\t";

my ($opt, $usage) =
    describe_options(
		     'csvtotab %o <some-arg>',
		     [ 'skip_rows|k=i',            "number of rows to skip"            ],
		     [ 'columns|c=s',            "columns to output"            ],
		     [ 'print_header|H',            "print header"            ],
		     [],
		     [ 'separator|s=s',  "field separator", { default => "\t" } ],
		     [ 'tab_file|T',            "treat input as tab-separated file"            ],
		     [ 'smart_file|S',            "output to smart named file"            ],
		     [ 'fields_file|F=s',            "fields list file"            ],
		     [ 'check_columns|C',            "check columns and exit"            ],
		     [],
		     [ 'verbose|v',  "print extra stuff"            ],
		     [ 'help',       "print usage message and exit" ],
		    );

print($usage->text), exit if $opt->help;

my @cols = Set::IntSpan->new($opt->columns)->elements;
# print join ', ', @cols; exit;

my $file = $ARGV[0];

my $s = $opt->separator;
my $get_line;
unless ($opt->tab_file) {
    my $csv = Text::CSV_XS->new({ binary => 1, , sep_char => $opt->separator })  # should set binary attribute.
	or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();
    $get_line = sub { my $fh = shift; return $csv->getline($fh) };
} else {
    $get_line = sub { my $fh = shift; my $row = <$fh>; return unless $row; chomp $row; return [ split $s, $row ] };
}
open my $fh, '<', $file or die "$file: $!";

my $k = $opt->skip_rows || 0; 
my $c = $opt->columns;
my $i;

if ($opt->fields_file) {
    my $row;
    my %fields;
    while ($row = $get_line->($fh)) {
	next unless ($i++ >= $k);
	@fields{@$row} = (0..$#$row);
	seek $fh, 0, Fcntl::SEEK_SET; $i = 0;
	last;
    }

    open FF, $opt->fields_file || die;
    my @fields = map { s/^\d+\t//g; s/\s$//; $_ } <FF>;
    @cols = @fields{@fields};
    # ok, this needs to get better
    do { dump \@fields; die "column not found" } if grep { !defined $_ } @cols;
    exit if $opt->check_columns
}

if ($opt->smart_file) {
    my $file = file($file);
    local $_ = $file->basename;    
    s/ \- /\-/g; s/\s/_/g; s/&/and/g; s/\.csv/.txt/;
    $file = file($file->dir->absolute, $_);
    *STDOUT = $file->openw; 
}


if ($opt->print_header) {
    $get_line->($fh) while ($i++ < $k);
    my $row = $get_line->($fh);
    my $j = 0;
    print @$_ for map { [$j++, $_ ] } @$row;
    exit;
}

my $output = $opt->columns ? 
    sub { my @row = @{$_[0]}; $#row = $#cols if $#row < $#cols; print @row[@cols] } :
    sub { print @{$_[0]} };

while (my $row = $get_line->($fh)) {
    next unless ($i++ >= $k);
    $output->($row);
}
