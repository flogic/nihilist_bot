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
  
  # Adds poster info to the appropriate field
  def add_poster_info(info)
    poster_info = "(posted by #{info[:poster]})"
    
    key = case info[:type]
      when :image, :video : :caption
      when :quote         : :source
      when :link          : :description
    end
    
    if key
      info[key] ||= ''
      info[key] += " #{poster_info}"
    else
      key = case info[:type]
        when :fact, :true_or_false : :body
      end
      
      info[key] = poster_info
    end
    
    info
  end
  module_function :add_poster_info
end
