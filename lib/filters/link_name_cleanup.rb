class BotFilter::LinkNameCleanup
  def process(data)
    raise TypeError unless data.is_a?(Hash)
    
    return data unless data[:type] == :link
    
    result = data
    if result[:name]
      result[:name].strip!
      result[:name].sub!(/(:|-+)$/, '')
      result[:name].strip!
    end
    result
  end
end
