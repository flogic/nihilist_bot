class BotPlugin::Process
  include Cinch::Plugin
  
  listen_to :channel
  
  def listen(m)
    if bot.container.config['address_required_channels'].include?(m.channel)
      return unless m.text.sub!(/^#{Regexp.escape(bot.nick)}\s*:\s*/, '')
    end
    
    result = bot.container.parser.parse(m.nick, m.channel, m.text)
    result = bot.container.filter.process(result) if result
    m.reply  bot.container.sender.deliver(result) if result
  end
end
