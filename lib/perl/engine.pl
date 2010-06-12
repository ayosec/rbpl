#!/usr/bin/perl

use strict;
use YAML::Syck;

$| =1; # autoflush

our $data;
our $data_length;
our %SESSION;

while(1) {

    exit 0 if eof(STDIN); # Wait for data or exit if the parent closes the pipe

    read(STDIN, $data_length, 4) == 4 or die "Can not read \$data_length from stdin";
    $data_length = unpack("L", $data_length);

    read(STDIN, $data, $data_length) == $data_length or die "Can not read \$data from stdin";
    $data = Load($data);    

    if($data->{request} == "eval") {
        my $result = eval($data->{code});
        $result = Dump($@ ?
                        { status => "error", error => $@ } :
                        { status => "ok", result => $result });
        print pack("L", length($result)).$result;
    }
}
