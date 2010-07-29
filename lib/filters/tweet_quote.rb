require File.join(File.dirname(__FILE__), 'template')

begin
  require 'rubygems'
  require 'mechanize'
rescue LoadError
  puts 'mechanize required for the TweetQuote filter'
end

class BotFilter::TweetQuote < BotFilter::Template
  def process(data)
    raise TypeError unless data.is_a?(Hash)
    
    return data unless data[:type] == :link
    return data unless data[:url].match(Regexp.new('^http://twitter.com/\w+/status(es)?/\d+$'))
    
    begin
      agent = Mechanize.new
    rescue NameError
      puts 'mechanize required for the TweetQuote filter'
      return data
    end
    
    result = {}
    begin
      page = agent.get(data[:url])
      
      author = (page / 'div.full-name').text
      author = (page / 'a.screen-name').text if author == ''
      
      result[:type]   = :quote
      result[:quote]  = (page / 'span.entry-content').text
      result[:source] = author
      result[:url]    = data[:url]
      result[:poster] = data[:poster]
    rescue
      result = data
    end
    
    result
  end
end
