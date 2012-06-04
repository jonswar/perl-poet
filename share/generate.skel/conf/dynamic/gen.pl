#!<% Poet::Tools::perl_executable %>
#
# Processes the source files in this directory via MasonX::ProcessDir
# and generates destination files in data/conf/dynamic.
#
use Poet::Script qw($conf);
use strict;
use warnings;

$conf->generate_dynamic_conf();
