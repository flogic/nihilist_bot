class BotPlugin::Help
  include Cinch::Plugin
  
  listen_to :message
  
  def listen(m)
    formats = BotParser.formats
    m.reply "Known formats: #{formats.collect { |f|  f.name }.join(', ')}"
  end
end
