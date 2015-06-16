class TestApplicationRouter < Ramverk::Router
  get '/raise', :raise
  def raise
    raise ArgumentError, "Boom!"
  end

  get '/noraise', :noraise
  def noraise
    raise ArgumentError, "Boom!"
  end
end

class TestApplication < Ramverk::Application
end

class BodyParserTestRouter < Ramverk::Router
  post '/body-parser', :create
  def create
    res.write("#{params[:username]}-#{params[:password]}")
  end
end
