#!/usr/bin/perl

use strict;
use warnings;
$|++;


use LWP::Simple;


my $assets_tgz = "napi_test_files.tgz";
my $url = "https://www.dropbox.com/s/gq2wbfkl7ep1uy8/" . $assets_tgz;
my $assets_path = "TODO";


print "Downloading $assets_tgz\n";
getstore( $url, $assets_path );

my $ae = Archive::Extract->new( archive => $assets_path );
$ae->extract( to => $path_root ) and print "Unpacked assets\n";
