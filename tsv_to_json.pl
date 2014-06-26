use JSON;
use Scalar::Util qw(looks_like_number);

$\ = "\n"; $, = "\t";

my @head = map { s/^\s+|\s+$//; $_ } split /\t/, <>;

my @d;
while (<>) {
    my %h;

    chop;
    @h{@head} = map { looks_like_number($_) ? ($_ + 0) : $_ } split /\t/;
    # @h{@head} = split /\t/;
    push @d, { %h };
}

print to_json(\@d, { pretty => 1 });
