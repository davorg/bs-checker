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
  agent => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
);
$ua->default_header('Accept'          => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8');
$ua->default_header('Accept-Language' => 'en-US,en;q=0.5');

field $results = {};
field $errors  = [];
field $urls :param;

method run {
  for (@$urls) {
    my $url = $_;

    my $resp = $ua->get($url);
    unless ($resp->is_success) {
      my $err = $resp->status_line;
      warn "$err\n";
      push @$errors, { url => $url, error => $err };
      next;
    }

    my $html = $resp->decoded_content;
    my $q = do {
      try {
        wq($html)->find('link[rel="stylesheet"]');
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
