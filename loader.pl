use DBIx::Class::Schema::Loader;
use Data::Dump qw/dump/;
use List::Util qw/first/;
use Getopt::Long::Descriptive;

$\ = "\n"; $, = "\t";

my ($opt, $usage) =
    describe_options(
		     $0 . ' %o <database> <table> <text-file>',
		     [ 'populate|p',     "populate table" ],
		     [ 'add|a',     "add content", { implies => 'populate' } ],
		     [ 'filter|f:s',     "filter rows" ],
		     [ 'check|c',     "check after loading" ],
		     [],
		     [ 'table_columns|C',     "print table columns" ],
		     [ 'tables|T',     "print table names" ],
		     [ 'header|H',     "print file header" ],
		     [ 'missing_columns|M',      "print missing columns" ],
		     [],
		     [ 'verbose|v',  "print extra stuff"            ],
		     [ 'help|h',       "print usage message and exit" ],
		    );

print($usage->text), exit if $opt->help;

my ($db, $table, $file) = @ARGV;

DBIx::Class::Schema::Loader->naming('current');
my $s = DBIx::Class::Schema::Loader->connect('dbi:SQLite:' . $db) || die "database connection failed";
my $source = first { $s->class($_)->table eq $table } $s->sources;
my @columns = $s->class($source)->columns;
my @keys = $s->resultset($source)->result_source->primary_columns;

#----------------------------
# opening the file here
#----------------------------


#--------------------------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------------------------

if ($opt->tables) { print $_, $s->class($_)->table for ($s->sources) };
if ($opt->table_columns) { print join ', ', @columns };
exit if $opt->tables || $opt->table_columns; 


#----------------------------
# start output
#----------------------------

if ($file) { open $file, '<', $file } else { $file = *STDIN };
my %head = map { $_ => $i++ } mogrify(split /\t/, <$file>);
# if ($opt->header) { print  join ', ', sort { $head{$a} <=> $head{$b} } keys %head };

my @out = map { defined $_ ? $_ : (1 + scalar keys %head) } @head{@columns};

if ($opt->populate) {
    my @rows = map { s/\n//; $_ } <$file>;

    if ($opt->filter) {
	my $f;
	if (ref eval $opt->filter) { $f = eval $opt->filter } else { $f = quotemeta($opt->filter); $f = qr/$f/ }
    	@rows = grep { /$f/ } @rows;
    }
    
    @rows = map { [ @{[ split /\t/ ]}[@out] ] } @rows;
    unshift @rows, [ @columns ];

    if (@keys) {
	my @out = (shift @rows); map { unless ($u{join '::', @{$_}[@keys]}++) { push @out, $_ } } @rows;
	@rows = @out;
    }

    # there should be a transaction around this
    printf STDERR "table contains %d rows before load\n", $s->resultset($source)->search->count if $opt->check;
    {
	$s->resultset($source)->search->delete unless $opt->add;;
	$s->resultset($source)->populate(\@rows);
    }
    printf STDERR "loaded %d rows\n", (scalar @rows) - 1 if $opt->check;
    printf STDERR "table contains %d rows after load\n", $s->resultset($source)->search->count if $opt->check;
}

if ($opt->missing_columns) {
    print "Missing following columns in input: " . join ', ',  grep { !(defined $head{$_}) } @columns;
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
