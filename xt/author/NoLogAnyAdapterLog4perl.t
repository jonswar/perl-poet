#!perl -w
use Poet::t::NoLog4perl;
use Module::Mask;
my $mask = new Module::Mask('Log::Any::Adapter::Log4perl');
Poet::t::NoLog4perl->runtests;
