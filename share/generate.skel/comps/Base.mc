<%text>
<%class>
has 'title' => (default => 'My site');
</%class>

<%augment wrap>
  <html>
    <head>
      <link rel="stylesheet" href="/static/css/style.css">
% $.Defer {{
      <title><% $.title %></title>
% }}
    </head>
    <body>
      <% inner() %>
    </body>
  </html>
</%augment>
</%text>
