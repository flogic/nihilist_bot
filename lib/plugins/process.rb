class BotPlugin::Process < BotPlugin
  listen_to :channel
  
  def listen(m)
    if main_bot.config['address_required_channels'].include?(m.channel)
      return unless m.text.sub!(/^#{Regexp.escape(bot.nick)}\s*:\s*/, '')
    end
    
    result = main_bot.parser.parse(m.nick, m.channel, m.text)
    result = main_bot.filter.process(result) if result
    m.reply  main_bot.sender.deliver(result) if result
  end
end
