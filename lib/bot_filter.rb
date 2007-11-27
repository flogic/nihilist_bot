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
