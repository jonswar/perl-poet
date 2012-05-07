has 'content';
has 'title';

method handle () {
    my $session = $m->session;
    if ( !$.content || !$.title ) {
        $session->{message}   = "Content and title required.";
        $session->{form_data} = $.args;
        $m->redirect('/new_article');
    }
    my $article = Blog::Article->new(
        title       => $.title,
        content     => $.content,
        create_time => DateTime->now( time_zone => 'local' )
    );
    $article->save;
    $session->{message} = sprintf( "Article '%s' saved.", $.title );
    $m->redirect('/');
}

