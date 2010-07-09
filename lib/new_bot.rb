require 'rubygems'
require 'cinch'

require 'yaml'

require 'bot_parser'
require 'bot_filter'

class NewBot
  attr_reader :config
  attr_reader :bot
  attr_reader :parser, :filter
  
  def setup
    @parser = BotParser.new
    @filter = BotFilter.new(config)
  end
  
  def load_config
    @config = YAML.load(File.read('./config/config.yml'))
    normalize_config
  end
  
  def init_bot
    options = {
      :server => config['server'],
      :nick => config['nick'],
      :realname => config['realname'],
      :channels => config['channels'],
    }
    @bot = Cinch.setup(options)
    
    bot.on :privmsg do |m|
      result = parser.parse(m.nick, m.channel, m.text)
      filter.process(result) if result
    end
  end
  
  
  private
  
  def normalize_config
    config['realname'] ||= config['nick']
    %w[channels address_required_channels].each do |channels|
      config[channels] = (config[channels] || []).collect { |c| normalized_channel_name(c) }
    end
  end
  
  def normalized_channel_name(name)
    name.sub(/^#?/, '#')
  end
end
