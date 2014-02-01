package Poet::App::Command;

use Poet::Moose;
use Cwd qw(getcwd);
use strict;
use warnings;

method initialize_environment () {
    require Poet::Script;
    Poet::Script::initialize_with_root_dir( getcwd() );
}

extends 'MooseX::App::Cmd::Command';

1;
