require File.dirname(__FILE__) + "/lib/raw2swagger.rb"
Rack::Handler::Thin.run(Raw2Swagger::Server.new, :Port => 10901)
