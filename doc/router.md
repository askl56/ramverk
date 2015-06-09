# Router
Routers in Ramverk is a combination between a controller and routes. You define the route and tell what action to map it to.

_In all examples below `res` used when interacting with the response object. `res` is an alias for the `response` method._

```ruby
class PagesRouter < Ramverk::Router
  get '/', :index
  def index
    res.write('Hello World')
  end
end
```

Route paths can also have dynamic segments and they'll be available in the `params` hash.

```ruby
get '/posts/:id', :show
def show
  res.write("You're reading post: #{params['id]}")
end
```

When an action calls a method in `res` that renders a response the code execution in your action stops and the response is returned to the client. Those methods are:

```ruby
res.write
res.head
res.json
res.redirect
```

If `Ramverk::View` is included an extra "halt" method is added to the router itself. It's the `render` method that is used to render view templates. Once an action has called `render` it stops and return the rendered template to the client.

## RESTful routes
When you define routes you have several methods to choose from. They all are named after the request method they represent.

`get` `post` `put` `patch` `delete` `options` `link` `unlink`

To create a new route that responds to a `POST` request write this:

```ruby
post '/items', :create
def create
  res.status(201).write('Resource Created')
end
```

## Before callbacks

Callbacks are methods that are run before the requested action. Callbacks are inherited, so if you set a filter on AppRouter, it will be run on every router that inherits from that.

Callbacks may halt the request cycle if they render a response. A common usecase for this is to check if a user is authenticated or not:

```ruby
class AppRouter < Ramverk::Router
  before :authenticate

  private def authenticate
    res.redirect('/login') unless current_user
  end
end
```

This will halt the request and redirect to the `/login` path whenever the current user is not logged in. Somethimes we need to skip a callback just for certain a router or even a single action. That's whan `skip_before` comes in.

Take the scenario when you don't require a user to be authenticated when e.g trying to log out:

```ruby
class SessionsRouter < AppRouter
  skip_before :authenticate, only: :destroy

  get '/logout', :destroy
  def destroy

  end
end
```

If you have many actions and you want to skip the callback on all but one, use `except: :my_action` instead of `:only`. If not options hashis given it will skip the callback on all actions in the given router. Both `:only` and `:except` accept an array in order to define multiple actions.
