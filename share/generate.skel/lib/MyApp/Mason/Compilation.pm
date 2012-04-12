package <% $app_name %>::Mason::Compilation;
use Poet qw($conf $env);
use Poet::Moose;

extends 'Mason::Compilation';

# Add customizations to Mason::Compilation here.
#
# e.g. Add Perl code to the top of every compiled component
#
# override 'output_class_header' => sub {
#      return join("\n", super(), 'use Foo;', 'use Bar qw(baz);');
# };

1;
