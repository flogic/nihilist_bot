#
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# < _ [ at ] dominiek.com > wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return (http://people.freebsd.org/~phk/)
# ----------------------------------------------------------------------------
#
# = EyeAreSee - IRC API with SSL support
#
# Homepage::  http://blog.dominiek.com
# Author::    Dominiek ter Heide
# License::   Beer-Ware License 
#
#    == Example IRC Client
#
#    require 'EyeAreSee'
#
#    irc = EyeAreSee.new("EyeAreSee", "irc.darkwired.org", :ssl => true, :channel => "#test")
#
#    # catch all lines for debugging
#    irc.on_message { |line|
#      puts "debug: "+line if $DEBUG
#    }
#
#    # catch all server messages, eg nickname already in use
#    irc.on_server_message { |event|
#      next if event[:code] == 372
#      puts event[:code].to_s+": "+event[:message]
#    }
#
#    # handle 372 messages (Message of the Day)
#    irc.on_server_message(372) { |event|
#      puts "motd: "+event[:message]
#    }
#
#    # display all messages directed to the #test channel
#    irc.on_message("privmsg", :to => "#test") { |event|
#      puts event[:from_nickname].to_s+" says: "+event[:message].to_s
#    }
#
#    # auto-response to private message from specific user
#    irc.on_message("privmsg", :to => "EyeAreSee", :from_nickname => "Drakonen") { |event|
#      sleep(rand*10)
#      responses = ["hmmmz", "boeiend", "interessant"]
#      irc.message event[:from_nickname], responses[(rand*3).to_i]
#    }
# 
#    # display all messages directed to the #test channel
#    irc.on_message("privmsg", :to => "#test", :message => "please go away EyeAreSee") { |event|
#      irc.message("#test", "OK "+event[:from_nickname]+", bye everyone!") 
#      irc.quit
#    }
#
#    irc.start
#    irc.start #reconnect once after a quit
# 
# see EyeAreSee for more
#
# == Event Handlers
# Event handlers can be added in several ways, using the methods:
#  * on_message (for any kind of message)
#  * on_server_message (for codes/notices/errors send by the server)
# These methods need a block of code supplied (the event handler) and when the event is generated, the following hash will be send:
#  * event[:expression], string containing regular expression
#  * event[:matchdata], MatchData object
#  * event[:line], raw line
#  * event[:from], originating hostmask / server
#  * event[:from_nickname], parsed nickname from hostmask (if available)
#  * event[:code], server code (if available)
#  * event[:command], command (if available)
#  * event[:to], recipient (can be a channel or yourself)
#  * event[:message], the message / contents
#
# see EyeAreSee for more
#


require 'socket'
require 'openssl'

class EyeAreSee # :nodoc:
  attr :nickname
  attr :logger, true

  #
  # Initialize IRC session. Will try to determine port on its own.
  # Required parameters:
  #  * nickname 
  #  * server
  # Options: (hash)
  #  * :port 
  #  * :channel (optional channel)
  #  * :channels (array of channels)
  #  * :ssl (will use SSL if not nil)
  #  * :ssl_context (OpenSSL context instance for certificate stuff)
  #
  def initialize(nickname, server, options={})
    @server = server
    @nickname = nickname
    @options = options
    @port = options[:port]
    @port = 9999 if @port == nil and options[:ssl] != nil
    @port = 6667 if @port == nil
    @handlers = {}
    @raw_handler = nil
    @quit = nil
    @channels = @options[:channels]
    @channels = [] if @channels == nil
    @channels.push(@options[:channel]) unless @options[:channel] == nil
    @password = options[:password]
  end


  #
  # Add event handler (code block) for any IRC message
  # When omitted, every line will be send.
  # Expression as a String:
  #    irc.on_message("PRIVMSG") { |event| ... }
  #    irc.on_message("JOIN") { |event| ... }
  #    irc.on_message("KICK") { |event| ... }
  # Expression as a Regexp (advanced):
  #    irc.on_message(/^:([^\s]+)\s(PRIVMSG|JOIN)\s([^\s]+)\s:(.+)/) { |event| ... }
  # Use of the optional after_filter:
  #    irc.on_message("PRIVMSG", :to => "#channel", :from_nickname => "Drakonen") { |event| ... }
  # The after_filter Hash can contain all possible Event fields.
  #
  def on_message(expression=nil, after_filter=nil, &block)
    @raw_handler = block if expression.nil?
    @handlers[block] = [ expression, after_filter ] if expression.kind_of? Regexp
    if expression.kind_of? String then
      expression = Regexp.new("^:([^\s]+)\s("+expression.upcase+")\s([^\s]+)\s:(.+)")
      @handlers[block] = [ expression, after_filter ]
    end
  end

  #
  # Add event handler (code block) for server messages
  #    irc.on_server_message("372") { |event| ... }
  #    irc.on_message(372) { |event| ... }
  #    irc.on_message(/([0-9]+)/) { |event| ... }
  #    irc.on_message { |event| ... } # catches all server messages
  # 
  def on_server_message(code=nil, &block)
    code = /([0-9]+)/ if code.nil?
    code = Regexp.new("("+code.to_s+")") if code.kind_of? Fixnum
    expression = Regexp.new("^:([^\s]+)\s"+code.source+"\s([^\s]+)\s:(.+)$")
    @handlers[block] = [ expression, nil ]
  end

  #
  # Send IRC message to channel or nickname
  #
  def message(to, message)
    send_raw_line("PRIVMSG "+to.to_s+" :"+message.chomp)
  end
 
  #
  # Connect to server and start generating events (blocking!).
  # On timeout, disconnect or errors, this method will raise the exceptions.
  # On quit, this method will simply return.
  #
  def start
    @quit = nil
    @socket = self.connect()
    self.on_message(/^PING/) { |event|
      self.send_raw_line("PING "+event[:matchdata].post_match)
    }
    self.on_server_message(353) { |event|
    }
    self.on_server_message(376) do |event|
      if @password and !@authenticated then
        self.message 'NickServ', "IDENTIFY #{@password}"
        @authenticated = true
      end
      # Commented out to ensure that these actions occur in the correct order; see AutumnLeaf
      #@channels.each { |channel|
      #  if channel.kind_of? Hash then
      #    self.send_raw_line("JOIN "+channel.keys.first+" "+channel.values.first)
      #  else
      #    self.send_raw_line("JOIN "+channel)
      #  end
      #}
    end
 
    self.send_raw_line("USER "+@nickname+" "+@nickname+" "+@nickname+" "+@nickname)
    self.send_raw_line("NICK "+@nickname)
    begin
      while line = @socket.gets
        handle_raw_line(line) 
      end
    rescue IOError => ioe
      raise ioe unless @quit
    end
  end

  #
  # disconnect from server with optional message
  #
  def quit(message="ByeAreSee")
    @quit = true
    self.send_raw_line("QUIT :"+message.to_s)
    @socket.close
  end

  #
  # send raw data+"\n" to the IRC server
  #
  def send_raw_line(line)
    @logger.debug "<< #{line}" if @logger
    @socket.puts(line)
  end

protected 

  def handle_raw_line(line)
    @raw_handler.call(line) unless @raw_handler == nil
    @handlers.each { |action,expression|
      after_filter = expression[1]
      expression = expression[0]
      md = expression.match(line)
      next if md == nil
      event = Hash.new
      event[:expression] = expression
      event[:matchdata] = md
      event[:line] = line
      event[:from] = md[1] unless md[1] == nil
      event[:from_nickname] = md[1].slice(0, md[1].index('!').to_i) unless md[1] == nil
      event[:code] = md[2].to_i unless md[2] == nil or md[2].to_i == 0
      event[:command] = md[2] unless md[2] == nil or md[2].to_i != 0
      event[:to] = md[3] unless md[3] == nil
      event[:message] = md[4].chomp unless md[4] == nil
      if after_filter != nil
        skip = false
        after_filter.each { |key,value|
	  if key == :from_nickname or key == :to then
	    if event[key].downcase != value.downcase then
	      skip = true
	      break
	    end
	  else
            if event[key] != value
              skip = true
              break
            end
	  end
        }
        next if skip == true
      end
      action.call(event)
    }
  end

  ##
  # connect to IRC returns socket
  def connect
    socket = TCPSocket.new(@server, @port.to_i)
    if @options[:ssl] == nil
      return socket
    end
    ssl_context = @options[:ssl]
    ssl_context = OpenSSL::SSL::SSLContext.new()
    unless ssl_context.verify_mode
      warn "warning: peer certificate won't be verified this session."
      ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
    ssl_socket.sync_close = true
    ssl_socket.connect
    return ssl_socket
  end

end

