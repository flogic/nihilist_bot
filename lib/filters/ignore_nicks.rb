require File.join(File.dirname(__FILE__), 'template')

class BotFilter::IgnoreNicks < BotFilter::Template
  def process(data)
    raise TypeError unless data.is_a?(Hash)
    
    result = self.class.nick_list.include?(data[:poster]) ? nil : data
    
    result
  end
  
  class << self
    @@nick_list = nil
    def nick_list=(val)  @@nick_list = val  end
    def nick_list()      @@nick_list || []  end
  end
end
