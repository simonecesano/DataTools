use Getopt::Long::Descriptive;

$\ = "\n"; $, = "\t";

my ($opt, $usage) =
    describe_options(
		     'pltoupdate %o <data-file>',
		     [ 'text|T',      "input file is simple where-newvalue file", { default => 1 } ],
		     [ 'table|t:s',      "the table to be updated" ],
		     [ 'field|f:s',      "the field to be updated" ],
		     [ 'where|w:s',      "the field to be filtered" ],
		     [],
		     [ 'verbose|v',  "print extra stuff"            ],
		     [ 'help',       "print usage message and exit" ],
		    );

print($usage->text), exit if $opt->help;

$/ = "\n";

if ($opt->text) {
    @d = <>;

    my $table = $opt->table;
    my $field = $opt->field;
    my $where = $opt->where || $opt->field;


    # takes tables of either format:
    # - from_val, to_val
    # - update_field, to_val, filter_field, filter_val

    for (@d) {
	chop;
	my @val = split /\t/;
	my ($filter_field, $update_field);
	if (scalar @val == 4) {
	    ($update_field, $val[1], $filter_field, $val[0]) = @val;
	} else {
	    ($update_field, $filter_field) = ($field, $where);
	}

	printf qq/update %s set %s = "%s" where %s = "%s";\n/,
	                 $table, $update_field, $val[1], $filter_field, $val[0];
    }
}

