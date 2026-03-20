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
  agent => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' .
           '(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
);
$ua->default_header('Accept' =>
  'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,' .
  'image/webp,*/*;q=0.8');
$ua->default_header('Accept-Language' => 'en-US,en;q=0.5');

$Web::Query::UserAgent = $ua;

field $results = {};
field $errors  = [];
field $urls :param;

method run {
  for (@$urls) {
    my $url = $_;

    my $q = do {
      try {
        wq($_)->find('link[rel="stylesheet"]');
      }
      catch ($e) {
        (my $msg = $e) =~ s/\s+$//;
        warn "$msg\n";
        push @$errors, { url => $url, error => $msg };
        next;
      }
    };

    my $ver;
    my $has_bootstrap;

    $q->each(sub {
      my $href = $_->attr('href');
      $has_bootstrap = 1 if $href =~ /bootstrap/i;
      return unless $href =~ /bootstrap\.(min\.)?css/;
      ($ver) = $href =~ /(\d+\.\d+\.\d+)/;
    });

    unless ($has_bootstrap) {
      warn "Bootstrap not used at $url\n";
      push @$errors, { url => $url, error => "Bootstrap not used" };
      next;
    }

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
