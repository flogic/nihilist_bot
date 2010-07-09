$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib])
$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib mocha lib])

require 'mocha'

# activate Mocha-style mocking
Spec::Runner.configure do |config|
  config.mock_with :mocha
end
