class TestCallbacksRouter < Ramverk::Router
  before :stop

  get '/', :index
  def index
    res.write 'Hello World'
  end

  private def stop
    res.write('stop')
  end
end

class TestCallbacksParentRouter < TestCallbacksRouter
  skip_before :stop, only: :hit

  get '/stopped', :stopped
  def stopped
    res.write 'stopped'
  end
  get '/hit', :hit
  def hit
    res.write 'hit'
  end
end
