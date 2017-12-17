use strict;
use warnings;
use Path::Tiny;
use Promise;
use Sarze;

my $host = '0';
my $port = shift or die "Usage: $0 port";

Sarze->run (
  hostports => [
    [$host, $port],
  ],
  psgi_file_name => path (__FILE__)->parent->child ('server.psgi'),
  max_worker_count => 1,
)->to_cv->recv;
