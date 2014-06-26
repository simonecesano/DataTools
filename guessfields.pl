use Getopt::Long::Descriptive;
use Array::Transpose qw/transpose/;
use Array::Transpose::Ragged qw/transpose_ragged/;

use Data::Dump qw/dump/;
use List::MoreUtils qw/all uniq/;
use List::Util qw/max/;
use Text::CSV_XS;
use Text::Autoformat qw/autoformat/;
use File::Spec;

use strict;

$\ = "\n"; $, = "\t";

my ($opt, $usage) = 
    describe_options(
		     'guessfields.pl %o <some-arg>',
		     [ 'tab|t',    "tab separated file", { default => 1 } ],
		     [ 'csv|c',    "csv file"         ],
		     [],
		     [ "mode|m:s" => 
		       hidden => { one_of => [
					      [ 'sql|q',  "output sql create table" ],
					      [ 'analyse|a',  "analyse data" ],
					      [ 'length|l',  "print field lengths" ],
					     ] },
		     ],
		     [],
		     [ 'separator|s=s',  "field separator", { default => "\t" } ],
		     [ 'records|r=i',  "number of records to check", { default => 300 } ],
		     [ 'sample_perc|S=i',  "percentage of records to check", { default => 1 } ],
		     [ 'name|n=s',  "table name" ],
		     [],
		     [ 'strict|T',  "strict checking of integers" ],
		     [ 'force_varchar|V',  "force everything to varchar" ],
		     [ 'drop|D',  "add drop table statement" ],
		     [ 'import|I',  "add import statement (sqlite3 only)" ],
		     [],
		     [ 'verbose|v',  "print extra stuff"            ],
		     [ 'help|h',       "print usage message and exit" ],
		    );

print($usage->text), exit if $opt->help;

my $file = $ARGV[0];

my @data;

my $max_rec = $opt->records;
my $perc = 1 - ($opt->sample_perc / 100);

if ($opt->csv) {
    my $sep = $opt->separator eq "\t" ? ',' : $opt->separator;

    open my $fh, '<', $file;
    my $csv = Text::CSV_XS->new ({ binary => 1, sep_char => $sep  }) or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();
    while (my $row = $csv->getline ($fh)) {
	push @data, $row if (($. == 1) || (rand() > $perc));
	last if @data > $max_rec;
    }
    $csv->eof or $csv->error_diag ();
    close $fh;
}

if ($opt->tab) {
    my $sep = $opt->separator;
    while (<>) {
	chop;
	push @data, [split $sep, $_] if (($. == 1) || (rand() > $perc));
	last if @data > $max_rec;
    }
}


my @head = @{ shift @data };
# print @head; exit;
my @transposed = transpose_ragged \@data;

my %fields;

use Scalar::Util qw/looks_like_number/;

sub sql_type {
    my $opt = pop @_ if ref $_[-1] eq 'HASH';
    my @d = @_;

    s/^\s+|\s+$//g for @d;

    unless ($opt->{varchar}) {
	if ($opt->{strict}) {
	    return 'integer' if all { /^\d+$/       && looks_like_number($_) } @d;
	    return 'float'   if all { /^\d+\.*\d*$/ && looks_like_number($_) } @d;
	} else {
	    return 'integer' if all { /^\d+$/       || /^\s*$/ } @d;
	    return 'float'   if all { /^\d+\.*\d*$/ || /^\s*$/ } @d;
	}
    }
    return (sprintf "varchar(%d)", ((max map { length $_ } @d) || 8));
}

sub analyse_values {
    my @d = @_;
    my $r;

    $r->{values} = [ uniq map { s/^$/-EMPTY-/; $_ } @d ];
    $r->{values} = [ grep { $_ } @{$r->{values}}[0..19] ];

    $r->{unique} = scalar uniq map { s/^$/-EMPTY-/; $_ } @d;
    $r->{length} = max map { length $_ } @d;
    return $r;
} 

sub mogrify {
    my @d = @_;
    return map {
	s/^\s+|\s+$//g;
	s/\-(\d+)/_minus_$1_/g;
	s/\-//g;
	s/\s/_/g;
	s/%/perc/g;
	s/article.id/article_nr/ig;
	s/#/nr/g;
	s/^1st/first/g;
	s/\//_or_/g;
	s/[()\'\.]//g;
	s/\&/_and_/g;
	s/\+/_plus_/g;

	s/_+/_/g;
	s/^_|_$//g;

	$_ = lc;
	$_ 
    } @d
}

sub make_unique {
    my @d = @_;
    my %f;
    for (@d) { if ($f{$_}) { $_ .= (sprintf "_%02d", ++$f{$_}) } else {  $f{$_}++ } }
    return @d;
}

my @translated = make_unique(mogrify(@head));

# print scalar @transposed; 
my $i;
my @fields = map {
    [
     $_,
     shift @translated,
     sql_type(@{$transposed[$i]}, { strict => $opt->strict, varchar => $opt->force_varchar }),
     analyse_values(@{$transposed[$i++]})
    ]
} @head;

# print scalar @transposed; exit;

if ($opt->mode eq 'analyse') {
    print STDERR 'deprecated - use colan.pl instead';
    exit;
}

if ($opt->mode eq 'sql') {
    my $table = $opt->name || 'XXXX';
    my $name_len = 2 + max map { length $_->[1] } @fields; 
    my $type_len = 3 + max map { length $_->[2] } @fields; 

    my $create = join ",\n", map {
	sprintf "\t%-${name_len}s %s", $_->[1], $_->[2];
    } @fields;

    if ($opt->drop) { printf "DROP TABLE %s;\n", $table };

    printf "CREATE TABLE %s (\n%s\n);\n", $table, $create;

    if ($opt->import) {
	my $file = File::Spec->rel2abs($file);
	printf ".separator \"\\t\"\n.import \"%s\" %s\n", $file, $table;
    }
}
