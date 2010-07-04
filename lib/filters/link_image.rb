require File.join(File.dirname(__FILE__), 'template')
require 'open-uri'

class BotFilter::LinkImage < BotFilter::Template
  def process(data)
    raise TypeError unless data.is_a?(Hash)
    
    return data unless data[:type] == :link
    
    result = data
    begin
      open(data[:url], { 'User-Agent' => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)',
                         'Referer' => data[:url].sub(%r{^([a-z]+:/+[^/]+)/.*$}, '\1/') }) do |f|
        if f.content_type.match(/^image/)
          result = {:type => :image, :source => data[:url], :poster => data[:poster]}
          result[:title]   = data[:name]        if data[:name]
          result[:caption] = data[:description] if data[:description]
        end
      end
    rescue
      # there was an error, leave it alone
    end
    result
  end
end
