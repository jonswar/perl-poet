package Poet::Mason::Plugin::Compilation;
use Mason::PluginRole;

# Add 'use Poet qw($conf $poet :web)' at the top of every component
#
override 'output_class_header' => sub {
    return join( "\n", super(), 'use Poet qw($conf $poet :web);' );
};

1;
