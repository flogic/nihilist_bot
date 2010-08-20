class BotPlugin::Help
  include Cinch::Plugin
  
  listen_to :message
  def listen(m)
    formats = BotParser.formats
    m.reply "Known formats: #{formats.collect { |f|  f.name }.join(', ')}"
  end
  
  match /^!help\s+(\S+)/, :use_prefix => false
  def execute(m, fmt)
    formats = BotParser.formats
    format  = formats.detect { |f|  f.name == fmt.to_sym }
    if format
      description = format.description || 'no description available'
      description.split("\n").each { |line|  m.reply "#{format.name}: #{line}" }
    else
      m.reply "Format '#{fmt}' unknown"
    end
  end
end
