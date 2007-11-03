require 'net/http'
require 'uri'

# post to tumblr.com -- see http://www.tumblr.com/api/
class BotSender::Tumblr < BotSender
  def validate(args = {})
    [ :post_url, :site_url, :email, :password ].each {|arg| raise ArgumentError, ":#{arg} is required" unless args[arg] }
    @post_url = args[:post_url]
    @email    = args[:email]
    @password = args[:password]
    @site_url = args[:site_url]
  end

  def do_quote(args = {})
    result = Net::HTTP.post_form(URI.parse(@post_url), { 
      :type     => 'quote', 
      :quote    => (args[:quote] || ''), 
      :source   => (args[:source] || ''), 
      :email    => @email, 
      :password => @password
    })
    handle_response(result, args)
  end

  def do_text(args = {})
    result = Net::HTTP.post_form(URI.parse(@post_url), { 
      :type     => 'regular', 
      :title    => (args[:title] || ''),
      :body     => (args[:body] || ''),
      :email    => @email,
      :password => @password
    })
    handle_response(result, args)
  end

  def do_image(args = {})
    result = Net::HTTP.post_form(URI.parse(@post_url), { 
      :type           => 'photo',
      :source         => (args[:source] || ''),
      :caption        => (args[:caption] || ''), 
      :email          => @email,
      :password       => @password
    })
    handle_response(result, args)
  end

  def do_chat(args = {})
    result = Net::HTTP.post_form(URI.parse(@post_url), { 
      :type           => 'conversation', 
      :title          => (args[:title] || ''),
      :conversation   => (args[:body] || ''),
      :email          => @email,
      :password       => @password
    })
    handle_response(result, args)
  end
  
  def do_video(args = {})
    result = Net::HTTP.post_form(URI.parse(@post_url), { 
      :type           => 'video', 
      :caption        => (args[:caption] || ''),
      :embed          => (args[:embed] || ''),
      :email          => @email,
      :password       => @password
    })
    handle_response(result, args)
  end

  def do_link(args = {})
    result = Net::HTTP.post_form(URI.parse(@post_url), { 
      :type           => 'link', 
      :url            => (args[:url] || ''),
      :name           => (args[:name] || ''),
      :description    => (args[:description] || ''),
      :email          => @email,
      :password       => @password
    })
    handle_response(result, args)
  end
  
  def handle_response(response, metadata)
    return nil unless response
    case response
      when Net::HTTPSuccess
        "created #{metadata[:type]} for #{metadata[:poster]} at #{@site_url.sub(%r{/$}, '')}/post/#{response.body.to_s}"
      else
        "encountered error: [#{response.error!}] when trying to post #{metadata[:type]} for #{metadata[:poster]}"
    end
  end
end