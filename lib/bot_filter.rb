class BotFilter
  @@kinds = {}
  
  class << self
    def kinds
      @@kinds.keys.sort_by { |k|  k.to_s }
    end
    
    def register(args = {})
      args.each_pair { |k, v|  @@kinds[k] = v }
    end
    
    def clear_kinds
      @@kinds = {}
    end
  end
  
  def process(data)
    result = data
    self.class.kinds.each do |k|
      if result
        result = @@kinds[k].new.process(result)
      else
        result = nil
        break
      end
    end
    result
  end
end
