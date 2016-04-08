#!/usr/bin/perl

use strict;
use warnings;
$|++;


use LWP::Simple;
use File::Temp;


my $assets_tgz = "napi_testdata.tgz";
my $url = "https://www.dropbox.com/s/xz3pfvkj5d8zp6i/${assets_tgz}?dl=0";
my $assets_path = "/usr/share/napi";


my $wdir = File::Temp::tempdir( CLEANUP => 1 );


print "Downloading $assets_tgz ";
my $status = getstore( $url, $wdir . '/' . $assets_path );

print 200 == $status ? "OK" : "FAIL";
print "\n";

if (200 == $status) {
    die "Unable to create the architecture independent data directory\n"
        unless ( -e $assets_path || mkdir ($assets_path) );

    my $ae = Archive::Extract->new(
        archive => $wdir . '/' . $assets_tgz );
    $ae->extract( to => $assets_path ) and print "Unpacked assets\n";
}
