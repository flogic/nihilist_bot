require File.join(File.dirname(__FILE__), 'template')
require 'uri'
require 'cgi'

class BotFilter::YoutubeParamFix < BotFilter::Template
  def process(data)
    raise TypeError unless data.is_a?(Hash)
    
    return data unless data[:type] == :video
    
    uri = URI.parse(data[:embed])
    params = CGI.parse(uri.query)
    
    video_id = params.delete('v')
    return data if params.length.zero?
    
    result = data
    uri.query = ["v=#{video_id}", params.collect { |pair|  pair.join('=') } ].join('&')
    result[:embed] = uri.to_s
    result
  end
end
