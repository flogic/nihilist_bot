require File.join(File.dirname(__FILE__), 'template')
require 'open-uri'

class BotFilter::LinkTitle < BotFilter::Template
  def process(data)
    raise TypeError unless data.is_a?(Hash)
    
    return data unless data[:type] == :link
    
    title = data[:name]
    unless title
      begin
        open(data[:url], { 'User-Agent' => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)',
                           'Referer' => data[:url].sub(%r{^([a-z]+:/+[^/]+)/.*$}, '\1/') }) do |f|
          title = f.read.match(/<title>(.*?)<\/title>/mi)[1].strip.gsub(/\s+/, ' ')
        end
      rescue
        title = ''
      end
    end
    
    result = data
    result[:name] = title
    result
  end
end
