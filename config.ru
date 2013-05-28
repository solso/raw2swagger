require File.dirname(__FILE__) + "/lib/raw2swagger.rb"
Rack::Handler::Mongrel.run Raw2Swagger::Server.new 
