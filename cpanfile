requires 'JSON';
requires 'Web::Query';
# Assume we're going to use https
requires 'IO::Socket::SSL';
requires 'Net::SSLeay';
requires 'LWP::Protocol::https';
# Bad version of Module::Build::Tiny
requires 'Module::Build::Tiny', '!= 0.049';
