require 'yaml'

class NewBot
  attr_reader :config
  
  def load_config
    @config = YAML.load(File.read('./config/config.yml'))
    normalize_config
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
