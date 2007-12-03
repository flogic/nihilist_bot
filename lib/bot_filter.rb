class BotFilter
  attr_reader :options
  
  def initialize(options = {})
    @options = options
  end
  
  @@kinds = []
  @@filters_registered = false
  
  class << self
    def new(options = {})
      locate_filters unless @@filters_registered
      obj = allocate
      obj.send :initialize, options
      obj
    end
    
    def kinds
      @@kinds
    end
    
    def register(name)
      @@kinds << name
    end
    
    def clear_kinds
      @@kinds = []
      @@filters_registered = false
    end
    
    def get(ident)
      name = ident.to_s.gsub(/(?:^|_)([a-z])/) { $1.upcase }.to_sym
      const_get(name)
    end
    
    def locate_filters
      @@filters_registered = true
    end
  end
  
  def process(data)
    result = data
    self.class.kinds.each do |k|
      if result
        result = BotFilter.get(k).new(options).process(result)
      else
        result = nil
        break
      end
    end
    result
  end
end

[:link_name_cleanup, :link_title, :poster_info, :ignore_nicks, :ignore_patterns].each do |filter|
  require "filters/#{filter}"
  BotFilter.register(filter)
end
