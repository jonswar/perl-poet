package Poet::Util::File;
use File::Basename qw(basename dirname);
use File::Path qw();
use File::Slurp qw(read_dir read_file write_file);
use File::Spec::Functions qw(abs2rel canonpath catdir catfile rel2abs);
use List::MoreUtils qw(uniq);
use strict;
use warnings;
use base qw(Exporter);

File::Path->import( @File::Path::EXPORT, @File::Path::EXPORT_OK );

our @EXPORT_OK =
  uniq( qw(abs2rel basename canonpath catdir catfile dirname read_file rel2abs write_file),
    @File::Path::EXPORT, @File::Path::EXPORT_OK );
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

1;

__END__

=pod

=head1 NAME

Poet::Util::File - File utilities

=head1 SYNOPSIS

    # In a script...
    use Poet::Script qw(:file);

    # In a module...
    use Poet qw(:file);

    # In a component...
    <%class>
    use Poet qw(:file);
    </%class>

=head1 DESCRIPTION

This group of utilities includes

=over

=item basename, dirname

From L<File::Basename|File::Basename>.

=item mkpath, make_path, rmtree, remove_tree

From L<File::Path|File::Path>.

=item read_file, write_file, read_dir

From L<File::Slurp|File::Slurp>.

=item abs2rel canonpath catdir catfile rel2abs

From L<File::Spec::Functions|File::Spec::Functions>.

=back
