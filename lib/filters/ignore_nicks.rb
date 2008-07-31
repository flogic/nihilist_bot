require File.join(File.dirname(__FILE__), 'template')

class BotFilter::IgnoreNicks < BotFilter::Template
  def initialize(*args)
    super
    self.class.nick_list = options['nicks'] rescue nil
  end
  
  def process(data)
    raise TypeError unless data.is_a?(Hash)
    
    result = data
    if self.class.nick_list.any? { |nick|  nick === data[:poster] }
      result = nil
    end
    
    result
  end
  
  class << self
    @@nick_list = nil
    def nick_list=(val)  @@nick_list = val  end
    def nick_list()      @@nick_list || []  end
  end
end
