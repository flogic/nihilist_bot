$:.unshift(File.dirname(__FILE__)+'/../lib/')
$:.unshift(File.dirname(__FILE__)+'/../lib/mocha/lib/')

require 'mocha'

module Spec::DSL::BehaviourEval::ModuleMethods 
  def should(name, &block)
    it("should #{name}", &block)
  end
end

# activate Mocha-style mocking
Spec::Runner.configure do |config|
  config.mock_with :mocha
end
