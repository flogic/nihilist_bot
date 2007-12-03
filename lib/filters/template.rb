class BotFilter::Template
  attr_reader :options
  
  def initialize(options = {})
    @options = (options[:filters] and options[:filters][kind.to_s]) ? options[:filters][kind.to_s] : {}
  end
  
  def process(data)
    raise TypeError unless data.is_a?(Hash)
    result = data
    result
  end
  
  def kind
    self.class.name.split('::').last.gsub(/([a-z])([A-Z])/, '\1_\2').downcase.to_sym
  end
end
