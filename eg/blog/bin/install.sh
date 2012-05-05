#!/bin/bash

# Requires cpanm: http://search.cpan.org/perldoc?App::cpanminus
cpanm -S --notest Date::Format DBD::SQLite Poet Rose::DB::Object

cd `dirname $0`
mkdir -p ../data
sqlite3 ../data/blog.db < ../db/schema.sql
