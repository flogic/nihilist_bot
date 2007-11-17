class BotParserFormat
  attr_reader :name, :block
  
  def initialize(name, &block)
    raise ArgumentError, 'Block needed' if block.nil?
    
    @name  = name
    @block = block
  end
end