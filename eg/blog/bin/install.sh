#!/bin/bash

# Requires cpanm: http://search.cpan.org/perldoc?App::cpanminus
cpanm -S --notest DateTime DBD::SQLite Poet Rose::DB::Object

# Load schema into database
cd `dirname $0`
mkdir -p ../data
sqlite3 ../data/blog.db < ../db/schema.sql
