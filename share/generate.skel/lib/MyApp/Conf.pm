package <% $app_name %>::Conf;
use Poet::Moose;

extends 'Poet::Conf';

# Add customizations to Poet::Conf here.
#
# e.g. Use INI instead of YAML for config files
#
# use Config::INI;
# override 'read_conf_file' => sub {
#     my ($self, $file) = @_;
#     return Config::INI::Reader->read_file($file);
# };

1;
