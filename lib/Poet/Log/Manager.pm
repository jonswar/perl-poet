package Poet::Log::Manager;
use Log::Any::Adapter;
use Poet::Moose;
use strict;
use warnings;

has 'env' => ( weak_ref => 1 );

method initialize_logging () {
    $self->_initialize_log4perl;
}

method _initialize_log4perl  () {
    require Log::Log4perl;
    unless ( Log::Log4perl->initialized() ) {
        my $config_string = $self->_generate_log4perl_config();
        Log::Log4perl->init( \$config_string );
        Log::Any::Adapter->set('Log4perl');
    }
}

method _generate_log4perl_config () {
    my $conf          = $self->env->conf;
    my %core_defaults = (
        level  => 'info',
        output => 'poet.log',
        layout => '%d{dd/MMM/yyyy:HH:mm:ss.SS} %c - %m - %F:%L%n'
    );
    my %defaults = ( %core_defaults, %{ $conf->get_hash('log.defaults') } );
    my %classes = %{ $conf->get_hash_from_common_prefix('log.class.') };
    foreach my $set ( values(%classes) ) {
        foreach my $key (qw(level output layout)) {
            $set->{$key} = $defaults{$key} if !exists( $set->{$key} );
        }
    }
    foreach my $set ( \%defaults, values(%classes) ) {
        if ( $set->{output} =~ /^(?:stderr|stdout)$/ ) {
            $set->{appender_class} = "Log::Log4perl::Appender::Screen";
            $set->{stderr} = 0 if $set->{output} eq 'stdout';
        }
        else {
            $set->{appender_class} = "Log::Log4perl::Appender::File";
            $set->{filename}       = $set->{output};
            $set->{filename}       = $self->env->logs_path( $set->{filename} )
              if $set->{filename} !~ m|^/|;
        }
    }
    return join(
        "\n",
        $self->_generate_lines( 'log4perl.logger', 'default', \%defaults ),
        map {
            $self->_generate_lines( "log4perl.logger.$_", $self->_flatten($_),
                $classes{$_} )
          } sort( keys(%classes) ),
    );
}

method _generate_lines ($logger, $appender, $set) {
    my $full_appender = "log4perl.appender.$appender";
    my @pairs         = (
        [ $logger => join( ", ", uc( $set->{level} ), $appender ) ],
        [ $full_appender          => $set->{appender_class} ],
        [ "$full_appender.layout" => 'Log::Log4perl::Layout::PatternLayout' ],
        [ "$full_appender.layout.ConversionPattern" => $set->{layout} ]
    );
    foreach my $key qw(filename stderr) {
        if ( exists( $set->{$key} ) ) {
            push( @pairs, [ "$full_appender.$key" => $set->{$key} ] );
        }
    }

    my $lines = join( "\n", map { join( " = ", @$_ ) } @pairs ) . "\n";
    return $lines;
}

method _flatten ($class_name) {
    $class_name =~ s/(::|\.)/_/g;
    return $class_name;
}

__PACKAGE__->meta->make_immutable();

1;

__END__
