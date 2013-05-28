require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ServerTest < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    Server.new
  end
  
  def setup
  end 
 
  def teardown
  end
  
  def test_process_and_to_swagger_via_http
    
    valid_entry = {
      "method" => "GET",
      "path" => "/admin/api/accounts.xml",
      "status" => 200,
      "query_string" => "provider_key=foo&page=30&per_page=10",
      "body" => "",
      "host" => "raw2swagger.3scale.net",
      "port" => 80,
      "headers" => {}
    }
        
    post '/process', valid_entry.to_json 
    assert_equal 200, last_response.status
    
    get '/to_swagger', "args[]=#{valid_entry['host']}"
    assert_equal 200, last_response.status
    swagger_from_http = JSON::parse(last_response.body)
    
    f = Feeder.new()
    f.process(valid_entry)
    swagger_from_obj = f.to_swagger(valid_entry['host'])
    
    assert_equal swagger_from_http, swagger_from_obj
    
  end
end
  
  
