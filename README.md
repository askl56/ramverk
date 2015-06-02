# Ramverk

The Ruby web framework.

## Status

[![Coverage Status](http://img.shields.io/coveralls/sandelius/ramverk/master.svg?style=flat)](https://coveralls.io/r/sandelius/ramverk?branch=master)
[![Build Status](http://img.shields.io/travis/sandelius/ramverk.svg?branch=master&style=flat)](https://travis-ci.org/sandelius/ramverk)
[![Code Climate](http://img.shields.io/codeclimate/github/sandelius/ramverk/badges/gpa.svg?style=flat)](https://codeclimate.com/github/sandelius/ramverk)


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ramverk'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ramverk

## Usage

```ruby
# config.ru
class PostsRouter < Ramverk::Router

  get '/', :index
  def index
    res.write('Hello World')
  end

  post '/', :create
  def create
    res.status(201).write('Resource Created')
  end
end

class App < Ramverk::Application
  use Rack::Head

  map '/posts', PostsRouter

  config[:session] = { secret: '<secret>' }

  configure :development do
    config[:raise_errors] = true
    config.security[:ip_spoofing] = false
  end
end

run App.new
```

## Contributing

1. Fork it ( https://github.com/sandelius/ramverk/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
