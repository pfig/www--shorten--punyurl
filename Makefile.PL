use inc::Module::Install;

name     'WebService-SAPO-PunyURL';
all_from 'lib/WebService/SAPO/PunyURL.pm';
author   'Pedro Figueiredo <me@pedrofigueiredo.org>';
license  'perl';

build_requires  'Test::More';
build_requires  'XML::LibXML::XPathContext';

requires        'URI::Escape';
requires        'Regexp::Common';
requires        'LWP::UserAgent';
requires        'XML::LibXML';
requires        'XML::LibXML::XPathContext';
requires        'Mouse';
requires        'Mouse::Util::TypeConstraints';

auto_install;

WriteAll;

