$:.unshift(File.dirname(__FILE__)+'/../libs/')
$:.unshift(File.dirname(__FILE__)+'/../lib/')
$:.unshift(File.dirname(__FILE__)+'/../lib/mocha/lib/')

require 'mocha'

# activate Mocha-style mocking
Spec::Runner.configure do |config|
  config.mock_with :mocha
end

$AL_ENV = {}
$AL_ENV['root'] = File.dirname(__FILE__) + '/../'

require 'inheritable_attributes'
require 'leaf'
require 'logger'
require 'loader'
