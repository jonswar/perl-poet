<%augment wrap>
  <html>
    <head>
      <link rel="stylesheet" href="/static/css/mwiki.css">
      <title>My Blog</title>
    </head>
    <body>
% if (my $message = delete($m->session->{message})) {
      <div class="message"><% $message %></div>
% }      
      <% inner() %>
    </body>
  </html>
</%augment>
