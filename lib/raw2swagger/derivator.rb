module Raw2Swagger
  class Derivator

    WILDCARD = "*"
    EOL = "__EOL"

    def initialize(options = {})
      defaults = {:occurrences_threshold => 1.0,
                  :unmergeable_words => []}
    
      @options = defaults.merge(options)
      @spec = {"root" => {}} 
      @hist = {}
      @count_learn = 0
    end
  
    def options
      @options
    end
  
    def spec
      @spec
    end
  
    def spec=(val)
      @spec = val
    end
  
    def hist
      @hist
    end
  
    def hist=(val)
      @hist = val
    end
   
    ## returns true if both words (segments of the path) can be merged
    ## any of the words are not in the unmergeable_words and their relative frequency 
    ## to the most common word is lower than occurrences_threshold
    def mergeable?(word_1, word_2)
  
      ## do not merge if workds are in unmergeabled_words
      return false if options[:unmergeable_words].include?(word_1) || options[:unmergeable_words].include?(word_2)
  
      ## do not merge if words are formats (words that start with .)
      return false if word_1[0]=="." || word_2[0]=="."
    
      score_1 = hist[word_1] || 0
      score_2 = hist[word_2] || 0
    
      max = 0
      hist.each {|k,v| max = v if (v > max) }
    
      if max > 0
        score_1 = score_1 / max.to_f
        score_2 = score_2 / max.to_f
      else
        score_1 = score_2 = 0
      end 
    
      if score_1 <= options[:occurrences_threshold] && score_2 <= options[:occurrences_threshold]
        return true
      else
        return false
      end
    end  
 
    ## returns the a list of all paths from the tree
    def paths()
      paths_recur(@spec["root"],"")
    end
  

    def clashes()
      results = {}
      all_paths = paths()
    
      all_paths.each do |path1|
        results[path1] = []
        all_paths.each do |path2|
          if path1!=path2
            results[path1] << path2 if equal?(path1,path2)
          end
        end
      end
    
      return results
    end
  
    def equal?(path1, path2)
      v1 = vectorize(path1)
      v2 = vectorize(path2)
      return false if v1.nil? or v2.nil?
    
      if v1.size()==v2.size
        eq = true
        v1.size().times do |z|
          eq = eq && ((v1[z]==v2[z]) || v1[z]==WILDCARD || v2[z]==WILDCARD)
        end
        return eq
      else
        return false
      end 
    end
  
    def find(path)
      matches = []
      paths.each do |item|
        matches << item if equal?(path,item)
      end
      return matches
    end
    
    def remove(path)
  
      return false unless paths.include?(path)
  
      v = vectorize(path)
    
      tree = @spec["root"]
      res = []
  
      v.each_with_index do |item, i|
        res << tree
        tree = tree[item] || tree[WILDCARD]
      end
    
      res.each do |item|
        return false if item.nil?
      end
    
      n = res.size
      n.times do |i|
        res[n-i-1].each do |k,v|
          if v.size==0 
            res[n-i-1].delete(k)
          end
        end      
      end
    
      return true
    end

    def add(path)

      v = vectorize(path)
      r = @spec["root"]
  
      v.each_with_index do |item, i|
      
        if i<(v.size-1)
          @hist[item]||=0
          @hist[item]+=1
        end
      
        if r[item].nil?
          if r.size() == 0
            ## totally unseen
            r[item] = {}
          else
            ## there are others, let's compare siblings
            found = nil
        
            r.each do |sibling, children_sibling|
              children_sibling.keys.each do |n|
                ## found if the next word of both are the same and it
                ## meets the mergeable condition
                if n==v[i+1]
                  found ||= sibling if mergeable?(sibling, item)
                end
              end
            end
        
            if found.nil?
              r[item] = {}
            else
              if found==WILDCARD
                ## not needed but keep it for clarity
                ##r[WILDCARD].merge!({})
              else
                r[WILDCARD]||={}
                r[WILDCARD].merge!(r[found])            
                r.delete(found)
              end
              item = WILDCARD  
            end
          end
        end  
        r = r[item]
      end
    end

    def learn(path)
      @count_learn += 1
    
      matches = find(path)
    
      if matches.size==0
        add(path)
        return true
      elsif matches.size==1
        return false
      else
        ## there is conflict      
        clash = clashes()
        min = Float::INFINITY
        m_path = nil
      
        matches.each do |rep|
          sc = score(rep)
          if sc < min
            min = sc
            m_path = rep
          end
        end
      
        if !m_path.nil?        
          remove(m_path)
          return true
        else
          return false
        end  
      end
    end
  
    def vectorize(path)
      v = path.split("/")
      return nil if v.size<1
    
      ## tries to find the format out of the path, format can only
      ## be in the last word, /foo/bar.kkk.json, format is .json
      ## /foo/bar.xxx/hello
      lw = v.last.split(".")  
      lw = [lw[0..lw.size-2].join("."), ".#{lw.last}"] if lw.size>1
      
      if v.size==1
        lw << EOL
        return lw
      else
        v = [v[1..(v.size()-2)], lw, EOL].flatten
        return v
      end
        
    end

    protected 

    def score(path)
      v = vectorize(path)
      v = v[0..v.size-1]
    
      score = 0
      v.each do |word|
        score += @hist[word] unless @hist[word].nil?
      end
      return score
    end
  
  
    def paths_recur(tree, str)
      v = []
      tree.each do |node, children|
        if node==EOL
          v << [str]
        elsif node[0]=="."
          v << paths_recur(children, "#{str}#{node}")        
        else  
          v << paths_recur(children, "#{str}/#{node}")
        end
      end
      return v.flatten! || []
    end

    ## returns true is the path exists on the spec, false otherwise
    def match?(path)
      v = vectorize(path)  
      return false if v.nil?
      tree = @spec["root"]
    
      return match_recur(tree, v)
    end
    
    def match_recur(tree, path_as_vector)
      path_as_vector.each_with_index do |item, i|
        if item==WILDCARD 
          equal = true
          tree.each do |tmp, child|
            equal = equal && match_recur(child, path_as_vector[i+1..path_as_vector.size-1])
          end  
          return equal
        else
          tree  = tree[item] || tree[WILDCARD]
          return false if tree.nil?
        end  
      end
      return true  
    end
  end
end