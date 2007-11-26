require 'open-uri'

class BotFilter::LinkTitle
  def process(data)
    raise TypeError unless data.is_a?(Hash)
    
    return data unless data[:type] == :link
    
    title = data[:name]
    unless title
      begin
        open(data[:url]) do |f|
          title = f.read.match(/<title>(.*?)<\/title>/m)[1].strip.gsub(/\s+/, ' ')
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
