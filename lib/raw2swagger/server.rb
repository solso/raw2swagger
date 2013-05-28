module Raw2Swagger
  class Server
    
    def initialize()
      @obj = Feeder.new()
    end
    
    def call(env)
      req = Rack::Request.new(env)      
      method = req.path      
      
      clean_methods = method.gsub("/","").split(".")
      clean_methods.map!(&:to_sym)

      args = req.params["args"]
      
      if env["REQUEST_METHOD"]=="HEAD" || env["REQUEST_METHOD"]=="GET"
        args = req.params["args"]
      else
        args = req.body.read
      end  
      
      clean_args = []
      if !args.nil?
        args = [args] if args.class!=Array
          
        args.each do |item|
          begin
            clean_args << JSON::parse(item)
          rescue Exception => e
            if item.to_i.to_s == item
              clean_args << item.to_i
            else
              clean_args << item
            end  
          end
        end
      end  
      
      begin     
        o = @obj
        res = nil
        clean_methods.each_with_index do |meth, i|
          if i==clean_methods.size()-1
            res = o.public_send(meth,*clean_args)
          else
            obj = o.public_send(meth)
          end
        end  
          
        if res.class==Hash || res.class==Array
          return [200, {"Content-Type" => "application/json"}, [res.to_json]]
        else
          return [200, {"Content-Type" => "application/json"}, [{"value" => res}.to_json]]
        end      
      rescue Exception => e
        return [422, {"Content-Type" => "application/json"}, [{"error" => e.message}.to_json]]
      end
    end
  end
end



