use Getopt::Std;

getopt("p:");
$opt_p ||= 10;
$opt_p /= 100;

while (<>) {
    print if rand() < $opt_p;
}
