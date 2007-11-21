class BotFilter::PosterInfo
  def process(data)
    poster_info = "(posted by #{data[:poster]})"
    
    result = data
    
    key = case data[:type]
      when :image, :video : :caption
      when :quote         : :source
      when :link          : :description
    end
    
    if key
      data[key] ||= ''
      data[key] += " #{poster_info}"
    else
      key = case data[:type]
        when :fact, :true_or_false : :body
      end
      
      data[key] = poster_info
    end
    
    result
  end
end