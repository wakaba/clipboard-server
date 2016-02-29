#!/usr/bin/perl
use strict;
use warnings;
use Wanage::HTTP;
use MIME::Base64 qw(decode_base64);

my $Data = {};

return sub {
  my $http = Wanage::HTTP->new_from_psgi_env ($_[0]);
  return $http->send_response (onready => sub {
    my $path = $http->url->{path};
    $http->set_response_header
        ('Strict-Transport-Security' => 'max-age=2592000; includeSubDomains; preload');
    if ($path =~ m{\A/([1-9][0-9]*)/?\z}) {
      my $key = $1;
      my $method = $http->request_method;
      if ($method eq 'POST') {
        if (@{$http->request_uploads->{file} || []}) {
          $Data->{$key} = \scalar $http->request_uploads->{file}->[0]->as_f->slurp;
        } elsif (defined $http->request_body_params->{base64}->[0]) {
          my $b64 = $http->request_body_params->{base64}->[0];
          if ($b64 =~ s{^[Dd][Aa][Tt][Aa]:[^,]*?;[Bb][Aa][Ss][Ee]64,}{}) {
            $b64 =~ s/%([0-9A-Fa-f]{2})/pack 'C', hex $1/ge;
            $b64 = decode_base64 $b64;
          } elsif ($b64 =~ s{^[Dd][Aa][Tt][Aa]:[^,]*,}{}) {
            $b64 =~ s/%([0-9A-Fa-f]{2})/pack 'C', hex $1/ge;
          } else {
            $b64 = decode_base64 $b64;
          }
          $Data->{$key} = \$b64;
        } else {
          $Data->{$key} = \($http->request_body_params->{data}->[0] // '');
        }
        $http->set_status (201);
        $http->send_response_body_as_ref (\q{Saved});
        $http->close_response_body;
      } elsif ($method eq 'PUT') {
        $Data->{$key} = $http->request_body_as_ref;
        $http->set_status (201);
        $http->send_response_body_as_ref (\q{Saved});
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
    } elsif ($path =~ m{\A/([1-9][0-9]*)/form\z}) {
      $http->set_response_header ('Content-Type' => 'text/html; charset=utf-8');
      $http->send_response_body_as_ref (\q{
        <!DOCTYPE HTML>
        <title>Clipboard</title>
        <style>
          section {
            margin: .5rem;
            border: blue 1px solid;
            padding: .5rem;
          }
          h1 {
            margin: .5rem 0;
            font-size: 100%;
            font-weight: bolder;
          }
          h1::after { content: ":" }
          p {
            margin: .5rem 0;
            text-align: center;
            line-height: 1.5;
          }
          textarea {
            width: 100%;
            min-height: 10em;
            box-sizing: border-box;
          }
          button {
            min-width: 10em;
            padding: .3rem;
          }
        </style>

        <section>
          <h1>Text</h1>
          <form method=post action=./>
            <p><textarea name=data></textarea>
            <script>
              fetch ('./').then (function (res) {
                return res.text ();
              }).then (function (text) {
                document.forms[0].elements.data.value = text;
              });
            </script>
            <p><button type=submit>Save</button>
          </form>
        </section>

        <section>
          <h1>Base64</h1>
          <form method=post action=./>
            <p><textarea name=base64></textarea>
            <p><button type=submit>Save</button>
          </form>
        </section>

        <section>
          <h1>File</h1>
          <form method=post action=./ enctype=multipart/form-data>
            <p><input type=file name=file>
            <p><button type=submit>Upload</button>
          </form>
        </section>
      });
      $http->close_response_body;
    } else {
      $http->set_status (404);
      $http->close_response_body;
    }
  });
};

## License: Public Domain.
