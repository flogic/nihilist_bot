$:.unshift(File.dirname(__FILE__) + '/../lib/')

require 'bot_parser'
require 'bot_sender'
require 'bot_filter'

class Bot < AutumnLeaf
  attr_reader :options
  
  self.instance_methods.select {|meth| meth.to_s =~ /_command$/ }.each {|meth| undef_method(meth) }
  
  def did_receive_channel_message(sender, channel, mesg)
    bot_parser = BotParser.new
    bot_sender = BotSender.new(sender_configuration)
    bot_filter = BotFilter.new(options)
    result = bot_parser.parse(sender, channel, mesg)
    result = bot_filter.process(result) if result
    respond(bot_sender.deliver(result), channel) if result
  end
  
  def respond(mesg, channel)
    message(mesg, channel) if mesg
  end
  
  def help_command(sender, channel, text)
    BotParser.formats.each do |f|
      respond("#{f.name}: #{f.description || 'no description available'}", channel)
    end
  end
  
  def sender_configuration
    raise "leaf bot configuration should include an :active_sender option" unless options[:active_sender] 
    raise "leaf bot configuration should include a list of :senders" unless options[:senders] 
    raise "leaf bot configuration doesn't have a :senders entry for :active_sender [#{options[:active_sender]}]" unless options[:senders][options[:active_sender]]
    raise "leaf bot configuration doesn't have a :destination type for :active_sender [#{options[:active_sender]}]" unless options[:senders][options[:active_sender]]['destination']
    
    result = {}
    options[:senders][options[:active_sender]].each_pair do |k, v|
      new_key = k.to_sym
      new_val = new_key == :destination ? v.to_sym : v
      result[new_key] = new_val
    end
    result
  end
end
