package Blog::DB;
use Poet qw($env);
use strict;
use warnings;
use base qw(Rose::DB);

__PACKAGE__->use_private_registry;
__PACKAGE__->register_db(
    driver   => 'sqlite',
    database => $env->data_path("blog.db"),
);

1;
