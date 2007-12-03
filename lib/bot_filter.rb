class BotFilter
  attr_reader :options
  
  def initialize(options = {})
    @options = options
  end
  
  @@kinds = []
  
  class << self
    def kinds
      @@kinds
    end
    
    def register(name)
      @@kinds << name
    end
    
    def clear_kinds
      @@kinds = []
    end
    
    def get(ident)
      name = ident.to_s.gsub(/(?:^|_)([a-z])/) { $1.upcase }.to_sym
      const_get(name)
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

require 'filters/link_name_cleanup'
BotFilter.register(:link_name_cleanup)

require 'filters/link_title'
BotFilter.register(:link_title)

require 'filters/poster_info'
BotFilter.register(:poster_info)

require 'filters/ignore_nicks'
BotFilter.register(:ignore_nicks)

require 'filters/ignore_patterns'
BotFilter.register(:ignore_patterns)
