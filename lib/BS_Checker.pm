use strict;
use warnings;
use feature 'class';
no warnings 'experimental::class';

class BS_Checker;

use feature qw[say];
use experimental qw[try];

use Web::Query;
use JSON;

field $results = {};
field $urls :param;

method run {
  for (@$urls) {
    my $url = $_;

    my $q = do {
      try {
        wq($_)->find('link[rel="stylesheet"]');
      }
      catch ($e) {
        warn $e;
        next;
      }
    };

    my $ver;

    $q->each(sub {
      my $href = $_->attr('href');
      return unless $href =~ /bootstrap\.(min\.)?css/;
      ($ver) = $href =~ /(\d+\.\d+\.\d+)/;
      $ver //= '0.0.0';
    });

    if ($ver) {
      push @{$results->{$ver}}, $url;
    } else {
      warn "Can't get version for $url\n";
    }
  }

  for (keys %$results) {
    $results->{$_} = [ sort @{ $results->{$_} } ];
  }

  say JSON->new->pretty->encode($results);
}

1;
