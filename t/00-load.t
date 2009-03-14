#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WebService::SAPO::PunyURL' );
}

diag( "Testing WebService::SAPO::PunyURL $WebService::SAPO::PunyURL::VERSION, Perl $], $^X" );
