require 'bot_parser_format'

class BotParser
  @formats = []
  
  class << self
    attr_reader :formats
    
    def register_format(*args, &block)
      formats << BotParserFormat.new(*args, &block)
    end
    
    def clear_formats
      @formats = []
    end
  end
  
  def formats()  self.class.formats;  end
  
  register_format :image, /^\s*(?:(.*?)\s+)?(http:\S+\.(?:jpe?g|png|gif))(?:\s+(\S.*))?$/i do |md, _|
    { :title => md[1], :source => md[2], :caption => md[3] }
  end
  
  register_format :video, %r{^\s*(?:(.*?)\s+)?(http://(?:www\.)?youtube\.com/\S+\?\S+)(?:\s+(.*))?$}i do |md, _|
    { :title => md[1], :embed => md[2], :caption => md[3] }
  end
  
  register_format :quote, /^\s*"([^"]+)"\s+--\s*(.*?)(?:\s+\((https?:.*)\))?$/i do |md, _|
    { :quote => md[1], :source => md[2], :url => md[3] }
  end
  
  register_format :link, %r{^\s*(?:(.*?)\s+)?(https?://\S+)\s*(?:\s+(\S.*))?$}i do |md, _|
      { :name => md[1], :url => md[2], :description => md[3] }
  end
  
  register_format :fact, %r{^\s*fact:\s+(.*)}i,
  %Q['fact: Zed Shaw doesn't do pushups, he pushes the earth down'] do |md, _|
    { :title => "FACT: #{md[1]}" }
  end
  
  register_format :true_or_false, %r{^\s*(?:(?:true\s+or\s+false)|(?:t\s+or\s+f))\s*[:\?]\s+(.*)}i,
  %Q['T or F: the human body has more than one sphincter'] do |md, _|
    { :title => "True or False?  #{md[1]}" }
  end
  
  def parse(sender, channel, mesg)
    return nil if mesg.empty?
    
    common = { :poster => sender, :channel => channel }
    
    result = nil
    formats.detect { |f|  result = f.process(mesg) }
        
    return nil unless result
    
    result = common.merge(result)
    result
  end
end
