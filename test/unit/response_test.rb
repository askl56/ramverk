require 'test_helper'

describe Ramverk::Response do
  let(:res) { Ramverk::Response.new(TestApplication) }

  it 'has a content type by default' do
    result = catch :finished do
      res.write
    end
    result[1]['Content-Type'].must_equal 'text/plain'
  end

  it 'use application default headers' do
    res.header.must_equal({
      'Content-Type' => 'text/plain',
      'X-Frame-Options' => 'SAMEORIGIN',
      'X-XSS-Protection' => '1; mode=block',
      'X-Content-Type-Options' => 'nosniff'
    })
  end

  describe '#status' do
    it 'sets status and return self, it gets current status' do
      res.status(404).must_equal res
      res.status.must_equal 404
    end
  end

  describe '#header' do
    it 'it sets, and gets, a single header' do
      res.header('Location', 'https://google.com').must_equal res
      res.header('Location').must_equal 'https://google.com'
    end

    it 'sets multiple headers' do
      res.header('Location' => 'https://google.com', 'Content-Type' => 'text/html')
      res.header('Location').must_equal 'https://google.com'
      res.header('Content-Type').must_equal 'text/html'
    end

    it 'return all existing headers' do
      res.header('Location' => 'https://google.com', 'Content-Type' => 'text/html')
      res.header.size.must_equal 5
    end
  end

  describe '#content_type' do
    it 'sets a new content type and return self' do
      res.content_type(:json).must_equal res
      res.content_type.must_equal 'application/json'
    end

    it 'sets a raw type if string is given' do
      res.content_type('text/xml')
      res.content_type.must_equal 'text/xml'
    end
  end

  describe '#head' do
    it 'throws finished' do
      ->{ res.head 401 }.must_throw :finished
    end

    it 'creates an empty response body with only status and headers' do
      res.body('Hello')
      res.body.must_equal 'Hello'
      res.status.must_equal 200
      catch :finished do
        res.head 401
      end
      res.body.must_equal ''
      res.status.must_equal 401
    end
  end

  describe '#redirect' do
    it 'throws finished' do
      ->{ res.redirect('/another/path') }.must_throw :finished
    end

    it 'sets the location header' do
      catch :finished do
        res.redirect('/another/path')
      end
      res.status.must_equal 302
      res.header('Location').must_equal '/another/path'
    end
  end

  describe '#json' do
    it 'renders the raw string and sets status if given and json content-type' do
      catch :finished do
        res.json('{"hello":"world"}', status: 201)
      end
      res.status.must_equal 201
      res.type.must_equal 'application/json'
      res.body.must_equal '{"hello":"world"}'
    end

    it 'generate json from the data' do
      catch :finished do
        res.json([{hello: 'world'}])
      end
      res.body.must_equal '[{"hello":"world"}]'
    end

    it 'uses as_json if available' do
      catch :finished do
        res.json(JSONObject1.new)
      end

      res.body.must_equal '{"name":"first"}'
    end

    it 'uses map and as_json if available' do
      catch :finished do
        res.json([JSONObject1.new, JSONObject2.new])
      end

      res.body.must_equal '[{"name":"first"},{"name":"second"}]'
    end

    it 'sets a root if available' do
      catch :finished do
        res.json([JSONObject1.new, JSONObject2.new], root: 'data')
      end

      res.body.must_equal '{"data":[{"name":"first"},{"name":"second"}]}'
    end

    it 'sets meta available meta and root is available' do
      catch :finished do
        res.json([JSONObject1.new, JSONObject2.new], root: 'data', meta: {current_page: 0})
      end

      res.body.must_equal '{"data":[{"name":"first"},{"name":"second"}],"meta":{"current_page":0}}'
    end
  end

  describe '#finish' do
    [204, 205, 304].each do |code|
      it "removes type and length header if status is #{code}" do
        res.header('Content-Type' => 'text/plain', 'Content-Length' => '5')
        res.status(code)

        catch :finished do
          res.write('hello')
        end

        res.header('Content-Type').must_equal nil
        res.header('Content-Length').must_equal nil
        res.body.must_equal ''
      end
    end
  end
end
