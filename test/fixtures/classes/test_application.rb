class TestApplicationRouter < Ramverk::Router
  get '/hello', :hello
  def hello
    raise ArgumentError, "Boom!"
  end
end

class TestApplication < Ramverk::Application
  map TestApplicationRouter
end

class TestOnLoadApplication < Ramverk::Application

  before_load do |app|
    app.config[:first_name] = 'Tobias'
  end

  after_load do |app|
    app.config[:last_name] = 'Sandelius'
  end
end
