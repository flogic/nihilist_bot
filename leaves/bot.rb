$:.unshift(File.dirname(__FILE__) + '/../lib/')

require 'bot_parser'
require 'bot_sender'
require 'bot_helper'
require 'bot_filter'

class Bot < AutumnLeaf
  self.instance_methods.select {|meth| meth.to_s =~ /_command$/ }.each {|meth| undef_method(meth) }
  
  def did_receive_channel_message(sender, channel, mesg)
    bot_parser = BotParser.new
    bot_sender = BotSender.new(:destination => :tumblr, 
                               :post_url => 'http://www.tumblr.com/api/write', 
                               :site_url => 'http://ni.hili.st/', 
                               :email => 'ni@hili.st',
                               :password => 'password')
    bot_filter = BotFilter.new
    result = bot_parser.parse(sender, channel, mesg)
    result = bot_filter.process(result) if result
    respond(bot_sender.deliver(result), channel) if result
  end
  
  def respond(mesg, channel)
    message(mesg, channel) if mesg
  end
end
