class TestRouter < Ramverk::Router
  get '/', :index
  def index
    res.write 'Hello World'
  end
  get '/:id', :show
  def show
    res.write "post-#{params['id']}"
  end
end

class TestParentRouter < TestRouter
  get '/unknown', :unknown
  post '', :create
  def create
  end
end
