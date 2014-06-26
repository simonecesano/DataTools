chop;
s/\,//g;
printf "%s\t%s\n", $_, join '', sort split '', $_;
