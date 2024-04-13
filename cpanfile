# Someone, somewhere deep in the dependency stack needs
# this. And CPAN still thinks the most recent version
# is 0.26 - even though 0.27 exists.
requires 'HTML::TreeBuilder::LibXML', '0.27';
requires 'JSON';
requires 'Web::Query';
# Assume we're going to use https
requires 'IO::Socket::SSL';
requires 'Net::SSLeay';
requires 'LWP::Protocol::https';
