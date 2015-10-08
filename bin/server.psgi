#!/usr/bin/perl
use strict;
use warnings;
use Wanage::HTTP;

my $Data = {};

return sub {
  my $http = Wanage::HTTP->new_from_psgi_env ($_[0]);
  return $http->send_response (onready => sub {
    my $path = $http->url->{path};
    $http->set_response_header
        ('Strict-Transport-Security' => 'max-age=2592000; includeSubDomains; preload');
    if ($path =~ m{\A/([1-9][0-9]*)\z}) {
      my $key = $1;
      my $method = $http->request_method;
      if ($method eq 'POST') {
        $Data->{$key} = \($http->request_body_params->{data}->[0] // '');
        $http->set_status (201);
        $http->close_response_body;
      } elsif ($method eq 'PUT') {
        $Data->{$key} = $http->request_body_as_ref;
        $http->set_status (201);
        $http->close_response_body;
      } else {
        if (defined $Data->{$key}) {
          $http->set_status (200);
          $http->send_response_body_as_ref ($Data->{$key});
          $http->close_response_body;
        } else {
          $http->set_status (404);
          $http->close_response_body;
        }
      }
    } else {
      $http->set_status (404);
      $http->close_response_body;
    }
  });
};

## License: Public Domain.
