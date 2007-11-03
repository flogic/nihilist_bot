require 'yaml'
require 'singleton'

# Loads leaves and executes them in their own threads. Manages the threads and
# oversees all leaves. This is a singleton class; access the instance with the
# +instance+ class method.
class Foliater
  include Singleton

  # Loads the leaves specified in a given YAML file. See the README file for
  # more on how the YAML is specified.
  def load_leaves(yml_file)
    raise "Environment not ready yet" unless $AL_ENV

    leaf_info = YAML.load(File.open(yml_file))
    leaf_info.each do |leaf|
      # Set up options
      name = leaf['nick']
      name ||= leaf['type']
      server = leaf['server']
      options = leaf.reject { |k, v| [ 'nick', 'type', 'server' ].include? k }
      sym_opts = Hash.new
      options.each { |k,v| sym_opts[k.to_sym] = v }
      # Auto-include support file
      helper = nil
      begin
        helper = Kernel.const_get(leaf['type'] + 'Helper')
      rescue NameError
        $AL_SRVLOG.info "Helper class not found for leaf #{leaf['type']}"
      end
      # Load the leaf
      begin
        leaf_class = Kernel.const_get(leaf['type'])
      rescue NameError
        $AL_SRVLOG.error "couldn't find class to load for leaf #{leaf['type']}"
	$AL_SRVLOG.error $!
      end
      load_leaf leaf_class, helper, name, server, sym_opts
    end
  end

  # Returns true if there is at least one leaf still running.
  def alive?
    @leaf_threads and @leaf_threads.any? { |nick, thread| thread.alive? }
  end

  # This method yields each AutumnLeaf subclass that was loaded, allowing
  # you to iterate over each leaf. For instance, to take attendance:
  #
  #  Foliater.instance.each_leaf { |leaf| leaf.message "Here!" }
  def each_leaf
    @leaves.each { |leaf| yield leaf }
  end

  private

  def load_leaf(leaf_class, helper, nick, server, options={})
    @leaf_threads ||= Hash.new
    @leaves ||= Array.new

    leaf = leaf_class.new nick, server, options
    leaf.extend(helper) if helper
    @leaves << leaf
    @leaf_threads[nick] = Thread.new(Thread.current) do |parent_thread|
      # The thread will run the leaf until it exits, then inform the main thread
      # that it has exited
      leaf.run
      parent_thread.wakeup
    end
  end
end
