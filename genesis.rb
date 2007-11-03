# Loads configuration files, loads leaves and support files, then starts the
# Foliater.

require 'yaml'

# Add each_char method to String.
class String # :nodoc:
  # Yields each character of the string as an Integer in succession.
  def each_char
    (0..(length-1)).each { |index| yield self[index] }
  end
end

# Load the global settings
root = File.dirname(__FILE__)
begin
  $AL_ENV = YAML.load(File.open("#{root}/config/global.yml"))
rescue SystemCallError
  raise "Couldn't find your global.yml file."
end
$AL_ENV['root'] = File.expand_path(root)

# Load the season
season_dir = "#{root}/config/seasons/#{$AL_ENV['season']}"
begin
  raise "No leaves.yml file for the current season." unless Dir.entries(season_dir).include? 'leaves.yml'
rescue SystemCallError
  raise "The current season doesn't have a directory."
end
begin
  $AL_ENV['season_config'] = YAML.load(File.open("#{season_dir}/season.yml"))
rescue
  # season.yml is optional
end
$AL_ENV['debug'] = true if $AL_ENV['season_config']['logging'] == 'debug'

require "#{root}/libs/inheritable_attributes"
require "#{root}/libs/leaf"
require "#{root}/libs/loader"
require "#{root}/libs/logger"

$AL_SRVLOG = ObservantSquirrel.new :leaf_name => '<SYSTEM>', :min_level => :info, :console => $AL_ENV['debug']

# Load support files
Dir.new("#{root}/support").each do |file|
  next if file[0] == ?.
  begin
    require "#{root}/support/#{file}"
  rescue
    $AL_SRVLOG.error $!
  end
end

# Load the leaves
Dir.new("#{root}/leaves").each do |leaf|
  next if leaf[0] == ?.
  begin
    require "#{root}/leaves/#{leaf}"
  rescue
    $AL_SRVLOG.error $!
  end
end

leaves_config_file = "#{season_dir}/leaves.yml"
begin
  Foliater.instance.load_leaves leaves_config_file
  # suspend execution of the master thread until all leaves are dead
  while Foliater.instance.alive?
    Thread.stop
  end
rescue
  $AL_SRVLOG.error $!
end
