require 'rake'
require 'rake/testtask'
require 'bundler/gem_tasks'

Rake::TestTask.new do |t|
  t.pattern = 'test/**/*_test.rb'
  t.libs.push 'test'
end

namespace :test do
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task['test'].invoke
  end
end

task default: :test

# class PagesController
#   include Ramverk::Controller
#   include Ramverk::Controller::Callbacks
#   include Ramverk::Controller::Rescuer # Keep at bottom

#   get '/home'
#   def index
     # response.status(404).json({})
#   end
# end


# class MyApp < Ramverk::Application
#   mount HomeController
#   mount '/pages/:page_id', PagesController

#   mount '/api', Controllers::PagesController
#   mount '/api/workspaces', Controllers::WorkspacesController # root = /api/workspaces
# end
