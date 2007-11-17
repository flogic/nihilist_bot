class BotParserFormat
  attr_reader :name, :format, :block
  
  def initialize(name, format, &block)
    raise ArgumentError, 'Block needed' if block.nil?
    
    @name   = name
    @format = format
    @block  = block
  end
  
  def process(text)
  end
end