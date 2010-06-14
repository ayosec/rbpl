#!/usr/bin/perl

use strict;
use YAML::Syck;

use IO::Handle;

open Reader, "<&=", $ENV{ENGINE_READER};
open Writer, ">&=", $ENV{ENGINE_WRITER};
Writer->autoflush(1);

our $data;
our $data_length;
our %SESSION;
our %_USER_METHODS;

sub eval_and_respond {
    my ($block) = @_;
    my $result = &$block();

    my $packed_result = Dump($@ ?
                    { status => "error", error => $@ } :
                    { status => "ok", result => $result });
    print Writer pack("L", length($packed_result)).$packed_result;
    $result;
}

while(1) {

    exit 0 if eof(Reader); # Wait for data or exit if the parent closes the pipe

    read(Reader, $data_length, 4) == 4 or die "Can not read \$data_length from stdin";
    $data_length = unpack("L", $data_length);

    read(Reader, $data, $data_length) == $data_length or die "Can not read \$data from stdin";
    $data = Load($data);    

    if($data->{request} eq "eval") {
        eval_and_respond(sub { eval($data->{code}); });
    } elsif($data->{request} eq "define_method") {
        eval_and_respond(sub {
            $_USER_METHODS{$data->{method_name}} = eval("sub { ".$data->{body}." }");
        });
    } elsif($data->{request} eq "invoke_method") {
        eval_and_respond(sub {
            my $arguments = $data->{arguments};
            $_USER_METHODS{$data->{method_name}}(@$arguments);
        });
    }
}
