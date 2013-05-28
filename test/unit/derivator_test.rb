require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class DerivatorTest < Test::Unit::TestCase

  def setup
  end 
 
  def teardown
  end
  
  def test_find
    
    g = Derivator.new()
    
    g.add("/users/foo/activate.xml")
    g.add("/applications/foo/activate.xml")

    g.add("/applications/foo2/activate.xml")
    g.add("/applications/foo3/activate.xml")

    g.add("/users/foo4/activate.xml")
    g.add("/users/foo5/activate.xml")

    g.add("/applications/foo4/activate.xml")
    g.add("/applications/foo5/activate.xml")

    g.add("/services/foo5/activate.xml")
    g.add("/fulanitos/foo5/activate.xml")

    g.add("/fulanitos/foo6/activate.xml")
    g.add("/fulanitos/foo7/activate.xml")
    g.add("/fulanitos/foo8/activate.xml")

    g.add("/services/foo6/activate.xml")
    g.add("/services/foo7/activate.xml")
    g.add("/services/foo8/activate.xml")
    
    v = g.paths()
    
    assert_equal ["/#{Derivator::WILDCARD}/foo/activate.xml", 
      "/#{Derivator::WILDCARD}/foo5/activate.xml", 
      "/applications/#{Derivator::WILDCARD}/activate.xml", 
      "/users/#{Derivator::WILDCARD}/activate.xml", 
      "/fulanitos/#{Derivator::WILDCARD}/activate.xml", 
      "/services/#{Derivator::WILDCARD}/activate.xml"].sort, v.sort
    
    g.clashes.each do |p, v|
      assert_equal v.size + 1, g.find(p).size
    end
      
    assert_equal ["/fulanitos/#{Derivator::WILDCARD}/activate.xml"], g.find("/fulanitos/whatever/activate.xml")
    assert_equal g.paths.sort, g.find("/#{Derivator::WILDCARD}/#{Derivator::WILDCARD}/activate.xml").sort
    assert_equal g.paths.sort, g.find("/#{Derivator::WILDCARD}/#{Derivator::WILDCARD}/#{Derivator::WILDCARD}.xml").sort
    assert_equal [], g.find("/")
    assert_equal [], g.find("/#{Derivator::WILDCARD}/#{Derivator::WILDCARD}/activate.xml.whatever")
    assert_equal ["/#{Derivator::WILDCARD}/foo/activate.xml"], g.find("/whatever/foo/activate.xml")
    assert_equal ["/#{Derivator::WILDCARD}/foo5/activate.xml"], g.find("/whatever/foo5/activate.xml")    
    assert_equal [], g.find("/whatever/foo_not_there/activate.xml")
            
  end
  
  def test_remove_regression_test
    
    g = Derivator.new
    
    g.spec = {"root"=>{"services"=> {
                "foo6"=>{"#{Derivator::WILDCARD}"=>{".xml" => {Derivator::EOL=>{}}}}, 
                "foo7"=>{"#{Derivator::WILDCARD}"=>{".xml" => {Derivator::EOL=>{}}}}, 
                "foo8"=>{"#{Derivator::WILDCARD}"=>{".xml" => {Derivator::EOL=>{}}}}, 
                "foo9"=>{"#{Derivator::WILDCARD}"=>{".xml" => {Derivator::EOL=>{}}}}, 
                "#{Derivator::WILDCARD}"=>{
                  "suspend"=>{".xml"=>{Derivator::EOL=>{}}}, 
                  "activate"=>{".xml"=>{Derivator::EOL=>{}}}, 
                  "deactivate"=>{".xml"=>{Derivator::EOL=>{}}}}}}}
    
    assert_equal ["/services/#{Derivator::WILDCARD}/activate.xml", 
      "/services/#{Derivator::WILDCARD}/deactivate.xml", 
      "/services/#{Derivator::WILDCARD}/suspend.xml", 
      "/services/foo6/#{Derivator::WILDCARD}.xml", 
      "/services/foo7/#{Derivator::WILDCARD}.xml", 
      "/services/foo8/#{Derivator::WILDCARD}.xml", 
      "/services/foo9/#{Derivator::WILDCARD}.xml"].sort, g.paths.sort
    
    g.remove("/services/#{Derivator::WILDCARD}/activate.xml")
    
    assert_equal ["/services/#{Derivator::WILDCARD}/deactivate.xml", 
      "/services/#{Derivator::WILDCARD}/suspend.xml", 
      "/services/foo6/#{Derivator::WILDCARD}.xml", 
      "/services/foo7/#{Derivator::WILDCARD}.xml", 
      "/services/foo8/#{Derivator::WILDCARD}.xml", 
      "/services/foo9/#{Derivator::WILDCARD}.xml"].sort, g.paths.sort
    
    
  end
  
  def test_remove
    
    g = Derivator.new()
    
    g.add("/users/foo/activate.xml")
    g.add("/applications/foo/activate.xml")

    g.add("/applications/foo2/activate.xml")
    g.add("/applications/foo3/activate.xml")

    g.add("/users/foo4/activate.xml")
    g.add("/users/foo5/activate.xml")

    g.add("/applications/foo4/activate.xml")
    g.add("/applications/foo5/activate.xml")

    g.add("/services/foo5/activate.xml")
    g.add("/fulanitos/foo5/activate.xml")

    g.add("/fulanitos/foo6/activate.xml")
    g.add("/fulanitos/foo7/activate.xml")
    g.add("/fulanitos/foo8/activate.xml")

    g.add("/services/foo6/activate.xml")
    g.add("/services/foo7/activate.xml")
    g.add("/services/foo8/activate.xml")

         
    assert_equal ["/#{Derivator::WILDCARD}/foo/activate.xml", 
      "/#{Derivator::WILDCARD}/foo5/activate.xml", 
      "/applications/#{Derivator::WILDCARD}/activate.xml", 
      "/users/#{Derivator::WILDCARD}/activate.xml", 
      "/fulanitos/#{Derivator::WILDCARD}/activate.xml", 
      "/services/#{Derivator::WILDCARD}/activate.xml"].sort, g.paths().sort
      
    assert_equal true, g.remove("/#{Derivator::WILDCARD}/foo5/activate.xml")
    
    assert_equal ["/#{Derivator::WILDCARD}/foo/activate.xml",  
      "/applications/#{Derivator::WILDCARD}/activate.xml", 
      "/users/#{Derivator::WILDCARD}/activate.xml", 
      "/fulanitos/#{Derivator::WILDCARD}/activate.xml", 
      "/services/#{Derivator::WILDCARD}/activate.xml"].sort, g.paths().sort
    
    assert_equal true, g.remove("/services/#{Derivator::WILDCARD}/activate.xml")

    assert_equal ["/#{Derivator::WILDCARD}/foo/activate.xml",  
      "/applications/#{Derivator::WILDCARD}/activate.xml", 
      "/users/#{Derivator::WILDCARD}/activate.xml", 
      "/fulanitos/#{Derivator::WILDCARD}/activate.xml"].sort, g.paths().sort
  
    ## remove only works for exact paths, not for matches
    assert_equal false, g.remove("/#{Derivator::WILDCARD}/#{Derivator::WILDCARD}/activate.xml")
    
  end
  
  def test_learn
    
    g = Derivator.new()

    g.learn("/users/foo/activate.xml")
    assert_equal ["/users/foo/activate.xml"].sort, g.paths().sort 
    
    g.learn("/applications/foo/activate.xml")
    assert_equal ["/#{Derivator::WILDCARD}/foo/activate.xml"].sort, g.paths().sort 
    
    
    g.learn("/applications/foo2/activate.xml")
    g.learn("/applications/foo3/activate.xml")
    
    g.learn("/users/foo4/activate.xml")

    g.learn("/users/foo5/activate.xml")
    g.learn("/users/foo6/activate.xml")
    g.learn("/users/foo7/activate.xml")

    assert_equal ["/#{Derivator::WILDCARD}/foo/activate.xml", 
      "/users/#{Derivator::WILDCARD}/activate.xml",
      "/applications/#{Derivator::WILDCARD}/activate.xml"
      ].sort, g.paths().sort

    g.learn("/users/foo/activate.xml")
    
    ## but after seeing some, we got it back
    assert_equal ["/users/#{Derivator::WILDCARD}/activate.xml",
      "/applications/#{Derivator::WILDCARD}/activate.xml"
      ].sort, g.paths().sort
    
    g.learn("/applications/foo4/activate.xml")
    g.learn("/applications/foo5/activate.xml")

    g.learn("/services/bar5/activate.xml")
    g.learn("/fulanitos/bar5/activate.xml")

    g.learn("/fulanitos/bar6/activate.xml")
    g.learn("/fulanitos/bar7/activate.xml")
    g.learn("/fulanitos/bar8/activate.xml")

    g.learn("/services/foo6/activate.xml")
    g.learn("/services/foo7/activate.xml")
    g.learn("/services/foo8/activate.xml")

    g.learn("/applications/foo4/activate.xml")
    g.learn("/applications/foo5/activate.xml")

    g.learn("/services/bar5/activate.xml")
    g.learn("/fulanitos/bar5/activate.xml")

    g.learn("/fulanitos/bar6/activate.xml")
    g.learn("/fulanitos/bar7/activate.xml")
    g.learn("/fulanitos/bar8/activate.xml")

    g.learn("/services/bar6/activate.xml")
    g.learn("/services/bar7/activate.xml")
    g.learn("/services/bar8/activate.xml")
    

    assert_equal [ 
      "/applications/#{Derivator::WILDCARD}/activate.xml", 
      "/users/#{Derivator::WILDCARD}/activate.xml", 
      "/fulanitos/#{Derivator::WILDCARD}/activate.xml", 
      "/services/#{Derivator::WILDCARD}/activate.xml"].sort, g.paths().sort
      
      
    assert_equal ["/services/#{Derivator::WILDCARD}/activate.xml"], g.find("/services/foo8/activate.xml")
    assert_equal ["/services/#{Derivator::WILDCARD}/activate.xml"], g.find("/services/foo18/activate.xml")
    
    assert_equal [], g.find("/services/foo8/activate.json")
    assert_equal [], g.find("/ser/foo8/activate.xml")
        
  end
  
  def test_last_mile_learn
    
    g = Derivator.new()
    
    g.learn("/services/foo6/activate.xml")
    g.learn("/services/foo7/activate.xml")
    g.learn("/services/foo8/activate.xml")
    
    assert_equal ["/services/#{Derivator::WILDCARD}/activate.xml"].sort, g.paths().sort
    
    g.learn("/services/foo6/deactivate.xml")
    g.learn("/services/foo7/deactivate.xml")
    g.learn("/services/foo8/deactivate.xml")
    
    assert_equal ["/services/#{Derivator::WILDCARD}/activate.xml", 
      "/services/#{Derivator::WILDCARD}/deactivate.xml"
      ].sort, g.paths().sort
   
    g.learn("/services/foo/60.xml")
    g.learn("/services/foo/61.xml")
    g.learn("/services/foo/62.xml")

    assert_equal ["/services/#{Derivator::WILDCARD}/activate.xml", 
      "/services/#{Derivator::WILDCARD}/deactivate.xml", 
      "/services/foo/#{Derivator::WILDCARD}.xml"
      ].sort, g.paths().sort
      
  end
  
  def test_behaviour_0
    
    g = Derivator.new()
    
    g.add("/services/foo6/activate.xml")
    g.add("/services/foo7/activate.xml")
    g.add("/services/foo8/activate.xml")
    
    assert_equal ["/services/#{Derivator::WILDCARD}/activate.xml"].sort, g.paths().sort
    
    g.add("/services/foo6/dectivate.xml")
    g.add("/services/foo7/dectivate.xml")
    g.add("/services/foo8/dectivate.xml")
    
    g.add("/services/foo/60.xml")
    g.add("/services/foo/61.xml")
    g.add("/services/foo/62.xml")
    
  end
  
  def test_occurrences_threshold
    
    ## the default, merge at will
    g = Derivator.new(:occurrences_threshold => 1.0)
    
    g.learn("/services/foo6/activate.xml")
    g.learn("/services/foo6/deactivate.xml")
    g.learn("/services/foo7/activate.xml")
    g.learn("/services/foo7/deactivate.xml")
    g.learn("/services/foo8/activate.xml")
    g.learn("/services/foo8/deactivate.xml")
    
    assert_equal ["/services/foo6/#{Derivator::WILDCARD}.xml",
      "/services/foo7/#{Derivator::WILDCARD}.xml",
      "/services/foo8/#{Derivator::WILDCARD}.xml"
      ].sort, g.paths().sort
    
    ## never merge 
    g = Derivator.new(:occurrences_threshold => 0.0)
    
    g.learn("/services/foo6/activate.xml")
    g.learn("/services/foo6/deactivate.xml")
    g.learn("/services/foo7/activate.xml")
    g.learn("/services/foo7/deactivate.xml")
    g.learn("/services/foo8/activate.xml")
    g.learn("/services/foo8/deactivate.xml")

    assert_equal ["/services/foo6/activate.xml",
      "/services/foo6/deactivate.xml",
      "/services/foo7/activate.xml",
      "/services/foo7/deactivate.xml",
      "/services/foo8/activate.xml",
      "/services/foo8/deactivate.xml"
      ].sort, g.paths().sort
      
    g = Derivator.new(:occurrences_threshold => 0.2)
    ## fake the hist, so that the words that are not var are seen more often
    ## the threshold 0.2 means that only merge if word is 5 (=1/0.2) times less frequent
    ## than the most common word 
    g.hist = {"services" => 20, "activate" => 10, "deactivate" => 10, 
      "foo6" => 1, "foo7" => 1, "foo8" => 1}
      
    g.learn("/services/foo6/activate.xml")
    g.learn("/services/foo6/deactivate.xml")
    g.learn("/services/foo7/activate.xml")
    g.learn("/services/foo7/deactivate.xml")
    g.learn("/services/foo8/activate.xml")
    g.learn("/services/foo8/deactivate.xml")
      
    
    assert_equal ["/services/#{Derivator::WILDCARD}/activate.xml", 
      "/services/#{Derivator::WILDCARD}/deactivate.xml"
      ].sort, g.paths().sort  
      
  end
  
  def test_unmergeable_words
    
    g = Derivator.new(:unmergeable_words => ["activate", "deactivate"])
    
    g.add("/services/foo6/activate.xml")
    g.add("/services/foo6/deactivate.xml")
    
    assert_equal ["/services/foo6/activate.xml",
      "/services/foo6/deactivate.xml"
      ].sort, g.paths().sort
    
    g.add("/services/foo7/activate.xml")
    g.add("/services/foo7/deactivate.xml")
    
    g.add("/services/foo8/activate.xml")
    g.add("/services/foo8/deactivate.xml")
    
    assert_equal ["/services/#{Derivator::WILDCARD}/activate.xml", 
      "/services/#{Derivator::WILDCARD}/deactivate.xml"
      ].sort, g.paths().sort
    
    ## without unmergeable words
    
    g = Derivator.new()
    
    g.add("/services/foo6/activate.xml")
    g.add("/services/foo6/deactivate.xml")
    
    assert_equal ["/services/foo6/#{Derivator::WILDCARD}.xml"].sort, g.paths().sort
    
    g.add("/services/foo7/activate.xml")
    g.add("/services/foo7/deactivate.xml")
    
    g.add("/services/foo8/activate.xml")
    g.add("/services/foo8/deactivate.xml")
    
    assert_equal ["/services/foo6/#{Derivator::WILDCARD}.xml",
      "/services/foo7/#{Derivator::WILDCARD}.xml",
      "/services/foo8/#{Derivator::WILDCARD}.xml"
      ].sort, g.paths().sort
    
  end
  
  

  def test_behaviour
    
    g = Derivator.new()
    
    g.learn("/services/foo6/activate.xml")
    g.learn("/services/foo6/deactivate.xml")
    
    assert_equal ["/services/foo6/#{Derivator::WILDCARD}.xml"].sort, g.paths().sort

    g.learn("/services/foo6/activate.xml")
    g.learn("/services/foo6/deactivate.xml")
    
    g.learn("/services/foo7/activate.xml")
    g.learn("/services/foo7/deactivate.xml")
    
    g.learn("/services/foo8/activate.xml")
    g.learn("/services/foo8/deactivate.xml")

    g.learn("/services/foo9/activate.xml")
    g.learn("/services/foo9/deactivate.xml")

    assert_equal ["/services/foo6/#{Derivator::WILDCARD}.xml", 
      "/services/foo7/#{Derivator::WILDCARD}.xml", 
      "/services/foo8/#{Derivator::WILDCARD}.xml", 
      "/services/foo9/#{Derivator::WILDCARD}.xml"].sort, g.paths().sort
        
    g.learn("/services/foo1/activate.xml")
    g.learn("/services/foo2/activate.xml")
    
    assert_equal ["/services/#{Derivator::WILDCARD}/activate.xml",
      "/services/foo6/#{Derivator::WILDCARD}.xml", 
      "/services/foo7/#{Derivator::WILDCARD}.xml", 
      "/services/foo8/#{Derivator::WILDCARD}.xml", 
      "/services/foo9/#{Derivator::WILDCARD}.xml"].sort, g.paths().sort
    
    5.times do 
      g.learn("/services/#{rand(10)}/deactivate.xml")
      g.learn("/services/#{rand(10)}/activate.xml")
    end
    
    assert_equal ["/services/#{Derivator::WILDCARD}/activate.xml", 
      "/services/#{Derivator::WILDCARD}/deactivate.xml",
      "/services/foo6/#{Derivator::WILDCARD}.xml",
      "/services/foo7/#{Derivator::WILDCARD}.xml",
      "/services/foo8/#{Derivator::WILDCARD}.xml",
      "/services/foo9/#{Derivator::WILDCARD}.xml"      
      ].sort, g.paths().sort
    
    
    g.learn("/services/foo6/activate.xml") 
    g.learn("/services/foo7/activate.xml") 
    g.learn("/services/foo8/deactivate.xml") 
    g.learn("/services/foo9/deactivate.xml") 
     
    assert_equal ["/services/#{Derivator::WILDCARD}/activate.xml", 
      "/services/#{Derivator::WILDCARD}/deactivate.xml"
      ].sort, g.paths().sort
    
  end
  
  def test_behaviour_2
    
    g = Derivator.new()
    
    g.learn("/admin/api/features.xml")
    g.learn("/admin/api/applications.xml")
    g.learn("/admin/api/users.xml")
    
    assert_equal ["/admin/api/#{Derivator::WILDCARD}.xml"].sort, g.paths().sort
    
    g.learn("/admin/xxx/features.xml")
    g.learn("/admin/xxx/applications.xml")
    g.learn("/admin/xxx/users.xml")

    assert_equal ["/admin/api/#{Derivator::WILDCARD}.xml", 
      "/admin/xxx/#{Derivator::WILDCARD}.xml"
      ].sort, g.paths().sort
            
  end

  def test_behaviour_order_matters

    g = Derivator.new()
    
    g.learn("/admin/api/features.xml")
    g.learn("/admin/api/applications.xml")
    g.learn("/admin/api/users.xml")
    
    assert_equal ["/admin/api/#{Derivator::WILDCARD}.xml"].sort, g.paths().sort
    
    g.learn("/admin/xxx/features.xml")
    g.learn("/admin/xxx/applications.xml")
    g.learn("/admin/xxx/users.xml")

    assert_equal ["/admin/api/#{Derivator::WILDCARD}.xml", 
      "/admin/xxx/#{Derivator::WILDCARD}.xml"].sort, g.paths().sort
    
    g = Derivator.new()
    
    g.learn("/admin/api/features.xml")
    g.learn("/admin/xxx/features.xml")

    assert_equal ["/admin/#{Derivator::WILDCARD}/features.xml"].sort, g.paths().sort

    g.learn("/admin/api/applications.xml")
    g.learn("/admin/xxx/applications.xml")
    
    g.learn("/admin/api/users.xml")
    g.learn("/admin/xxx/users.xml")
    
    assert_equal ["/admin/#{Derivator::WILDCARD}/features.xml",
      "/admin/#{Derivator::WILDCARD}/applications.xml",
      "/admin/#{Derivator::WILDCARD}/users.xml"].sort, g.paths().sort
            
  end
  
  def test_vectorize
    
    g = Derivator.new()
    
    assert_equal ["admin", "api", "applications", ".xml", Derivator::EOL], g.send(:vectorize,"/admin/api/applications.xml")
    assert_equal ["admin", "api", "applications", ".json", Derivator::EOL], g.send(:vectorize,"/admin/api/applications.json")
    assert_equal ["admin", "api", "applications", ".xxx", Derivator::EOL], g.send(:vectorize,"/admin/api/applications.xxx")
    assert_equal ["admin", "api", "applications", Derivator::EOL], g.send(:vectorize,"/admin/api/applications")
    assert_equal ["admin", "api", "applications.xml", ".json", Derivator::EOL], g.send(:vectorize,"/admin/api/applications.xml.json")
    assert_equal ["admin", "api.json", "applications", Derivator::EOL], g.send(:vectorize,"/admin/api.json/applications")
    
  end

end


