require 'open-uri'
require 'yaml'

module Kernel::BotHelper
  def get_link_title(url)
    open(url) do |f|
      YAML::load(f).match(/<title>(.*)<\/title>/)[1]
    end
  rescue
    ''
  end
  module_function :get_link_title
end
