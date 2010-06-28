use inc::Module::Install;

name 'Poet';
abstract 'Lightweight application environment';
all_from 'lib/Poet.pm';
author 'Jonathan Swartz <swartz@pobox.com>';

perl_version '5.006';

build_requires 'Test::Class' => 0;
build_requires 'Test::More' => 0;

requires 'File::Slurp' => 0;
requires 'Moose' => 0;
requires 'Text::Trim' => 0;
requires 'YAML::AppConfig' => 0;
requires 'YAML::XS' => 0;

license 'perl';

auto_install;

WriteAll;
