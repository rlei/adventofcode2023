#!/usr/bin/env perl
use feature qw(say);
use List::Util qw/sum/;

my $total = 0;
my @cards = <>;
my %cardCounts = map { $_ + 1 => 1 } (0 .. $#cards);

# Perl 5 has only closed ranges, and $#cards is actually len(cards) minus 1!
for my $idx (0 .. $#cards) {
    my $card = $cards[$idx];
    my $cardNo = $idx + 1;
    
    my ($cardName, $nums) = split(':', $card);
    my ($winningNumbersStr, $numbersStr) = split("\\|", $nums);

    my %winningNumbers = map { $_ => 1 } split(" ", $winningNumbersStr);
    my @numbers = split(" ", $numbersStr);

    my $found = sum(map {exists $winningNumbers{$_} ? 1 : 0} @numbers);
    if ($found > 0) {
        for my $next ($cardNo + 1 .. $cardNo + $found) {
            $cardCounts{$next} += $cardCounts{$cardNo}
        }
    }
    # say $cardNo, " ", $cardCounts{$cardNo};
    $total += $cardCounts{$cardNo}
}
say $total
