require 'yaml'

require "#{$AL_ENV['root']}/libs/EyeAreSee"

# This is the superclass that all Autumn Leaves use. To write a leaf, sublcass
# this class and implement methods for each of your leaf's commands. Your leaf's
# repertoire of commands is derived from the names of the methods you write. For
# instance, to have your leaf respond to a "!hello" command in IRC, write a
# method like so:
# 
#  def hello_command(sender, channel, text)
#    message "Why hello there!", channel
#  end
#
# Methods of the form <tt>[word]_command</tt> tell the leaf to respond to
# commands in IRC of the form "![word]". They should accept three parameters:
#
# 1. The nick of the person who typed the message
# 2. The channel name where the message was typed
# 3. Any text following the command. For instance, if the person typed "!eat A
#    tasty slice of pizza", the +text+ parameter would be "A tasty slice of
#    pizza". This is nil if no text was supplied with the command.
#
# If you would like to use a prefix other than "!" for your commands, use the
# uses_command_prefix class method.
# 
# If your leaf needs to respond to more complicated commands, you will have to
# override the did_receive_channel_message method. If you like, you can remove
# the quit_command method in your subclass, for instance, to prevent the leaf
# from responding to !quit.
#
# Aside from adding your own <tt>*_command</tt>-type methods, you should
# investigate overriding the "hook" methods, such as will_start_up,
# did_start_up, did_receive_private_message, did_receive_channel_message, etc.
# There's a laundry list of so-named methods you can override. Their default
# implementations do nothing, so there's no need to call +super+.
#
# The convention for Autumn Leaves channel names is: When you specify a channel
# to Autumn Leaves, you can (but don't have to) prefix it with the '#'
# character, if it's a normal IRC channel. When Autumn Leaves gives a channel
# name to you, it will always start with the '#' character (assuming it's a
# normal IRC channel, of course). If your channel is prefixed with a different
# character (say, '&'), you will need to include that prefix every time you pass
# a channel name to an AutumnLeaf method.
#
# So, if you would like your leaf to send a message to the "#kittens" channel,
# you can omit the '#' character; but if it's a server-local channel called
# "&kittens", you will have to provide the '&' character. Likewise, if you are
# overriding a hook method, you can be guaranteed that the channel given to you
# will always be called "#kittens", and not "kittens".
#
# Autumn Leaves comes with a framework for storing settings for your leaf. If
# you have information you'd like remembered even after your leaf exits, use
# the record method to store that information to a YAML file in the 'data'
# directory. Any information you do store can be accessed by the <tt>data</tt>
# hash. For instance:
# 
#  record :destroy_all_humans_mode => :off
#  if data[:destroy_all_humans_mode] == :on then
#    message "DESTROY ALL HUMANS!"
#  end
#
# If you modify data without using the record method, call the sync method after
# your changes are completed.
#
# You can use the <tt>@status</tt> variable to initialize your data, if
# necessary. If <tt>@status</tt> is <tt>:fresh</tt>, then your leaf has no
# existing recorded data, and you should initialize it. If <tt>@status</tt> is
# :reload, the data hash has been loaded from file.
#
# Like Ruby on Rails, you can add filters to each of your commands to be
# executed before or after the command is run. You can do this using the
# before_filter and after_filter methods, just like in Rails. Filters are run in
# the order they are added to the chain. Thus, if you wanted to run your
# authentication filter before you ran your preload filter, you'd write the
# calls in this order:
#
#  class MyLeaf < AutumnLeaf
#    before_filter :my_authenticate
#    before_filter :my_preload
#  end
#
# See the documentation for the before_filter and after_filter methods for more
# information on filters.
#
# Finally, Autumn Leaves comes with a framework for logging as well. It's very
# similar to the Ruby on Rails logging framework. To log an error message:
#
#  logger.log :error, "Quiz data is missing!"
#
# You can shorten this to:
#
#  logger.error "Quiz data is missing!"
#
# Valid log levels are +error+, +warn+, +info+, and +debug+ (in order of
# decreasing severity). By default the logger will only log +info+ events and
# above in production seasons, and will log all messages for debug
# seasons (see the README for more on seasons).
#
# The logger can also accept exceptions, in which case it will log the error
# and its backtrace:
#
#  logger.error $!
#
# To customize the logger, and for more information on logging, see the
# ObservantSquirrel class documentation.
class AutumnLeaf

  # Utility method that creates a hash where the default value for an unknown
  # key is to simply return the key itself:
  #
  #  hash = parroting_hash 'flat' => 'round'
  #  hash['flat'] #=> 'round'
  #  hash['asleep'] #=> 'asleep'
  #  hash['asleep'] = 'awake'
  #  hash['asleep'] #=> 'awake'
  def self.parroting_hash(initial={})
    hash = Hash.new { |h, k| k }
    hash.merge! initial
    return hash
  end

  # Valid IRC colors, in the mIRC style, to be used with the color method.
  COLORS = {
    :black => 1,
    :dark_blue => 2,
    :dark_green => 3,
    :red => 4,
    :brown => 5,
    :purple => 6,
    :dark_yellow => 7,
    :orange => 7,
    :yellow => 8,
    :green => 9,
    :dark_cyan => 10,
    :cyan => 11,
    :blue => 12,
    :magenta => 13,
    :gray => 14,
    :light_gray => 15,
    :white => 16
  }
  # Codes for user modes.
  PRIVILEGE_CODES = { ?v => :voice, ?h => :halfop, ?o => :op, ?a => :superop, ?q => :owner }
  # Codes for channel modes.
  PROPERTY_CODES = parroting_hash ?n => :no_outside_messages, ?t => :protected_topic, ?m => :moderated, ?i => :invite_only, ?p => :private, ?s => :secret, ?l => :user_limit, ?k => :password, ?b => :ban
  # Prefixes in front of a user's nick that indicate a certain privilege level.
  PRIVILEGE_PREFIXES = { ?~ => :owner, ?& => :superop, ?@ => :op, ?% => :halfop, ?+ => :voiced }

  # The nickname for the leaf and the name used to refer to it in other parts of
  # the program.
  attr_reader :name
  # The IRC server the leaf will log into.
  attr_reader :server
  # The password the leaf will send to NickServ to authenticate its nick.
  attr_reader :password
  # The port to use for the IRC server.
  attr_reader :port
  # An array of channels to join on the server.
  attr_reader :channels

  # Instantiates a leaf. +name+ becomes the leaf's nick and is used to reference
  # the leaf throughout the program. No two separate leaves can share the same
  # name. +server+ is the address of the IRC server (<i>e.g.</i>,
  # irc.utonet.org). +options+ is an optional hash that can specify:
  # 
  # <tt>:password</tt>:: The password to send to NickServ, if your leaf's nick
  #                      is registered
  # <tt>:channel</tt>:: The name of a channel to join
  # <tt>:channels</tt>:: An array of channel names to join
  # <tt>:port</tt>:: The port number for the IRC server (6667 by default)
  # <tt>:rejoin</tt>:: Whether or not to rejoin a channel when kicked
  # <tt>:responds_to_private_messages</tt>:: If true, the bot responds to known
  #                                          commands sent in private messages
  #
  # You must at a minimum specify one channel.
  def initialize(name, server, options={})
    raise "Please specify at least one channel." unless options[:channel] or options[:channels]
    @name = name
    @server = server
    @password = options.delete :password
    @channels = options.delete :channels
    @channels ||= [ options.delete(:channel) ]
    @channels.map! do |chan|
      if chan.kind_of? Hash then
        { normalized_channel_name(chan.keys.first) => chan.values.first }
      else
        normalized_channel_name chan
      end
    end
    @port = options.delete :port
    @port ||= 6667
    @options = options
    @break_flag = false

    @logger = ObservantSquirrel.new :leaf_name => @name, :min_level => (if $AL_ENV['debug'] then :debug else :info end), :console => $AL_ENV['debug']

    fresh = load_data
    will_start_up
    initialize_bot

    @status = if fresh then :fresh else :reload end
  end

  # Begins the leaf's event loop. This will cause the leaf to log in and begin
  # responding to messages. This method does not terminate until the leaf does,
  # so consider placing it in its own thread.
  def run
    begin
      while !@break_flag
        logger.info "starting up"
        @bot.start
	@break_flag = true unless @options[:rejoin]
      end
    rescue
      message('Error: ' + $!) if @started_up
      logger.error $!
      @bot.quit if @started_up
    end
  end

  # Sends a message to one or more channels or nicks. If no channels or nicks
  # are specified, broadcasts the message to every channel the leaf is on. Fails
  # silently on error.
  #
  #  message "Look at me!" # Broadcasts to all channels
  #  message "I love kitties", 'kitties' # Sends a message to one channel or person
  #  message "Learn to RTFM", 'help, 'support' # Sends a message to two channels or people
  def message(msg, *channels)
    return if msg.nil? or msg.empty?
    channels = normalized_channels if channels.empty?
    msg.each_line { |line| channels.flatten.each { |chan| @bot.message(chan, line) } }
  end

  # Sets the topic for one or more IRC channels. Example:
  # 
  #  set_topic "Bots sure are fun!", 'channel1', 'channel2'
  #
  # Fails silently on error.
  def set_topic(topic, *channels)
    channels = normalized_channels if channels.empty?
    channels.each { |chan| @bot.send_raw_line "TOPIC #{chan} :#{topic}" }
  end

  # Joins a channel by name. If the channel is password-protected, specify the
  # +password+ parameter. Fails silently on error.
  def join_channel(channel, password=nil)
    channel = normalized_channel_name(channel)
    return if normalized_channels.include? channel
    if password then
      @bot.send_raw_line "JOIN #{channel}, #{password}"
    else
      @bot.send_raw_line "JOIN #{channel}"
    end
    @channels << (password ? { channel => password } : channel)
  end

  # Leaves a channel, specified by name. Fails silently on error.
  def leave_channel(channel, options={})
    channel = normalized_channel_name(channel)
    return unless normalized_channels.include? channel
    @bot.send_raw_line "PART #{channel}"
    remove_channel channel
  end

  # Changes this leaf's IRC nick. Note that the leaf's original nick will still
  # be used by the logger and by <tt>$AL_ENV</tt>.
  def change_nick(nick)
    @bot.send_raw_line "NICK #{nick}"
  end

  # Grants a privilege to a channel member, such as voicing a member. The leaf
  # must have the required privilege level to perform this command. +privilege+
  # can either be a Symbol as used in someone_did_gain_privilege or a String
  # with the letter code for the privilege. Examples:
  #
  #  grant_user_privilege 'mychannel', 'Somedude', :op
  #  grant_user_privilege '#mychannel', 'Somedude', 'oa'
  def grant_user_privilege(channel, nick, privilege)
    channel = normalized_channel_name(channel)
    privcode = PRIVILEGE_CODES.index(privilege).chr if PRIVILEGE_CODES.value? privilege
    privcode ||= privilege
    @bot.send_raw_line "MODE #{channel} +#{privcode} #{nick}"
  end

  # Removes a privilege to a channel member, such as voicing a member. The leaf
  # must have the required privilege level to perform this command. +privilege+
  # can either be a Symbol as used in someone_did_gain_privilege or a String
  # with the letter code for the privilege.
  def remove_user_privilege(channel, nick, privilege)
    channel = normalized_channel_name(channel)
    privcode = PRIVILEGE_CODES.index(privilege).chr if PRIVILEGE_CODES.value? privilege
    privode ||= privilege
    @bot.send_raw_line "MODE #{channel} -#{privcode} #{nick}"
  end

  # Sets a property of a channel, such as moderated. The leaf must have the
  # required privilege level to perform this command. +property+ can either be
  # a Symbol as used in channel_did_gain_property or a String with the letter
  # code for the property. If the property takes an argument (such as when
  # setting a channel password), pass it as the +argument+ paramter. Examples:
  #
  #  set_channel_property '#mychannel', :secret
  #  set_channel_property 'mychannel', :password, 'mypassword'
  #  set_channel_property '#mychannel', 'ntr'
  def set_channel_property(channel, property, argument="")
    channel = normalized_channel_name(channel)
    propcode = PROPERTY_CODES.index(property).chr if PROPERTY_CODES.value? property
    propcode ||= property
    @bot.send_raw_line "MODE #{channel} +#{propcode} #{argument}"
  end

  # Removes a property of a channel, such as moderated. The leaf must have the
  # required privilege level to perform this command. +property+ can either be
  # a Symbol as used in channel_did_gain_property or a String with the letter
  # code for the property. If the property takes an argument (such as when
  # setting a channel password), pass it as the +argument+ paramter.
  def unset_channel_property(channel, property, argument="")
    channel = normalized_channel_name(channel)
    propcode = PROPERTY_CODES.index(property).chr if PROPERTY_CODES.value? property
    propcode ||= property
    @bot.send_raw_line "MODE #{channel} -#{propcode} #{argument}"
  end
  
  # Terminates the leaf. You can specify a goodbye message if you wish.
  def quit(message=nil)
    will_quit
    @break_flag = true
    @bot.quit message
    logger.info "shutting down"
  end
  
  # Returns an array of nicks for users that are in a channel.
  def users(channel)
    channel = normalized_channel_name(channel)
    @names[channel] && @names[channel].keys
  end
  
  # Returns the privilege level of the channel and nick. The privilege level can
  # be <tt>:unvoiced</tt>, <tt>:voiced</tt>, <tt>:halfop</tt>, <tt>:op</tt>,
  # <tt>:superop</tt>, or <tt>:owner</tt>. Returns nil if the nick doesn't exist
  # or if the bot is not on the given channel.
  def privilege(channel, user)
    @names[channel] && @names[channel][user]
  end

  protected
  
  # Describes all possible channel names.
  CHANNEL_REGEX = "[\\+#&!][^\\s\\x7,:]+"
  # Describes all possible nicks.
  NICK_REGEX = "[a-zA-Z][a-zA-Z0-9\\-_\\[\\]\\{\\}\\\\|`\\^]+"
  
  class_inheritable_reader :command_prefix
  
  # Sets the prefix for commands. By default, this is "!". If you would like to
  # use, for instance, a question mark, you would call this method in your class
  # definition like so:
  #
  #  class MyLeaf < AutumnLeaf
  #    uses_command_prefix '?'
  #  end
  #
  # Now, instead of responding to commands like "!quit" and "!about", your leaf
  # will respond to commands like "?quit" and "?about". You can use this to
  # ensure two leafs that share a channel do not both respond to the same
  # command.
  def self.uses_command_prefix(prefix)
    if prefix.kind_of? String : prefix_str = prefix
    elsif prefix.kind_of? Fixnum : prefix_str = prefix.chr
    else prefix_str = prefix.to_s end
    
    write_inheritable_attribute :command_prefix, Regexp.escape(prefix_str)
  end
  
  uses_command_prefix '!'

  # Adds a filter to the end of the list of filters to be run before a
  # command is executed. You can use these filters to perform tasks that
  # prepare the leaf to respond to a command, or to determine whether or not a
  # command should be run (<i>e.g.</i>, authentication). Pass the name of your
  # filter as a symbol, and an optional has of options:
  #
  # <tt>:only</tt>:: Only run the filter for these commands
  # <tt>:except</tt>:: Do not run the filter for these commands
  #
  # Each option can refer to a single command or an Array of commands. Commands
  # should be symbols such as <tt>:quit</tt> for the !quit command.
  #
  # Your method will be called with four parameters: The sender, the channel,
  # the command (such as the String "quit" for the !quit command), the message
  # (which is everything after the command, or nil if nothing was afterwards),
  # and an options hash. Any additional options in before_filter's options hash
  # will be passed through to the filter method's options hash. If your filter
  # returns either nil or false, the filter chain will be halted and the command
  # will not be run. Example:
  #
  #  before_filter :authenticate, :only => [ :quit, :reload ], :use_passwd_file => true
  # 
  # As a result, any time the bot receives a "!quit" or "!reload" command, it
  # will first evaluate
  #
  #  authenticate_filter <sender>, <channel>, <command>, <message>, :use_passwd_file => true
  #
  # And if the result is not false or nil, the command will be executed.
  def self.before_filter(filter, options={})
    if options[:only] and !options[:only].kind_of? Array then
      options[:only] = [ options[:only] ]
    end
    if options[:except] and !options[:except].kind_of? Array then
      options[:except] = [ options[:only] ]
    end
    write_inheritable_array 'before_filters', [ [ filter.to_sym, options ] ]
  end

  # Adds a filter to the end of the list of filters to be run after a
  # command is executed. You can use these filters to perform tasks that
  # must be done after a command is run, such as cleaning up temporary files.
  # Pass the name of your filter as a symbol, and an optional has of options.
  # See the before_filter docs for more on the options hash.
  #
  # Your method will be called with five parameters -- see the before_filter
  # method for more information. Unlike before_filter filters, however, any
  # return value is ignored. Example:
  #
  #  after_filter :clean_tmp, :only => :sendfile, :remove_symlinks => true
  # 
  # As a result, any time the bot receives a "!quit" or "!reload" command, after
  # executing the command it will evaluate
  #
  #  authenticate_filter <sender>, <channel>, <command>, <message>, :use_passwd_file => true
  def self.after_filter(filter, options={})
    if options[:only] and !options[:only].kind_of? Array then
      options[:only] = [ options[:only] ]
    end
    if options[:except] and !options[:except].kind_of? Array then
      options[:except] = [ options[:only] ]
    end
    write_inheritable_array 'after_filters', [ [ filter.to_sym, options ] ]
  end

  # Writes some information to the external settings file. This information
  # will be available via the <tt>data</tt> hash. This method only takes a
  # hash.
  def record(data)
    raise ArgumentError, "Must supply a hash" unless data.kind_of? Hash
    @data.merge! data
    sync
  end

  # Returns a hash of data recorded to file with the record method. This data
  # persists even after the process is terminated.
  def data
    @data
  end

  # Writes any changes to the data hash to disk. If you have modified the data
  # hash directly, such as:
  #
  #  data[:my_setting] = 15
  # 
  # rather than using the record method, like:
  #
  #  record :my_setting => 15
  #
  # you must call this method after you are finished making your changes to
  # ensure they are written out to disk.
  def sync
    File.open(data_file, 'w') { |f| f.puts @data.to_yaml }
  end

  # Returns the ObservantSquirrel logger handling this leaf.
  def logger
    @logger
  end

  # Colors IRC text using mIRC-style escape characters. +colorname+ is a color
  # in the COLORS hash. You can optionally specify a hash of options:
  #
  # <tt>:suppress_space</tt>:: By default, a space is added after the colored
  #                            string to ensure it formats correctly. (This is
  #                            due to limitations in mIRC's color system.) If
  #                            you're sure it won't format incorrectly, you can
  #                            suppress the trailing space by setting this to
  #                            true.
  def self.color(str, colorname, options={})
    return str unless COLORS.include? colorname
    return 3.chr + COLORS[colorname].to_s + str + 3.chr + (if options[:suppress_space] then '' else ' ' end)
  end

  # Calls the color class method. Example:
  #
  #  message color("Green with envy!", :green) # Sends a message in green
  def color(str, colorname, options={})
    return AutumnLeaf::color(str, colorname)
  end
  
  # Given a full channel name, returns the channel type as a symbol. Possible
  # return values are <tt>:normal</tt>, <tt>:local</tt> for a server-specific
  # channel, <tt>:no_channel_modes</tt> for a channel with no channel mode
  # support, and <tt>:unknown</tt> for channels of an unknown type.
  def channel_type(channel)
    case channel[0]
      when ?# then :normal
      when ?& then :local
      when ?+ then :no_channel_modes
      else :unknown
    end
  end

  # Calls the parroting_hash class method.
  def parroting_hash(initial={})
    return AutumnLeaf::parroting_hash(initial)
  end
  
  # Invoked just before the leaf starts up. Override this method to do any
  # pre-startup tasks you need. <tt>data</tt> and <tt>logger</tt> are both
  # available.
  def will_start_up
  end

  # Invoked after the leaf is started up and is ready to accept commands.
  # Override this method to do any post-startup tasks you need, such as
  # displaying a greeting message.
  def did_start_up
  end
  
  # Invoked just before the leaf exists. Override this method to perform any
  # pre-shutdown tasks you need.
  def will_quit
  end

  # Invoked when the leaf receives a private (whispered) message.
  def did_receive_private_message(sender, msg)
  end

  # Invoked when a message is sent to a channel the leaf is a member of. This
  # method is not invoked if the message was handled by a
  # <tt>*_command</tt>-type method.
  def did_receive_channel_message(sender, channel, msg)
  end

  # Invoked when someone joins a channel the leaf is a member of.
  def someone_did_join_channel(nick, channel)
  end

  # Invoked when someone leaves a channel the leaf is a member of.
  def someone_did_leave_channel(nick, channel)
  end

  # Invoked when someone gains a channel privilege. +privilege+ can be any value
  # in the PRIVILEGE_CODES hash. If the privilege is unknown, it will be a
  # String (not a Symbol) equal to the letter value for that privilege
  # (<i>e.g.</i>, 'v' for voice).
  def someone_did_gain_privilege(nick, channel, privilege, bestower)
  end

  # Invoked when someone loses a channel privilege.
  def someone_did_lose_privilege(nick, channel, privilege, bestower)
  end

  # Invoked when a channel gains a property.  +property+ can be any value in the
  # PROPERTY_CODES hash. If the peroperty is unknown, it will be a String (not a
  # Symbol) equal to the letter value for that property (<i>e.g.</i>, 'k' for
  # password). If the property takes an argument (such as user limit or
  # password), it will be passed via +argument+ (which is otherwise nil).
  def channel_did_gain_property(channel, property, argument, bestower)
  end

  # Invoked when a channel loses a property.
  def channel_did_lose_property(channel, property, argument, bestower)
  end

  # Invoked when someone changes a channel's topic. +topic+ is the new topic.
  def someone_did_change_topic(nick, channel, topic)
  end

  # Invoked when someone invites another person to a channel. For most IRC
  # servers, this will only be invoked if the leaf itself is invited into a
  # channel.
  def someone_did_invite(nick, invitee, channel)
  end

  # Invoked when someone is kicked from a channel. Note that this is called when
  # your leaf is kicked as well, so it may well be the case that +channel+ is a
  # channel you are no longer in! (If you have the +rejoin+ option set, then
  # this will be called _after_ your leaf rejoins the channel.)
  def someone_did_kick(nick, channel, victim, msg)
  end

  # Invoked when a notice is received. Notices are like channel or pivate
  # messages, except that leaves are expected _not_ to respond to them.
  # +recipient+ is either a channel or a user name.
  def did_receive_notice(nick, recipient, msg)
  end

  # Invoked when a user changes his nick.
  def nick_did_change(oldnick, newnick)
  end

  # Invoked when someone quits IRC.
  def someone_did_quit(nick, msg)
  end
  
  # Invoked when the leaf attempts to log in but the nickname is already in use.
  # Its return value will be used as the new nick to use. By default, appends an
  # underscore to the end of the name and tries again. +current_nick+ is the
  # nick that the leaf currently has, or an empty string if the leaf has not yet
  # chosen a valid nick. +desired_nick+ is the nick that the leaf attempted to
  # use.
  def nickname_in_use(current_nick, desired_nick)
    desired_nick + '_'
  end
  
  # Invoked when the leaf attempts to perform an action on a user that doesn't
  # exit. By default, logs an unhelpful warning message. Override this method if
  # you would like alternate behaivor in this situation. Unfortunately, at this
  # time there is no way for you to know what the leaf was trying to do when the
  # error occurred, so you'll have to figure that out yourself using some clever
  # coding.
  def no_such_nick(nick)
    logger.warn "No such nickname #{nick}"
  end
  
  # Invoked when the leaf attempts to join a password-protected channel with no
  # password or an incorrect password. By default, logs a warning message.
  def invalid_channel_password(channel)
    logger.warn "Couldn't join channel #{channel}: Invalid password"
  end
  
  # Invoked when the leaf attempts to join a user-limited channel that is at its
  # limit.  By default, logs a warning message.
  def too_many_channel_members(channel)
    logger.warn "Couldn't join channel #{channel}: Too many members"
  end
  
  # Invoked when the leaf attempts to do something without having the necessary
  # privilege level to do it. By default, logs an unhelpful warning message.
  # Override this method if you would like alternate behaivor in this situation.
  # Unfortunately, at this time there is no way for you to know what the leaf
  # was trying to do when the error occurred, so you'll have to figure that out
  # yourself using some clever coding.
  def insufficient_privileges(channel)
    logger.warn "Insufficient privileges to perform an action on #{channel}"
  end
  
  # Invoked when the leaf attempts to join an invite-only channel without an
  # invite. By default, logs a warning message.
  def invite_only_channel(channel)
    logger.warn "Couldn't join channel #{channel}: Invite-only"
  end
  
  # Invoked when the leaf attempts to join a channel from which it is banned. By
  # default, logs a warning message.
  def banned_from_channel(channel)
    logger.warn "Couldn't join channel #{channel}: Banned"
  end

  # Typing this command terminates the leaf.
  def quit_command(sender, channel, msg)
    quit
  end

  # Typing this command reloads all source code for the leaf, allowing you to
  # make "on-the-fly" changes without restarting the process. There is one
  # caveat: If you make any change to a constant or other unchangeable value,
  # you will need to restart the process. Any other change can be reloaded.
  #
  # This command does not reload the YAML configuration files.
  def reload_command(sender, channel, msg)
    reload
    message "All code successfully reloaded.", channel
  end

  # Typing this command reloads all data for the leaf from file. You should use
  # this command if you make any changes to the data files on disk; the bot will
  # reload the file and your changes will be in memory.
  def sync_command(sender, channel, msg)
    load_data
    message "All data successfully reloaded from disk.", channel
  end

  # Typing this command will display information about the version of Autumn
  # Leaves that is running this leaf.
  def alabout_command(sender, channel, msg)
    message "Autumn Leaves version 1.0.1 (9-21-07), an IRC bot framework for Ruby (http://autumn-leaves.googlecode.com). Includes code from EyeAreSee.", channel
  end

  private

  def initialize_bot
    @bot = EyeAreSee.new @name, @server, :port => @port, :channels => @channels, :password => @password
    @bot.logger = @logger
    # Pingback
    @bot.on_message(/^PING :(.+)$/) { |event| pong event[:matchdata][1] }
    # Hooks
    @bot.on_message(Regexp.new("^:(#{NICK_REGEX})!.+ JOIN :(#{CHANNEL_REGEX})")) { |event| someone_did_join_channel event[:matchdata][1], event[:matchdata][2] }
    @bot.on_message(Regexp.new("^:(#{NICK_REGEX})!.+ PART (#{CHANNEL_REGEX})")) { |event| someone_did_leave_channel event[:matchdata][1], event[:matchdata][2] }
    @bot.on_message(Regexp.new("^:(#{NICK_REGEX})!.+ MODE (#{CHANNEL_REGEX}) ([^\s]+)\s?(.*)$"))  do |event|
      mode_str = event[:matchdata][3]
      channel = event[:matchdata][2]
      user_or_arg = event[:matchdata][4].chomp
      user_or_arg = nil if user_or_arg.empty?
      bestower = event[:matchdata][1]

      if mode_str.length == 2 and PRIVILEGE_CODES.include? mode_str[1] then
        @bot.send_raw_line "NAMES #{channel}"
        gained_privileges(mode_str) { |priv| someone_did_gain_privilege user_or_arg, channel, priv, bestower }
        lost_privileges(mode_str) { |priv| someone_did_lose_privilege user_or_arg, channel, priv, bestower }
      elsif mode_str.length == 2 and PROPERTY_CODES.include? mode_str[1] then
        gained_properties(mode_str) { |prop| channel_did_gain_property channel, prop, user_or_arg, bestower }
        lost_properties(mode_str) { |prop| channel_did_lose_property channel, prop, user_or_arg, bestower }
      #TODO if it's an unknown mode and the argument is a user name, treat it like a user mode
      else
        gained_properties(mode_str) { |prop| channel_did_gain_property channel, prop, user_or_arg, bestower }
        lost_properties(mode_str) { |prop| channel_did_lose_property channel, prop, user_or_arg, bestower }
      end
    end
    @bot.on_message('TOPIC') { |event| someone_did_change_topic event[:from_nickname], event[:to], event[:message] }
    @bot.on_message('INVITE') { |event| someone_did_invite event[:from_nickname], event[:to], event[:message] }
    @bot.on_message(Regexp.new("^:(#{NICK_REGEX})!.+ KICK (#{CHANNEL_REGEX}) (#{NICK_REGEX}) :(.+)$")) do |event|
      channel = event[:matchdata][2]
      victim = event[:matchdata][3]
      if victim == @name then
        channel_pair = remove_channel(channel)
        join_channel(channel_pair.keys.first, channel_pair.values.first) if @options[:rejoin]
      end
      someone_did_kick event[:matchdata][1], channel, victim, event[:matchdata][4].chomp
    end
    @bot.on_message('NOTICE') { |event| did_receive_notice event[:from_nickname], event[:to], event[:message] }
    @bot.on_message(Regexp.new("^:(#{NICK_REGEX})!.+ NICK :(#{NICK_REGEX})")) do |event|
      @name = event[:matchdata][2] if @name == event[:matchdata][1]
      nick_did_change event[:matchdata][1], event[:matchdata][2]
    end
    @bot.on_message(Regexp.new("^:(#{NICK_REGEX})!.+ QUIT :(.+)$")) { |event| someone_did_quit event[:matchdata][1], event[:matchdata][2].chomp }
    # Logging
    @bot.on_message { |line| logger.debug ">> #{line}" }
    @bot.on_server_message { |event| logger.debug "S>> #{event[:code]}: #{event[:message]}" }
    # Startup
    @bot.on_server_message(376) { |event| startup_check }
    # NAMES list
    @bot.on_message(Regexp.new("^:.+ 353 [^\\s]+ = (#{CHANNEL_REGEX}) :(.+)$")) { |event| update_names_list event[:matchdata][1], event[:matchdata][2].chomp.strip }
    # No such nick
    @bot.on_message(Regexp.new("^:.+ 401 #{@name} (\\w+) :")) do |event|
      nick = event[:matchdata][1]
      no_such_nick nick
    end
    # Nickname in use
    @bot.on_message(Regexp.new("^:.+ 433 (#{NICK_REGEX}|\\*) (#{NICK_REGEX}) :")) do |event|
      oldnick = event[:matchdata][1]
      oldnick = '' if oldnick == '*'
      newname = nickname_in_use(oldnick, event[:matchdata][2])
      if newname then
        @name = newname
        @bot.send_raw_line "NICK #{newname}"
      else
        raise "Nickname #{name} is in use, and no alternate nick was provided."
      end
    end
    # Too many users
    @bot.on_message(Regexp.new("^:.+ 471 #{@name} (#{CHANNEL_REGEX}) :")) do |event|
      channel = event[:matchdata][1]
      remove_channel channel
      too_many_channel_members channel
    end
    # Invite-only channel
    @bot.on_message(Regexp.new("^:.+ 473 #{@name} (#{CHANNEL_REGEX}) :")) do |event|
      channel = event[:matchdata][1]
      remove_channel channel
      invite_only_channel channel
    end
    # Banned from channel
    @bot.on_message(Regexp.new("^:.+ 474 #{@name} (#{CHANNEL_REGEX}) :")) do |event|
      channel = event[:matchdata][1]
      remove_channel channel
      banned_from_channel channel
    end
    # Invalid channel password
    @bot.on_message(Regexp.new("^:.+ 475 #{@name} (#{CHANNEL_REGEX}) :")) do |event|
      channel = event[:matchdata][1]
      remove_channel channel
      invalid_channel_password channel
    end
    # Insufficient privileges
    @bot.on_message(Regexp.new("^:.+ 482 #{@name} (#{CHANNEL_REGEX}) :")) do |event|
      channel = event[:matchdata][1]
      insufficient_privileges channel
    end
    # Private messages
    @bot.on_message('privmsg', :to => @name) { |event| did_receive_private_message event[:from_nickname], event[:message] }
    # Channel messages
    @bot.on_message('privmsg') do |event|
      if normalized_channels.include? event[:to] or @options[:respond_to_private_messages] then
        if event[:message] =~ /^#{command_prefix}(\w+)\s+(.*)$/ then
	  begin
	    name = $1
	    msg = $2
	    if run_before_filters(name, event[:from_nickname], event[:to], msg) then
              method(name.downcase + '_command')[event[:from_nickname], event[:to], $2]
  	      run_after_filters name, event[:from_nickname], event[:to], event[:message]
	    end
	  rescue NameError
	    unless $!.message.include?(name.downcase + '_command') then
	      raise
	    end
	  end
	elsif event[:message] =~ /^#{command_prefix}(\w+)$/ then
	  begin
	    name = $1
	    if run_before_filters(name, event[:from_nickname], event[:to], nil) then
              method(name.downcase + '_command')[event[:from_nickname], event[:to], $2]
  	      run_after_filters name, event[:from_nickname], event[:to], event[:message]
	    end
	  rescue NameError
	    unless $!.message.include?(name.downcase + '_command') then
	      raise
	    end
	  end
	else
	  did_receive_channel_message event[:from_nickname], event[:to], event[:message]
	end
      end
    end
  end

  def startup_check
    # Join channel; task originally performed by EyeAreSee
    @channels.each do |channel|
      channel.kind_of?(Hash) ? @bot.send_raw_line("JOIN #{channel.keys.first}, #{channel.values.first}") : @bot.send_raw_line("JOIN #{channel}")
    end
 
    # AutumnLeaf tasks
    return if @started_up
    @started_up = true
    did_start_up
  end

  def pong(hashcode)
    @bot.send_raw_line "PONG :#{hashcode}"
  end

  def data_file
    "#{$AL_ENV['root']}/data/#{@name}.#{$AL_ENV['season']}.yml"
  end

  def load_data
    begin
      @data = YAML::load(File.open(data_file))
      return false
    rescue
      @data = Hash.new
    end
    return true
  end

  def reload
    Dir.new("#{$AL_ENV['root']}/leaves").each do |file|
      next if file[0] == ?.
      load "#{$AL_ENV['root']}/leaves/#{file}"
    end
    Dir.new("#{$AL_ENV['root']}/support").each do |file|
      next if file[0] == ?.
      load "#{$AL_ENV['root']}/support/#{file}"
    end
    #TODO it's slow to reload everything in leaves/ and support/ for every leaf,
    #TODO but there's not really a better way for now
    logger.info "reloaded"
  end

  def run_before_filters(cmd, sender, channel, msg)
    command = cmd.to_sym
    self.class.before_filters.each do |filter, options|
      local_opts = options.dup
      next if local_opts[:only] and not local_opts.delete(:only).include? command
      uext if local_opts[:except] and local_opts.delete(:except).include? command
      return false unless method("#{filter.to_s}_filter")[sender, channel, cmd.to_s, msg, local_opts]
    end
    return true
  end

  def run_after_filters(cmd, sender, channel, msg)
    command = cmd.to_sym
    self.class.after_filters.each do |filter, options|
      local_opts = options.dup
      next if local_opts[:only] and not local_opts.delete(:only).include? command
      next if local_opts[:except] and local_opts.delete(:except).include? command
      method("#{filter.to_s}_filter")[sender, channel, cmd.to_s, msg, local_opts]
    end
  end

  def gained_privileges(privstr)
    return unless privstr[0] == ?+
    privstr[1,privstr.length].each_char { |c| yield PRIVILEGE_CODES[c] }
  end

  def lost_privileges(privstr)
    return unless privstr[0] == ?-
    privstr[1,privstr.length].each_char { |c| yield PRIVILEGE_CODES[c] }
  end

  def gained_properties(propstr)
    return unless propstr[0] == ?+
    propstr[1,propstr.length].each_char { |c| yield PROPERTY_CODES[c] }
  end

  def lost_properties(propstr)
    return unless propstr[0] == ?-
    propstr[1,propstr.length].each_char { |c| yield PROPERTY_CODES[c] }
  end

  def self.before_filters
    read_inheritable_attribute('before_filters') or []
  end

  def self.after_filters
    read_inheritable_attribute('after_filters') or []
  end
  
  def update_names_list(channel, names)
    @names ||= Hash.new
    @names[channel] = Hash.new
    names.split(/\s+/).each do |name|
      if PRIVILEGE_PREFIXES.has_key? name[0] then
        @names[channel][name[1,name.length]] = PRIVILEGE_PREFIXES[name[0]]
      else
        @names[channel][name] = :unvoiced
      end
    end
  end
  
  def normalized_channel_name(channel)
    [ ?#, ?&, ?+, ?! ].include?(channel[0]) ? channel : '#' + channel
  end

  def normalized_channels
    @channels.collect { |c| c.to_a.flatten.first }
  end

  def remove_channel(channel)
    # Store the channel and password so we can return it later
    password = nil
    @channels.each { |c| password = c[channel] if c.kind_of?(Hash) and c[channel] }
    # And delete the channel
    @channels.delete_if { |c| c.kind_of?(Hash) ? c.keys.first == channel : c == channel }
    # And return it
    return { channel, password }
  end
end


