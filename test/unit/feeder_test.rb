require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class FeederTest < Test::Unit::TestCase

  def setup
  end 
 
  def teardown
  end
  
  def helper_swagger_find(swagger, path, method, parameter)
    swagger["apis"].each do |ep|
      if ep["path"]==path
        return ep if method.nil?
        ep["operations"].each do |op|
          if op["httpMethod"]==method
            return op if parameter.nil?
            op["parameters"].each do |par|
              if par["name"]==parameter
                return par
              end
            end
          end
        end  
      end
    end
    return nil
  end
  
  def test_extract_params
    
    f = Feeder.new()
    
    params = f.extract_params("foo=x&bar=y&", "application/x-www-form-urlencoded")
    assert_equal "x", params["foo"]
    assert_equal "y", params["bar"]
    
    params = f.extract_params("foo[]=x&foo[]=y&", "application/x-www-form-urlencoded")
    assert_equal ["x","y"].sort, params["foo"].sort

    params = f.extract_params("foo[bar]=x&foo[zoo]=y", "application/x-www-form-urlencoded")
    assert_equal Hash, params["foo"].class
    assert_equal "x", params["foo"]["bar"]
    assert_equal "y", params["foo"]["zoo"]
    
    params = f.extract_params("foo=42&&&", "application/x-www-form-urlencoded")
    assert_equal "42", params["foo"]
    
    params = f.extract_params(nil, "application/x-www-form-urlencoded")
    assert_equal 0, params.size
    
    params = f.extract_params("", "application/x-www-form-urlencoded")
    assert_equal 0, params.size

    params = f.extract_params(nil)
    assert_equal 0, params.size

    params = f.extract_params("")
    assert_equal 0, params.size
    
    params = f.extract_params("foo[bar]=x&foo[zoo]=y")
    assert_equal Hash, params.class
    assert_equal ["__body"], params.keys
    assert_equal ["foo[bar]=x&foo[zoo]=y"], params.values

    params = f.extract_params("{\"foo\": \"bar\"}")
    assert_equal Hash, params.class
    assert_equal ["__body"], params.keys
    assert_equal ["{\"foo\": \"bar\"}"], params.values

    params = f.extract_params({"foo" => {"bar" => "x", "zoo" => "y"}}, "application/x-www-form-urlencoded")
    assert_equal Hash, params["foo"].class
    assert_equal "x", params["foo"]["bar"]
    assert_equal "y", params["foo"]["zoo"]

    params = f.extract_params({"foo" => {"bar" => "x", "zoo" => "y"}})
    assert_equal Hash, params.class
    assert_equal ["__body"], params.keys
    assert_equal Hash, params["__body"]["foo"].class
    assert_equal "x", params["__body"]["foo"]["bar"]
    assert_equal "y", params["__body"]["foo"]["zoo"]
    
  end
  
  def test_process_straight_cases

    f = Feeder.new()
    
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
    
    f.process(valid_entry)
    
    swagger = f.spec("raw2swagger.3scale.net").to_swagger()
    swagger2 = f.spec("raw2swagger.3scale.net").to_swagger()
    swagger3 = f.to_swagger("raw2swagger.3scale.net")
    
    assert_equal swagger, swagger2
    assert_equal swagger, swagger3
    
    assert_equal valid_entry["host"], swagger["basePath"]
    assert_equal [], swagger["models"]
    assert_equal 1, swagger["apis"].size
    assert_equal valid_entry["path"], swagger["apis"].first["path"]
    assert_equal [], swagger["apis"].first["errorResponses"]
    
    assert_equal 1, swagger["apis"].first["operations"].size
    
    assert_equal valid_entry["method"], swagger["apis"].first["operations"].first["httpMethod"]
    assert_equal false, swagger["apis"].first["operations"].first["deprecated"]
    assert_equal 3, swagger["apis"].first["operations"].first["parameters"].size
    
    real_params = {"provider_key" => "foo", "page" => "30", "per_page" => "10"}
    
    swagger["apis"].first["operations"].first["parameters"].each do |param|
      assert_not_nil real_params[param["name"]]
      assert_equal "query", param["paramType"]
    end

    
    valid_entry = {
      "method" => "POST",
      "path" => "/admin/api/accounts.xml",
      "status" => 200,
      "query_string" => "",
      "body" => "provider_key=foo&name=hello&email=foo@3scale.net",
      "host" => "raw2swagger.3scale.net",
      "port" => 80,
      "headers" => {"Content-Type" => "application/x-www-form-urlencoded"}
    }
    
    f.process(valid_entry)
    
    swagger = f.spec("raw2swagger.3scale.net").to_swagger()
    
    endpoint = helper_swagger_find(swagger,"/admin/api/accounts.xml",nil,nil)
    assert_equal ["GET", "POST"].sort, [endpoint["operations"].first["httpMethod"], endpoint["operations"].last["httpMethod"]].sort 

    parameter = helper_swagger_find(swagger,"/admin/api/accounts.xml","POST","provider_key")
    assert_equal "provider_key", parameter["name"]
    assert_equal "query", parameter["paramType"]
    
    parameter = helper_swagger_find(swagger,"/admin/api/accounts.xml","POST","email")
    assert_equal "email", parameter["name"]
    assert_equal "query", parameter["paramType"]
    
    parameter = helper_swagger_find(swagger,"/admin/api/accounts.xml","POST","name")
    assert_equal "name", parameter["name"]
    assert_equal "query", parameter["paramType"]        
    
    parameter = helper_swagger_find(swagger,"/admin/api/accounts.xml","POST","Content-Type")
    assert_equal "Content-Type", parameter["name"]
    assert_equal "header", parameter["paramType"]
    
      
    valid_entry = {
      "method" => "GET",
      "path" => "/admin/api/accounts/___.xml",
      "status" => 200,
      "query_string" => "provider_key=foo",
      "body" => "",
      "host" => "raw2swagger.3scale.net",
      "port" => 80,
      "headers" => {}
    }
    
    5.times do |i|
      valid_entry["path"] = "/admin/api/accounts/#{10000+i}.xml"
      f.process(valid_entry)
    end

    swagger = f.spec("raw2swagger.3scale.net").to_swagger()
    assert_equal 2, swagger["apis"].size
    
    paths = ["/admin/api/accounts/{#{f.spec("raw2swagger.3scale.net").make_friendly_id("accounts")}}.xml",
              "/admin/api/accounts.xml"]
    
    paths.each do |p|
      endpoint = helper_swagger_find(swagger,p,nil,nil)
      assert_equal false, endpoint.nil?
    end          
    assert_equal 2, swagger["apis"].size
    
    parameters = helper_swagger_find(swagger,paths.first,"GET",nil)
    assert_equal 2, parameters["parameters"].size
    
    parameter = helper_swagger_find(swagger,paths.first,"GET","provider_key")
    assert_equal "query", parameter["paramType"]
    
    parameter = helper_swagger_find(swagger,paths.first,"GET",f.spec("raw2swagger.3scale.net").make_friendly_id("accounts"))
    assert_equal "path", parameter["paramType"]
    assert_equal true, parameter["required"]
    
    ##puts JSON.pretty_generate(f.spec("raw2swagger.3scale.net").to_swagger())
    
    valid_entry = {
       "method" => "POST",
       "path" => "/resource/1000.json",
       "status" => 200,
       "query_string" => "",
       "body" => {"id" => 10, "foo" => "bar"},
       "host" => "raw2swagger.3scale.net",
       "port" => 80,
       "headers" => {"Content-Type" => "application/json"}
     }
    
     f.process(valid_entry)
     
     swagger = f.spec("raw2swagger.3scale.net").to_swagger()
     assert_equal 3, swagger["apis"].size
     
     parameters = helper_swagger_find(swagger,"/resource/1000.json","POST",nil)
     
     assert_equal 2, parameters["parameters"].size
     
     parameter = helper_swagger_find(swagger,"/resource/1000.json","POST","__body")
     assert_equal "__body", parameter["name"]
     assert_equal "body", parameter["paramType"]

     parameter = helper_swagger_find(swagger,"/resource/1000.json","POST","Content-Type")
     assert_equal "header", parameter["paramType"]

  end
  
  def test_path_params
    
    f = Feeder.new()
    
    spec = f.create_spec("test.net")
    
    5.times do |i|
      path = "/api/accounts/#{10000+i}/applications/#{50000+i}.xml"
      spec.derivator.learn(path)    
    end
    assert_equal ["/api/accounts/#{Derivator::WILDCARD}/applications/#{Derivator::WILDCARD}.xml"], spec.derivator.paths()
    
    v = f.extract_path_params(spec, "/api/accounts/42/applications/13.xml")
    
    path_params = v[0]
    swagger_path = v[1]
    spec_path = v[2]
    
    assert_equal "/api/accounts/{#{spec.make_friendly_id("accounts")}}/applications/{#{spec.make_friendly_id("applications")}}.xml",  swagger_path
    assert_equal "/api/accounts/#{Derivator::WILDCARD}/applications/#{Derivator::WILDCARD}.xml", spec_path
    
    assert_equal "accounts_id", spec.make_friendly_id("accounts")
    assert_equal "applications_id", spec.make_friendly_id("applications")
    
    assert_equal 2, path_params.size()
    assert_equal "42", path_params[spec.make_friendly_id("accounts")]
    assert_equal "13", path_params[spec.make_friendly_id("applications")]
        
  end
  
  def test_process_invalid_inputs
    
    f = Feeder.new()
    
    valid_entry = {
      "method" => "GET",
      "path" => "/admin/api/accounts.xml",
      "status" => 200,
      "query_string" => "provider_key=foo&page=30%per_page=10",
      "body" => "",
      "host" => "raw2swagger.3scale.net",
      "port" => 80,
      "headers" => {}
    }
    
    assert_raise Exception do 
      invalid_entry = valid_entry.clone
      invalid_entry["headers"]=nil
      f.process(invalid_entry)
    end

    assert_raise Exception do 
      invalid_entry = valid_entry.clone
      invalid_entry["headers"]=""
      f.process(invalid_entry)
    end
    
    assert_raise Exception do 
      invalid_entry = valid_entry.clone
      invalid_entry["host"]=nil
      f.process(invalid_entry)
    end
    
  end
  
  def test_make_friendly_operation
    
    ## this is totally a heuristic, more than the rest (if that's possible)
    
    f = Feeder.new()
    spec = f.create_spec("test.net")
    
    ## get the last word before a *
    
    text = spec.make_friendly_operation("GET", "/v1/api/word/*")
    assert_equal "Get word by id", text

    text = spec.make_friendly_operation("GET", "/v1/api/word/*.json")
    assert_equal "Get word by id", text

    text = spec.make_friendly_operation("POST", "/v1/api/word.xml")
    assert_equal "Create word", text

    text = spec.make_friendly_operation("PUT", "/v1/api/word/*")
    assert_equal "Modify word by id", text

    text = spec.make_friendly_operation("DELETE", "/v1/api/word/*")
    assert_equal "Delete word by id", text
    
    text = spec.make_friendly_operation("DELETE", "/*.xml")
    assert_equal "Delete by id", text

    text = spec.make_friendly_operation("DELETE", "/")
    assert_equal "Delete", text
        
    
    ## if not one *, get the last word that is not format
    
    text = spec.make_friendly_operation("GET","/api/accounts.xml")
    assert_equal "List accounts", text

    text = spec.make_friendly_operation("GET","/api/accounts")
    assert_equal "List accounts", text

    text = spec.make_friendly_operation("POST","/api/accounts.xml")
    assert_equal "Create accounts", text
    
    text = spec.make_friendly_operation("PUT","/api/accounts.xml")
    assert_equal "Modify accounts", text

    text = spec.make_friendly_operation("DELETE","/api/accounts.xml")
    assert_equal "Delete accounts", text

    ## if combination word/*/action, we assume action is the verb, only on PUT (modification)
    
    text = spec.make_friendly_operation("PUT", "/v1/api/word/*/suspend")
    assert_equal "Suspend word by id", text

    text = spec.make_friendly_operation("PUT", "/v1/api/word/*/suspend.xml")
    assert_equal "Suspend word by id", text

    text = spec.make_friendly_operation("POST", "/v1/api/word/*/activate.xml")
    assert_equal "Create activate of word", text

    ## if more than one *
    
    text = spec.make_friendly_operation("GET", "/v1/api/account/*/application/*.xml")
    assert_equal "Get application of account", text

    text = spec.make_friendly_operation("DELETE", "/v1/api/account/*/application/*.xml")
    assert_equal "Delete application of account", text
    
    text = spec.make_friendly_operation("PUT", "/v1/api/account/*/application/*.xml")
    assert_equal "Modify application of account", text

    text = spec.make_friendly_operation("PUT", "/*/application/*.xml")
    assert_equal "Modify application", text
        
    text = spec.make_friendly_operation("POST", "/v1/api/account/*/application.xml")
    assert_equal "Create application of account", text

    ## more cases
    text = spec.make_friendly_operation("POST", "/v1")
    assert_equal "Create v1", text

    text = spec.make_friendly_operation("POST", "/")
    assert_equal "Create", text
    
    text = spec.make_friendly_operation("GET", "/v1")
    assert_equal "List v1", text

    text = spec.make_friendly_operation("GET", "/")
    assert_equal "List", text
  end  
    

  def test_log_file
        
    f = Feeder.new(:occurrences_threshold => 0.20, :skip_entries => 0)
    
    File.open(File.dirname(__FILE__) + '/../data/sample_api_traffic.log').each do |line|
      obj = JSON::parse(line)
      f.process(obj)
    end              

    expected_paths = [
      "/admin/api/accounts.xml",
      "/admin/api/accounts/*/applications.xml",
      "/admin/api/accounts/*/applications/*/suspend.xml",
      "/admin/api/accounts/*/applications/*/keys/*.xml",
      "/admin/api/accounts/*/applications/*/change_plan.xml",
      "/admin/api/accounts/*/applications/*.xml",
      "/admin/api/accounts/*/users/*/activate.xml",
      "/admin/api/accounts/*/users.xml",
      "/admin/api/accounts/*/approve.xml",
      "/admin/api/features.xml",
      "/admin/api/services/*/metrics/*/methods.xml",
      "/admin/api/applications/find.xml",
      "/admin/api/application_plans/*/features",
      "/stats/applications/*/usage.json"
    ]
      
    assert_equal expected_paths.sort(), f.spec("raw2swagger.3scale.net").derivator.paths().sort()
    
    swg =  f.spec("raw2swagger.3scale.net").to_swagger()   
    
    assert_equal expected_paths.size(), swg["apis"].size()
    
    check_for_repeats = {}
    swg["apis"].each do |ep|
      swg_path= ep["path"].gsub(/{[a-zA-Z0-9_-]+}*/,Derivator::WILDCARD)
      
      assert_equal true, expected_paths.include?(swg_path)
      assert_equal nil, check_for_repeats[ep["path"]]
      seen = ep["path"]
    end
        
        
  end  

end


