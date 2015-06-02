require 'test_helper'

describe Ramverk::Response do
  let(:res) { Ramverk::Response.new }

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
      res.header.size.must_equal 2
    end
  end

  describe '#content_type' do
    it 'sets a new content type and return self' do
      res.content_type(:json).must_equal res
      res.content_type.must_equal 'application/json'
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
