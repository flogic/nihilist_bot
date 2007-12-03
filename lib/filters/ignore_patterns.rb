require File.join(File.dirname(__FILE__), 'template')

class BotFilter::IgnorePatterns < BotFilter::Template
  def initialize(*args)
    super
    self.class.pattern_list = options['patterns'] rescue nil
  end
  
  def process(data)
    raise TypeError unless data.is_a?(Hash)
    
    return data unless data[:type] == :link
    
    result = self.class.pattern_list.any? { |pat|  pat.match(data[:url]) } ? nil : data
    
    result
  end
  
  class << self
    @@pattern_list = nil
    def pattern_list=(val)  @@pattern_list = val  end
    def pattern_list()      @@pattern_list || []  end
  end
end
