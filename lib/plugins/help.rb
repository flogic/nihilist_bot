class BotPlugin::Help < BotPlugin
  match /^!help(?:\s+(\S+))?/, :use_prefix => false
  
  def execute(m, fmt)
    formats = BotParser.formats
    
    if fmt
      format = formats.detect { |f|  f.name == fmt.to_sym }
      if format
        description = format.description || 'no description available'
        description.split("\n").each { |line|  m.reply "#{format.name}: #{line}" }
      else
        m.reply "Format '#{fmt}' unknown"
      end
    else
      m.reply "Known formats: #{formats.collect { |f|  f.name }.join(', ')}"
    end
  end
end
