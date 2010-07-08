require File.join(File.dirname(__FILE__), 'template')
$:.unshift File.join(File.dirname(__FILE__), %w[.. htmlentities lib])
require 'htmlentities'

class BotFilter::LinkEntityCleanup < BotFilter::Template
  def process(data)
    raise TypeError unless data.is_a?(Hash)
    
    return data unless data[:type] == :link
    
    result = data
    if result[:name]
      result[:name] = HTMLEntities.new.decode(result[:name])
    end
    result
  end
end
