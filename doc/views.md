# Views

View rendering is not enabled by default. There's two things you need to do:

In your main application file require `ramverk/view`.

```ruby
require 'ramverk/view'
```

Then you need to include the `Ramverk::View` module in your router. If you have an `AppRouter` you can put it there and it will be available for you in all routers that inherits from that one.

```ruby
class PagesRouter < Ramverk::Router
  include Ramverk::View

  get '/', :index
  def index
    posts = [{title: 'Hello'}, {title: 'World'}]
    render 'pages/index', posts: posts
  end
end
```

```html
# /path/to/views/pages/index.erb
<article>
  <% posts.each do |post| %>
    <h2><%= post[:title] %></h2>
  <% end %>
</article>
```

## Layouts

Templates can live inside a layout and be outputted via a `yield` statement. Layouts are disabled by default. To enable layouts globally you need to set the default, layout, name in the configurations:

```ruby
class Application < Ramverk::Application
  config.view.layout 'default'
end
```

We can enable the use of a layout locally as well:

```ruby
class PagesRouter < Ramverk::Router
  include Ramverk::View

  get '/', :index
  def index
    posts = [{title: 'Hello'}, {title: 'World'}]
    render 'pages/index', layout: 'default', posts: posts
  end
end
```

```html
# /path/to/views/layouts/default.erb
<!DOCTYPE html>
<html>
<head>
  <title>LAYOUT</title>
</head>
<body>
  <%= yield %>
</body>
</html>
```

Now the `pages/index.erb` template is rendered from the `yield` statement.

If layouts are enabled by default you can disable it locally by setting `layout: false` in the `render` options hash.

```ruby
res.render 'pages/index', layout: false, posts: posts
```

## Partials

We can render partials from within a template using the `render` method:

```html
# /path/to/views/pages/_title.erb
<h2><%= title %></h2>
```

```html
# /path/to/views/pages/index.erb
<article>
  <% posts.each do |post| %>
    <%= render 'pages/_title', title: post[:title] %>
  <% end %>
</article>
```

What its actually does is calling the `render_to_string` method that's available in the router.

The `render_to_string` method is also useful in actions if you want to render a template to a string:

```ruby
def index
  html = render_to_string('pages/index')
end
```
