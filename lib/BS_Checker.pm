use strict;
use warnings;
use feature 'class';
no warnings 'experimental::class';

class BS_Checker;

use feature qw[say];
use experimental qw[try];

use LWP::UserAgent;
use Web::Query;
use JSON;

my $ua = LWP::UserAgent->new(
  agent => 'Mozilla/5.0 (compatible; bs-checker/1.0; +https://github.com/davorg/bs-checker)',
);

field $results = {};
field $errors  = [];
field $urls :param;

method run {
  for (@$urls) {
    my $url = $_;

    my $q = do {
      try {
        wq($_, { agent => $ua })->find('link[rel="stylesheet"]');
      }
      catch ($e) {
        (my $msg = $e) =~ s/\s+$//;
        warn "$msg\n";
        push @$errors, { url => $url, error => $msg };
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
      warn "Can't get Bootstrap version for $url\n";
      push @$errors, { url => $url, error => "Bootstrap version not found" };
    }
  }

  for (keys %$results) {
    $results->{$_} = [ sort @{ $results->{$_} } ];
  }

  my $output = { %$results, errors => $errors };
  say JSON->new->pretty->encode($output);
}

1;
