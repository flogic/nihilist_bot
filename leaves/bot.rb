$:.unshift(File.dirname(__FILE__) + '/../lib/')

require 'bot_parser'
require 'bot_sender'
require 'bot_filter'

class Bot < AutumnLeaf
  attr_reader :options
  attr_reader :parser, :sender, :filter
  
  def did_start_up
    @parser = BotParser.new
    @sender = BotSender.new(sender_configuration)
    @filter = BotFilter.new(options)
  end
  
  instance_methods.select {|meth| meth.to_s =~ /_command$/ }.each {|meth| undef_method(meth) }
  
  def did_receive_channel_message(name, channel, mesg)
    result = nil
    if address_required_channels.include?(channel)
      return unless mesg.sub!(/^#{Regexp.escape(self.name)}\s*:\s*/, '')
    end
    result = parser.parse(name, channel, mesg)
    result = filter.process(result) if result
    respond(sender.deliver(result), channel) if result
  end
  
  def respond(mesg, channel)
    message(mesg, channel) if mesg
  end
  
  def help_command(sender, channel, text)
    formats = BotParser.formats
    if text and !text.empty?
      format = formats.detect { |f|  f.name == text.to_sym }
      if format
        respond("#{format.name}: #{format.description || 'no description available'}", channel)
      else
        respond("Format '#{text}' unknown", channel)
      end
    else
      respond("Known formats: #{formats.collect { |f|  f.name }.join(', ')}", channel)
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
  
  def address_required_channels
    options[:address_required_channels] || []
  end
end
