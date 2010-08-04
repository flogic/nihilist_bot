require File.join(File.dirname(__FILE__), 'template')

class BotFilter::YoutubeDomainFix < BotFilter::Template
  def process(data)
    raise TypeError unless data.is_a?(Hash)
    
    return data unless data[:type] == :video
    
    result = data
    result[:embed].sub!(%r{youtube.co[^/]+}, 'youtube.com')
    result
  end
end
