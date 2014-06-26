use DBIx::Class::Schema::Loader;
use Data::Dump qw/dump/;

use Getopt::Long::Descriptive;

$\ = "\n"; $, = "\t";

my ($opt, $usage) =
    describe_options(
		     $0 . ' %o <database> <table> <text-file>',
		     [ 'populate|p',     "populate table" ],
		     [ 'add|A',     "add content" ],
		     [],
		     [ 'missing_columns|m:s',      "print missing columns (table, input or both)" ],
		     [ 'table_columns|C',     "print table columns" ],
		     [ 'tables|T',     "print table names and exit" ],
		     [],
		     [ 'verbose|v',  "print extra stuff"            ],
		     [ 'help|h',       "print usage message and exit" ],
		    );

print($usage->text), exit if $opt->help;

my ($db, $table, $file) = @ARGV;

DBIx::Class::Schema::Loader->naming('current');
my $s = DBIx::Class::Schema::Loader->connect('dbi:SQLite:' . $db) || die "database connection failed";


my $source;
for ($s->sources) {
    if ($s->class($_)->table eq $table) {
	@table_columns = $s->class($_)->columns;
	$source = $_;
	last;
    }
}

if ($opt->tables) {
    for ($s->sources) {
	print $_, $s->class($_)->table;
    }
    exit;
}
if ($opt->table_columns) {
    print join ', ', @table_columns;
}

#----------------------------
# opening the file here
#----------------------------

open my $file, '<', $file;
%file_head = map { $_ => $i++ } mogrify(split /\t/, <$file>);


#----------------------------
# start output
#----------------------------

if ($opt->missing_columns) {
    use Set::Scalar;
    my $file_head     = Set::Scalar->new(keys %file_head);
    my $table_columns = Set::Scalar->new(@table_columns);
    
    print "Missing following columns in input: " . join ', ', $table_columns->difference($file_head)->members
	if $table_columns->difference($file_head)->members && $opt->missing_columns =~ /^i|^b/i ;
    print "Missing following columns in table: " . join ', ', $file_head->difference($table_columns)->members
	if $file_head->difference($table_columns)->members && $opt->missing_columns =~ /^t|^b/i ;

    exit if $opt->missing_columns;
}
my @out_cols = map { s/^$/xx/; $_; } @file_head{@table_columns};



if ($opt->populate) {
    my @rows;
    push @rows, [ @table_columns ];
    
    while (<$file>) {
	chop;
	my @data = split /\t/;
	push @rows, [ @data[@out_cols] ];
    }
    
    # there should be a transaction around this
    {
	$s->resultset($source)->search->delete unless $opt->add;;
	$s->resultset($source)->populate(\@rows);
    }
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
