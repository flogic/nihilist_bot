class BotPlugin::Process < BotPlugin
  listen_to :channel
  
  def listen(m)
    if main_bot.config['address_required_channels'].include?(m.channel.name)
      return unless m.message.sub!(/^#{Regexp.escape(bot.nick)}\s*:\s*/, '')
    end
    
    result = main_bot.parser.parse(m.user.nick, m.channel.name, m.message)
    result = main_bot.filter.process(result) if result
    m.reply  main_bot.sender.deliver(result) if result
  end
end
