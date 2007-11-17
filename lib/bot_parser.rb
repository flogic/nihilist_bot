require 'bot_parser_format'

class BotParser
  @formats = []
  
  class << self
    attr_reader :formats
    
    def register_format(format_name, &block)
      raise ArgumentError, 'Block needed' if block.nil?
      formats << BotParserFormat.new(format_name, &block)
    end
  end
  
  def parse(sender, channel, mesg)
    return nil if mesg.empty?
    
    common = { :poster => sender, :channel => channel }
    
    result = case mesg 
      when /^\s*(http:\S+\.(?:jpe?g|png|gif))(?:\s+(\S.*))?$/i
        { :type => 'image', :source => $1, :caption => ($2 || '') + " (posted by #{sender})" }
      when %r{^\s*(http://(?:www\.)?youtube\.com/\S+\?\S+)(?:\s+(.*))?$}i
        { :type => 'video', :embed => $1, :caption => ($2 || '') + " (posted by #{sender})" }
      when /^\s*"([^"]+)"\s+--\s*(.*)\s+\((https?:.*)\)$/i
        { :type => 'quote', :quote => $1, :source => $2 + " (posted by #{sender})", :url => $3 }
      when /^\s*"([^"]+)"\s+--\s*(.*)$/i
        { :type => 'quote', :quote => $1, :source => $2 + " (posted by #{sender})" }
      when %r{^\s*(?:(.*?)\s+)?(https?://\S+)\s*(?:\s+(\S.*))?$}i
        title = $1 || Kernel::BotHelper.get_link_title($2)
        { :type => 'link', :url => $2, :name => title, :description => ($3 || '') + " (posted by #{sender})" }
      when %r{^\s*fact:\s+(.*)}i
        { :type => 'fact', :title => "FACT: #{$1}", :body => "(posted by #{sender})" }
      when %r{^\s*(?:(?:true\s+or\s+false)|(?:t\s+or\s+f))\s*[:\?]\s+(.*)}i
        { :type => 'true_or_false', :title => "True or False?  #{$1}", :body => "(posted by #{sender})" }
      else
        nil
    end
    
    return nil unless result
    
    common.merge(result)
  end
end
