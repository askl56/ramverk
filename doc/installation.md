# Installation

## Starting a new project
Ramverk does not force to use any kind of folder structure. It does have a sanbox application that can be cloned to make it easy to get started.

### Sandbox

To use the sandbox application open you terminal and navigate to a location you want to create your project in then run the following:

```bash
git clone git@github.com:ramverk/sandbox.git app_name
```

Then cd into it and run `bundle install`

```bash
cd my_app && bundle install
```

### Manual

So you want to create your own folder structure? Good for you but make sure you atleast have a structure or else things might get out of hand once your project grows.

Add this line to your application's Gemfile:

```ruby
gem 'ramverk'
```

And then execute:

```bash
$ bundle install
```

Create a `config.ru` in your project root and add the following:

```ruby
require 'bundler/setup'
require 'ramverk'

class HomeRouter < Ramverk::Router
  get '/', :home
  def home
    res.write 'Hello World'
  end
end

class Application < Ramverk::Application
  map HomeRouter
end

Application.load
run Application

```

## Check it out

For the purposes of this guide, we'll be using Rack's builtin `rackup` bin. It will use `webrick` if nothing else is specified inside your `Gemfile`.

Make sure your're inside you project root, then run:

```bash
rackup
```

There you go, pretty easy right?
