class BotParser
  def parse(sender, channel, mesg)
    return nil if mesg.empty?
    
    result = { :poster => sender, :channel => channel }
    case mesg 
      when /^\s*(http:\S+\.(?:jpe?g|png|gif))(?:\s+(\S.*))?$/i
        return result.merge(:type => 'image', :source => $1, :caption => ($2 || '') + " (posted by #{sender})")
      when %r{^\s*(http://(?:www\.)?youtube\.com/\S+\?\S+)(?:\s+(.*))?$}i
        return result.merge(:type => 'video', :embed => $1, :caption => ($2 || '') + " (posted by #{sender})")
      when /^\s*"([^"]+)"\s+--\s*(.*)\s+\((https?:.*)\)$/i
        return result.merge(:type => 'quote', :quote => $1, :source => $2 + " (posted by #{sender})", :url => $3)
      when /^\s*"([^"]+)"\s+--\s*(.*)$/i
        return result.merge(:type => 'quote', :quote => $1, :source => $2 + " (posted by #{sender})")
      when %r{^\s*(?:(.*?)\s+)?(https?://\S+)\s*(?:\s+(\S.*))?$}i
        return result.merge(:type => 'link', :url => $2, :name => ($1 || ''), :description => ($3 || '') + " (posted by #{sender})")
      when %r{^\s*fact:\s+(.*)}i
        return result.merge(:type => 'fact', :title => "FACT: #{$1}", :body => "(posted by #{sender})")
      else 
        return nil
    end
  end
end