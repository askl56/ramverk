class TestErrorsRouter < Ramverk::Router
  error ArgumentError, :error_500
  def error_500(e = nil)
    res.status(500).write('[500] Kaboom!')
  end
end

class TestErrorsParentRouter < TestErrorsRouter
  get '/test', :test
  def test
    raise ArgumentError, "Boom!"
  end
end
