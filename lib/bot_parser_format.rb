class BotParserFormat
  attr_reader :name, :format, :block
  
  def initialize(name, format, &block)
    raise ArgumentError, 'Block needed' if block.nil?
    
    @name   = name
    @format = format
    @block  = block
  end
  
  def process(text)
    md = format.match(text)
    return nil unless md
    
    block.call(text, md).merge(:type => name)
  end
end
