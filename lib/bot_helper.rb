require 'open-uri'

module Kernel::BotHelper
  
  # Tries to retrieve a page title for a given URL. If there is
  # an error opening the URL, an empty string is returned.
  #
  # This is a module function and can be called as follows,
  #
  #  <tt>Kernel::BotHelper.get_link_title('http://www.yahoo.com')</tt>
  def get_link_title(url)
    open(url) do |f|
      f.read.match(/<title>(.*)<\/title>/)[1]
    end
  rescue
    ''
  end
  module_function :get_link_title
end
