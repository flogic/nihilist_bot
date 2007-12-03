class BotFilter
  attr_reader :options
  
  def initialize(options = {})
    @options = options
  end
  
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
    
    def get(ident)
      name = ident.to_s.gsub(/(?:^|_)([a-z])/) { $1.upcase }.to_sym
      const_get(name)
    end
  end
  
  def process(data)
    result = data
    self.class.kinds.each do |k|
      if result
        result = @@kinds[k].new(options).process(result)
      else
        result = nil
        break
      end
    end
    result
  end
end

require 'filters/link_name_cleanup'
BotFilter.register(:link_name_cleanup => BotFilter::LinkNameCleanup)

require 'filters/link_title'
BotFilter.register(:link_title => BotFilter::LinkTitle)

require 'filters/poster_info'
BotFilter.register(:poster_info => BotFilter::PosterInfo)

require 'filters/ignore_nicks'
BotFilter.register(:ignore_nicks => BotFilter::IgnoreNicks)

require 'filters/ignore_patterns'
BotFilter.register(:ignore_patterns => BotFilter::IgnorePatterns)
