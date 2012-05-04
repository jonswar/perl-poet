#!/usr/local/bin/perl
use Poet::Script qw($conf);
use Blog::Article;
use strict;
use warnings;

my $days_to_keep = $conf->get( 'blog.days_to_keep' => 365 );
my $min_date = DateTime->now->subtract( days => $days_to_keep );
Blog::Article::Manager->delete_articles(
    where => [ create_time => { lt => $min_date } ] );
