class TestRoutersRouter < Ramverk::Router
  get '/', :index
  def index
    res.write('hello')
  end
end

class TestRouters2Router < Ramverk::Router
  get '/say/:word', :say
  def say
    res.write(params['word'])
  end

  get '/rack/yeah', :rack
  def rack
    res.write('hello from router')
  end
end

class TestNoResponseTestRouter < Ramverk::Router
  post '/', :create
  def create
  end
end
