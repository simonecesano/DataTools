my $file = $ARGV[1];
my $table = $ARGV[2];

use Getopt::Long::Descriptive;
use Data::Dump qw/dump/;

$\ = "\n"; $, = "\t";

my ($opt, $usage) =
    describe_options(
		     'populate.pl %o <data> <file.db> <table>',
		     [ 'list|L',  "list models"            ],
		     [ 'columns|C',  "list columns"            ],
		     [ 'smart|S',  "smart loader"            ],
		     [ 'test|T',  "test column existence"            ],
		     [],
		     [ 'verbose|v',  "print extra stuff"            ],
		     [ 'help|h',       "print usage message and exit" ],
		    );

print($usage->text), exit if $opt->help;


use DBIx::Class::Schema::Loader;

my $dbi = 'dbi:SQLite:' . $file;

my $conn = DBIx::Class::Schema::Loader->connect($dbi, { naming => { 'ALL' =>' v7' } } );
$conn->naming({ ALL => 'v7' });
# $conn->use_namespaces(1);

if ($opt->list) {
    print "sources: " . join ('; ', $conn->sources);
    exit;
}

if ($opt->columns) { 
    my $m = $conn->resultset($table);
    print join ' ', $m->result_source->columns;
    exit;
}

if ($opt->smart) {
    use Data::Dump qw/dump/;
    my $m = $conn->resultset($table);
    my @cols = $m->result_source->columns;
    $/ = ",\n";

    while (<>) {
	chomp;
	print;
	$d = eval $_;
	print dump $d; 
    }
    exit;
    $conn->populate($table, $data)
}


{
    my $data = do $ARGV[0];
    shift @$data if (ref $data->[0] eq 'ARRAY');
    if (1) {
	my $m = $conn->resultset($table);
	my @cols = $m->result_source->columns;
	for (@cols) {
	    # print unless defined $data->[0]->{$_};
	}
	my $i;
	for my $k (keys $data->[0]) {
	    next if grep { $_ eq $k } @cols;
	    print STDERR $k;
	    $i++;
	}
	exit if $i;
    }

    $conn->populate($table, $data)
}
