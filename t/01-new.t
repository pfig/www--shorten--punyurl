#!perl -T

use Test::More tests => 2;

use WebService::SAPO::PunyURL;

my $url = 'http://developers.sapo.pt/';
my $punyurl = WebService::SAPO::PunyURL->new( url => $url );

ok( defined $punyurl, 'Object created' );
isa_ok( $punyurl, 'WebService::SAPO::PunyURL', 'Object type is correct' );
