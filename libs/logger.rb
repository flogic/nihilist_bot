true # placed here to prevent the class doc from becoming the file doc

# The Observant Squirrel is the logging class for leaves to use. This logger
# works very similarly to the Ruby on Rails logger. The logger uses five
# severity levels, +debug+, +info+, +warn+, and +error+ (in order). It will only
# log messages whose severity is at or above the min_level specified. If you
# have an instance named +logger+, you can log messages using:
#
#  logger.log :info, "Info message"
#  logger.info "Info message"
#  logger.error $! # Logs the exception name and backtrace at the error severity
#
# These messages are logged to a file in the logs/ directory named after the
# current Autumn Leaves season name. For example, if you are running in the
# production season, messages are logged to "logs/production.log". Log entries
# consist of the date and time, the message severity, the leaf name, and the
# message itself, separated by tab characters.
#
# This class does not prune or otherwise truncate logs. Please manage your own
# log file disk usage.
class ObservantSquirrel
  # Valid message severity levels.
  LEVELS = [ :debug, :info, :warn, :error ]

  # The minimum severity level that will be logged.
  attr :min_level, true
  # The name of the leaf that will be recorded for this instance's log messages.
  attr :leaf_name, true
  # Whether or not to print log entries to standard out as well.
  attr :console, true

  # Creates a new logger with an optional hash of settings:
  #
  # <tt>:min_level</tt>:: The lowest severity level that will be logged
  # <tt>:leaf_name</tt>:: The name of the leaf using this logger
  # <tt>:console</tt>:: If true, also prints output to standard out
  #
  # By default, the minimum level is <tt>:warn</tt> and console ouput is
  # suppressed.
  def initialize(options={})
    raise "Environment not ready yet." unless $AL_ENV

    @logfile = "#{$AL_ENV['root']}/log/#{$AL_ENV['season']}.log"
    full_opts = { :min_level => :warn, :leaf_name => "Unnamed Leaf", :console => false }.merge(options)
    self.min_level = full_opts[:min_level]
    self.leaf_name = full_opts[:leaf_name]
    self.console = full_opts[:console]
  end

  # Logs a message with a given level. Raises an exception if the level is
  # invalid. If +message+ is an exception, it will also log the complete
  # backtrace.
  def log(level, message)
    raise ArgumentError, "Invalid level" unless LEVELS.include? level
    return unless level_to_int(level) >= level_to_int(self.min_level)

    File.open(@logfile, 'a+') do |f|
      date = Time.now.strftime "%a %m/%d/%Y %H:%M:%S"
      f.puts "#{date}\t#{level.to_s.capitalize}\t#{self.leaf_name}\t#{message.to_s}"
      puts "#{level.to_s.capitalize}\t#{self.leaf_name}\t#{message.to_s}" if self.console
      if message.respond_to? :backtrace then
        f.puts message.backtrace.collect { |l| "#{date}\t#{level.to_s.capitalize}\t#{self.leaf_name}\t -- #{l}" }
	puts message.backtrace.collect { |l| "#{level.to_s.capitalize}\t#{self.leaf_name}\t -- #{l}" } if self.console
      end
    end
  end

  # Overriden to allow invocations like <tt>logger.warn "Warning message"</tt>.
  def method_missing(symbol, *args)
    if LEVELS.include? symbol and args.size == 1 then
      self.log symbol, args[0]
    else
      super symbol, args
    end
  end

  private

  def level_to_int(level)
    LEVELS.index level
  end
end
