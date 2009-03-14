#!perl -T

use Test::More tests => 3;

use WebService::SAPO::PunyURL;

my $url = 'http://developers.sapo.pt/';
my $punyurl = WebService::SAPO::PunyURL->new(
    url => 'http://developers.sapo.pt/'
);

is( $punyurl->url, 'http://developers.sapo.pt/', 'URL setting' );
isa_ok( $punyurl->parser, 'XML::LibXML', 'XML parser instantiated' );
isa_ok( $punyurl->browser, 'LWP::UserAgent', 'Browser instantiated' );