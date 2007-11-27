class BotFilter::Template
  attr_reader :options
  
  def initialize(options = {})
    @options = options
  end
  
  def process(data)
    raise TypeError unless data.is_a?(Hash)
    
    result = data
    
    result
  end
end
