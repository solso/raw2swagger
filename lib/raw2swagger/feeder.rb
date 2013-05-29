module Raw2Swagger
  class Feeder
  
    class Spec
    
      def initialize(host, options = {})
        @options = options
        @derivator = Derivator.new(@options)
        @swagger = {"basePath" => host, "apiVersion" => "3.1416", "swaggerVersion" => "0.1", "apis" => {}, "models" => {}}
      end
    
      def options
        @options
      end
    
      def derivator
        @derivator
      end
      
      def clean_up
        current_valid_paths = derivator.paths
        @swagger["apis"].each do |k, endpoint|
          @swagger["apis"].delete(k) unless current_valid_paths.include?(endpoint["path"])
        end
      end
    
      def add_parameter(spec_path, swagger_method, format, swagger_type, name, value) 
      
        endpoint = @swagger["apis"][spec_path]
        if endpoint.nil?
          ## defaults
          endpoint = (@swagger["apis"][spec_path] = {})
          endpoint["path"] = spec_path
          endpoint["format"] = [format] if !format.nil?
          endpoint["description"] = "placeholder for the resource description"
          endpoint["errorResponses"] = {}
          endpoint["operations"] = {}
        else
          ## already exists
          endpoint["format"] << format unless format.nil? || endpoint["format"].include?(format)
        end
      
        operation = endpoint["operations"][swagger_method]
        if operation.nil?
          ## defaults
          operation = (@swagger["apis"][spec_path]["operations"][swagger_method] = {})
          operation["httpMethod"] = swagger_method
          operation["deprecated"] = false
          operation["summary"] = make_friendly_operation(swagger_method, spec_path)
          operation["parameters"] = {}
        else
          ## already exists
        end  
      
        parameter = operation["parameters"][name]
        if parameter.nil?
          #defaults
          parameter = (@swagger["apis"][spec_path]["operations"][swagger_method]["parameters"][name] = {})
          parameter["name"] = name
          parameter["seen_values"] = [value]
          parameter["description"] = "Possible values are: #{text_for_values(parameter["seen_values"])}"
          parameter["dataType"] = "string"
          parameter["paramType"] = swagger_type
          if swagger_type=="path"
            parameter["required"] = true
          end
        else
          parameter["seen_values"] = (parameter["seen_values"] << value).uniq
          size = parameter["seen_values"].size
          if size > 3
            ## trim if too long
            parameter["seen_values"] = parameter["seen_values"][size-3..size-1]
          end 
          parameter["description"] = "Possible values are: #{text_for_values(parameter["seen_values"])}"  
        end
      end
    
      def to_swagger()
      
        swg = deep_copy(@swagger)
      
        swg["models"] = swg["models"].values
        swg["apis"] = swg["apis"].values
    
      
        swg["apis"].each do |endpoint|
          endpoint["path"] = spec_path_to_swagger(endpoint["path"])
          endpoint["errorResponses"] = endpoint["errorResponses"].values
          endpoint["operations"] = endpoint["operations"].values    
      
          endpoint["operations"].each do |ops|
            ops["parameters"] = ops["parameters"].values
            ops["parameters"].each do |param|
              param.delete("seen_values")
            end
          
          end    
        end
        return swg
      end
    
      def spec_path_to_swagger(spec_path)
      
        v1 = derivator.vectorize(spec_path)
        res = []
      
        v1.each_with_index do |item, i|
          if item==Derivator::WILDCARD
            param_name = (i>0 ? make_friendly_id(v1[i-1]) : "param_name")
            res[i] = "{#{param_name}}"
          else  
            res[i] = item unless item==Derivator::EOL
          end
        end

        swagger_path = "/"
        res.each_with_index do |item, i|
          swagger_path << item 
          swagger_path << "/" if (i+1 < res.size) && res[i+1][0]!="." 
        end

        return swagger_path
      end
    
      def make_friendly_id(name)
         "#{name}_id"
      end
      
      def make_friendly_operation(method, spec_path)
        begin
          method = method.downcase
        
          verbs = {"get" => "List", 
            "post" => "Create", 
            "put"=> "Modify", 
            "delete" => "Delete", 
            "head" => "Head", 
            "patch" => "Patch"}
        
          v1 = derivator.vectorize(spec_path) || []
        
          ## remove EOL and formats
          v1 = v1.delete_if {|x| x==Derivator::EOL || x[0]=="."}
        
          wildcards = []
          v1.each_with_index do |lab, i|
            wildcards << i if lab==Derivator::WILDCARD
          end
        
          wildcards.reverse!
        
          str = ""
          if wildcards.size()==0
            str << verbs[method] << ' ' << (v1.last || "")
          elsif wildcards.size()==1
            verbs["get"] = "Get"
            if (method!="put" && method!="post") || v1.last==Derivator::WILDCARD
              str << verbs[method]
              if (wildcards.first-1 >= 0)
                str << ' ' << v1[wildcards.first-1] << ' by id' if (wildcards.first-1 >= 0)
              else
                str << ' by id'
              end  
            else
              if method=="put"
                str << v1[wildcards.first+1].capitalize << ' ' << v1[wildcards.first-1] << ' by id'
              elsif method=="post"
                str << verbs[method] << ' '<< v1[wildcards.first+1] 
                str << ' of ' << v1[wildcards.first-1] if (wildcards.first-1 >= 0)
              end  
            end  
          else
            verbs["get"] = "Get"
            str << verbs[method] << ' ' << v1[wildcards[0]-1] 
            if (wildcards[1]-1 >= 0)
              str << ' of ' << v1[wildcards[1]-1]
            end            
          end
          
          return str.strip
        rescue Exception => e
          raise e
          return "Could not guess name"
        end
      end
    
      protected 
    
      def text_for_values(values)
        return "" if values.size==0
        str = "'#{values[0]}'"
        if  values.size > 1
          (values.size())-1.times do |i|
            str << ", '" << values[i+1] << "'"
          end
        end  
        str
      end
    
      def deep_copy(obj)
        Marshal.load(Marshal.dump(obj))
      end
      
    end
  
    ## ***************************************
    ## ***************************************
  
    def initialize(options = {})
      @specs = {}
      @options = options
    end

    def options 
      @options
    end

    def spec(base_path)
      @specs[base_path]
    end
  
    def swagger_specs
      @specs.keys
    end
    
    def to_swagger(host)
      spec(host).to_swagger()
    end
  
    def create_spec(host)
      @specs[host] = Spec.new(host, options)
    end
  
    def extract_path_params(spec, path)
    
      spec_path = spec.derivator.find(path).first
    
      v1 = spec.derivator.vectorize(spec_path)
      v2 = spec.derivator.vectorize(path)
    
      res = []
      path_params = {}
    
      v1.each_with_index do |item, i|
        if item==Derivator::WILDCARD
          param_name = (i>0 ? spec.make_friendly_id(v1[i-1]) : "param_name")
          path_params[param_name] = v2[i]
          res[i] = "{#{param_name}}"
        else  
          res[i] = item unless item==Derivator::EOL
        end
      end
     
      swagger_path = "/"
      res.each_with_index do |item, i|
        swagger_path << item 
        swagger_path << "/" if (i+1 < res.size) && res[i+1][0]!="." 
      end
    
    
      return [path_params, swagger_path, spec_path]
    end
  
    def extract_params(data, content_type = nil)
      return {} if data.nil? || data.empty?    
      begin
        if content_type=="application/x-www-form-urlencoded"
          return data if data.class==Hash
          return Rack::Utils.parse_nested_query(data) 
        else
          ## this will be when the data is a request body and not urlencoded
          return {"__body"=>data}
        end 
      rescue Exception => e
        raise Exception.new("Input is not valid! Body could not be processed: #{data}")
      end
    end
  
    def add_parameters(spec, spec_path, swagger_method, format, params)
      params.each do |type, parameters|
        parameters.each do |name, value|

          swagger_type = type.to_s
          if swagger_type=="header" || swagger_type=="path"
            ## do nothing, already ok
          else
            swagger_type = "query" if swagger_type=="query_string"
            if swagger_type=="body" && parameters.size==1 && name=="__body"
              swagger_type="body"
            else
              swagger_type= "query"
              ## most likely, should be the recently added "form"
            end  
          end
                
          spec.add_parameter(spec_path, swagger_method, format, swagger_type, name, value)
        end  
      end
    end
  
    def process(obj)
    
      validate(obj)
    
      sp = spec(obj["host"])
      sp = create_spec(obj["host"]) if sp.nil?
    
      modified = sp.derivator.learn(obj["path"])
      sp.clean_up() if modified
      
      swagger_method = obj["method"]
    
      ## FIXME: this will cause problems
      format = "not_done_yet"
    
      ## extract params
      params = {}
    
      ## for path
      tmp = extract_path_params(sp, obj["path"])
      params[:path] = tmp[0]
      swagger_path = tmp[1]
      spec_path = tmp[2]

      ## for query string
      params[:query_string] = extract_params(obj["query_string"],"application/x-www-form-urlencoded")
    
      ## for request body, only for methods other than GET and HEAD
      body_params = {}
      if obj["method"]!="GET" || obj["method"]!="HEAD"
        params[:body] = extract_params(obj["body"],obj["headers"]["Content-Type"]) 
      end
    
      ## for headers
      params[:header] = obj["headers"]
        
      add_parameters(sp, spec_path, swagger_method, format, params)
    
      ## other types are headers, form     
    end
  
    def validate(obj)
      raise Exception.new("Input is not valid! Must contain host: #{obj}") if obj["host"].nil? || obj["host"]==""
      raise Exception.new("Input is not valid! Must contain path: #{obj}") if obj["path"].nil? || obj["path"]==""
      raise Exception.new("Headers must be a hash! #{}") if obj["headers"].class!=Hash
    end
  
  end
end  