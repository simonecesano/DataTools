use List::MoreUtils qw/uniq/;
use List::Util qw/max/;
use Getopt::Long::Descriptive;

use strict;

$\ = "\n"; $, = "\t";

my ($opt, $usage) = describe_options(
				     "$0 %o - create sql snippets",
				     [ 'in|i', "create \"in\" clause"],
				     [ 'case|c', "create \"case\" clause"],
				     [ 'update|u:s', "get unique values from table and field in database"],
				     [ 'unique|U:s', "get unique values from table and field in database"],
				     [ 'count|C:s', "get unique values from table and field in database, and count of records"],
				     [ 'sub|S:s', "sub to apply to input values"],
				     [],
				     [ 'first|f', "force first line as field name"],
				     [ 'no_header|F', "first line is NOT field name"],
				     [],
				     [ 'verbose|v',  "print extra stuff"            ],
				     [ 'help|h',       "print usage message and exit" ],
				    );

print($usage->text), exit if $opt->help;

# my @foo = splice @ARGV, 0;

if ($opt->unique) {
    my ($table, $field) = (split /\./, $opt->unique);
    print "select distinct $field from $table\;";
    exit;
}

if ($opt->count) {
    my ($table, $field) = (split /\./, $opt->count);
    print "select $field, count(*) as count from $table group by $field\;";
    exit;
}


my @c = grep { /\w/ } map { s/\n//; $_ } <>;
my $field;
if (($c[0] =~ /^[a-z_]+$/ && !$opt->no_header) || ($opt->first)) { $field = shift @c }
my $len = 2 + max map { length } @c;
@c = sort @c;


if ($opt->case) {
    if ($field) {
	printf "case\n%s\nend\n", (join "\n", map { sprintf "    when %s = %-${len}s then %s", $field, $_, $_ } map {qq/"$_"/ } uniq @c);
    } else {
	my $field = "field_name";
	printf "case\n%s\nend\n", (join "\n", map { sprintf "    when %s = %-${len}s then %s", $field, $_, $_ } map {qq/"$_"/ } uniq @c);
    }
    exit;
}

if ($opt->in) {
    if ($field) { 
	printf "%s in (\n%s\n)\n", $field, (join ",\n", map {qq/     "$_"/ } uniq @c);
    } else {
	printf "(\n%s\n)\n", (join ",\n", map {qq/     "$_"/ } uniq @c);
    }
    exit;
}

if ($opt->sub) { die unless eval $opt->sub };
my $sub = $opt->sub ? eval $opt->sub : sub { return shift };

if ($opt->update) {
    my ($table, $updated_field) = (split /\./, $opt->update);
    printf "update %s set %s = \"%s\" where %s = \"%s\";\n", $table, $updated_field, $sub->($_), $field, $_
	for @c;
    exit;
}
