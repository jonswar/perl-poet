package Poet::Util::File;
use File::Basename qw(basename dirname);
use File::Path qw(make_path remove_tree);
use File::Slurp qw(read_dir read_file write_file);
use File::Spec::Functions qw(abs2rel canonpath catdir catfile rel2abs);
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK =
  qw(abs2rel basename canonpath catdir catfile dirname make_path read_dir read_file rel2abs remove_tree write_file);
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

=item make_path, remove_tree

From L<File::Path|File::Path>.

=item read_file, write_file, read_dir

From L<File::Slurp|File::Slurp>.

=item abs2rel canonpath catdir catfile rel2abs

From L<File::Spec::Functions|File::Spec::Functions>.

=back
