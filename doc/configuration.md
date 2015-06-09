# Configuration

#### `raise_errors`
Allow exceptions to be thrown. This is not recommended in production and is diabled by default. To
enable it in `development` and `test` set the following:

```ruby
configure :development, :test do
  config.raise_errors true
end
```

#### `sessions`
Session management is not enabled by default but it's easy to enable. The only required key
is `secret`.

```ruby
config.sessions(
  key: 'rack.session',
  domain: 'foo.com',
  path: '/',
  expire_after: 2592000,
  secret: 'change_me',
  old_secret: 'also_change_me'
)
```

#### `default_headers`
Default headers that's sent to the client. You can add, remove or change how you like.

```ruby
config.response.default_headers.merge!(
  'Content-Type' => 'text/plain',
  'X-Frame-Options' => 'DENY',
  'X-XSS-Protection' => '1; mode=block',
  'X-Content-Type-Options' => 'nosniff'
)
```

#### `json_renderer`
JSON renderer to be used when generating JSON via `res.json` in actions.

```ruby
config.json_renderer ->(data) { JSON.generate(data) } # (Default)
config.json_renderer ->(data) { Oj.dump(data, mode: :compat) }
```

## View

#### `view.paths`
Paths to where view templates is located. Paths are empty by default.

```ruby
config.view.paths << "#{Ramverk.root}/app/views"
```

#### `view.engine`
Template engine to be used.

```ruby
config.view.engine :erb # (Default)
config.view.engine :slim
config.view.engine :haml
```

Make sure you add the engine gem in your `Gemfile`. This is not needed when using `:erb`, the default, since it comes with Ruby.

#### `view.layout`
Name of the default layout to be used. Layouts are disabled by defalt.

```ruby
config.view.layout nil # (Default)
config.view.layout 'default'
```

#### `view.layouts_dir`
Name of the default layout to be used. Layouts are disabled by default. The dir name is appended the the added `paths` when searching for a layout.

```ruby
config.view.layouts_dir 'layouts' # (Default)
config.view.layouts_dir 'another_folder'
```

#### `view.cache`
Template cache to be used. By default it uses `Tilt::Cache` that store compiled templates in memory. Cache objects must implement `fetch(key, &block)` and `clear`.

```ruby
config.view.cache Tilt::Cache.new # (Default)
config.view.cache MyCustomCache.new
```

#### `view.reload_templates`
Clear template cache upon each request. This is disabled by default but useful during development.

```ruby
config.view.reload_templates false # (Default)
config.view.reload_templates true
```

To clear template cache, in development, on each request enable it in a configure block:

```ruby
configure :development do
  config.view.reload_templates true
end
```
