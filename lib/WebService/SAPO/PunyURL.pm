package WebService::SAPO::PunyURL;

=head1 NAME

WebService::SAPO::PunyURL - An interface to SAPO's URL shortening service

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

PunyURL is a URL shortening service provided by SAPO (L<http://sapo.pt/>). Given a URL, it replies with two versions of the short URL, one using Unicode and RFC3492-compliant (Punycode) and an ASCII-equivalent (lowercase).

You can also provide the shortened URL and get back the original one.

    use WebService::SAPO::PunyURL;

    my $punyurl = WebService::SAPO::PunyURL->new( url => $long );
    $punyurl->shorten;
    
    # or
    
    my $punyurl = WebService::SAPO::PunyURL->new( url => $short );
    $punyurl->long;

Optionally, you can give the constructor a timeout value (which defaults to 10 seconds):

    my $punyurl = WebService::SAPO::PunyURL->new(
        url     => $long,
        timeout => 5
    );

=head1 TODO

=over 4

* Write conditional network tests

* Write mock tests with a local XML file

* Report/fix bug in Regexp::Common::URI (doesn't handle Unicode)
  UNTIL THIS IS FIXED, REQUESTING THE URL CORRESPONDING A PUNYCODE SHORTENED
  ONE WILL BREAK HORRIBLY AND PROBABLY DESTROY THE WORLD. USE THE ASCII SHORT
  VERSION FOR NOW.

=back

=over

=cut

#use Moose;
#use Moose::Util::TypeConstraints;

use Mouse;
use Mouse::Util::TypeConstraints;

use Regexp::Common qw/ URI /;

use URI::Escape qw/ uri_escape_utf8 /;
use LWP::UserAgent;

use XML::LibXML;
use XML::LibXML::XPathContext;

subtype 'URL'
    => as 'Str'
    => where { /$RE{URI}/ };

has 'url'      => (
    is         => 'ro',
    isa        => 'URL',
    required   => 1,
);

has 'puny'     => (
    is         => 'rw',
    isa        => 'Str',
    default    => '',
);

has 'ascii'    => (
    is         => 'rw',
    isa        => 'Str',
    default    => '',
);

has 'original' => (
    is         => 'rw',
    isa        => 'Str',
    default    => '',
);

has 'browser'  => (
    is         => 'rw',
    isa        => 'LWP::UserAgent',
    lazy_build => 1
);

has 'timeout'  => (
    is         => 'rw',
    isa        => 'Int',
    default    => 10,
);

has 'error'    => (
    is         => 'rw',
    isa        => 'Str',
    default    => '',
);

has 'errstr'   => (
    is         => 'rw',
    isa        => 'Str',
    default    => '',
);

has 'parser'   => (
    is         => 'rw',
    isa        => 'XML::LibXML',
    lazy_build => 1,
);

no Mouse;
no Mouse::Util::TypeConstraints;
__PACKAGE__->meta->make_immutable;

=head1 CONSTANTS

=head2 ENDPOINT

The service endpoint for PunyURL

=cut

use constant ENDPOINT => 'http://services.sapo.pt/PunyURL';

=head1 FUNCTIONS

=head2 new

Create a new WebService::SAPO::PunyURL object. Takes a string (containing a URL) as the argument (may also take an optional timeout, see SYNOPSIS):

    my $punyurl = WebService::SAPO::PunyURL->new( $url );

=head2 shorten

Give it a long url and you will get two shortened URLs, one using Unicode and its equivalent in lowercase ASCII. Returns undef on failure.

    my $result = $punyurl->shorten;
    
    if ( $result ) {
        print $punyurl->url, "is now:\n";
        print "\t", $punyurl->puny, "\n";
        print "\t", $punyurl->ascii, "\n";
    } else {
        print STDERR "Error:\n";
        print STDERR $punyurl->errstr, "(", $punyurl->error, "\n";
    }

=cut

sub shorten {
    my $self = shift;
    
    my $request = ENDPOINT.'/GetCompressedURLByURL?url='.$self->_urlencode;
    
    my $xml = $self->_do_http( $request );
    return undef unless $xml;
    
    my $xpc   = $self->_get_xpc( $xml );
    my $puny  = $xpc->findvalue( '//p:puny' );
    my $ascii = $xpc->findvalue( '//p:ascii' );
    
    $self->puny( $puny );
    $self->ascii( $ascii );
    
    return 1;
}

=head2 long

Given a short URL (that you previously got through shorten() or any other means), returns the original URL, or undef in case of failure.

    $punyurl->long;

=cut

sub long {
    my $self = shift;
    
    my $request = ENDPOINT.'/GetURLByCompressedURL?url='.$self->_urlencode;

    my $xml = $self->_do_http( $request );
    return undef unless $xml;
    
    my $xpc      = $self->_get_xpc( $xml );    
    my $original = $xpc->findvalue( '//p:url' );

    $self->original( $original );
    
    return 1;
}

=begin ignore

=head1 INTERNAL FUNCTIONS

=head2 _do_http

=cut

sub _do_http {
    my $self = shift;
    my $uri  = shift;
    
    my $response = $self->browser->get( $uri );
    
    if ( ! $response->is_success ) {
        $self->error( $response->code );
        $self->errstr( $response->status_line );
        return undef;
    }
    
    if ( $response->content_type ne 'text/xml' ) {
        $self->error( '501' );
        $self->errstr(
            'Wrong Content-Type received: ' .
            $response->content_type
        );
        return undef;
    }
    
    return $response->content;
}

=head2 _get_xpc

=cut

sub _get_xpc {
    my $self = shift;
    my $xml  = shift;
    
    my $doc = $self->parser->parse_string( $xml );
    my $xpc = XML::LibXML::XPathContext->new( $doc );
    $xpc->registerNs( 'p', 'http://services.sapo.pt/Metadata/PunyURL' );
    
    return $xpc;
}
=head2 _urlencode

Lifted from Net::Amazon::S3. Thanks, Le'on!

=cut

sub _urlencode {
    my $self = shift;
    
    return uri_escape_utf8( $self->url, '^A-Za-z0-9_-' );
}

=head2 _build_browser

=cut

sub _build_browser {
    my $self = shift;
    
    my $ua = LWP::UserAgent->new;
    $ua->timeout( $self->timeout );
    $ua->env_proxy;
    
    return $ua;
}

=head2 _build_parser

=cut

sub _build_parser {
    return XML::LibXML->new;
}
=end ignore

=head1 AUTHOR

Pedro Figueiredo, C<< <me at pedrofigueiredo.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-sapo-punyurl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-SAPO-PunyURL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::SAPO::PunyURL


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-SAPO-PunyURL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-SAPO-PunyURL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-SAPO-PunyURL>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-SAPO-PunyURL/>

=back


=head1 ACKNOWLEDGEMENTS

=over 4

* João Pedro, from SAPO, for pushing PunyURL.

* Léon Brocard, for writing lots of code I can look at. My mistakes are my
  own, however.

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Pedro Figueiredo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of WebService::SAPO::PunyURL
