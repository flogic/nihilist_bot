require File.expand_path(File.join(File.dirname(__FILE__), *%w[.. spec_helper]))
require 'senders/tumblr'


# TODO: make sure that nil values passed in don't freak things out


def setup_for_posting(extra = {})
  @params = { 
              :destination => :tumblr, 
              :post_url    => 'http://www.domain.com/example/post/',
              :site_url    => 'http://www.domain.com/',
              :email       => 'example@domain.com',
              :password    => 's3kr17'
            }
  @params = @params.merge(extra)
  @sender = BotSender.new(@params)
end


describe BotSender::Tumblr, "when creating" do
  before(:each) do
    @params = { 
                :destination => :tumblr, 
                :post_url    => 'http://www.domain.com/example/post/',
                :site_url    => 'http://www.domain.com/',
                :email       => 'example@domain.com',
                :password    => 's3kr17'
              }
  end
  
  it "should require a posting URL to be specified" do
    Proc.new { BotSender.new(@params.delete_if {|k,v| k == :post_url }) }.should raise_error(ArgumentError)
  end
  
  it "should require a posting email to be specified" do
    Proc.new { BotSender.new(@params.delete_if {|k,v| k == :email }) }.should raise_error(ArgumentError)
  end
  
  it "should require a posting password to be specified" do
    Proc.new { BotSender.new(@params.delete_if {|k,v| k == :password }) }.should raise_error(ArgumentError)  
  end
  
  it "should require a site URL to be specified" do
    Proc.new { BotSender.new(@params.delete_if {|k,v| k == :site_url }) }.should raise_error(ArgumentError)      
  end
  
  it "should succeed when a post_url, site url, email address, and password are provided" do
    Proc.new { BotSender.new(@params) }.should_not raise_error
  end

  it "should allow a group to be specified" do
    Proc.new { BotSender.new(@params.merge(:group => 'other.tumblr.com')) }.should_not raise_error
  end
end

describe BotSender::Tumblr, "when generating a summary response" do
  before(:each) do
    setup_for_posting
    @params = { :poster => 'poster', :type => 'widget' }
    @mock_response = stub('fake response')
  end
  
  it "should include a link to a successfully created post" do
    Net::HTTPSuccess.expects(:===).returns(true)
    @mock_response.stubs(:body).returns('http://www.domain.com/post/1')
    @sender.handle_response(@mock_response, @params).should match(%r{http://www.domain.com/})
  end
  
  it "should include the poster name with a post summary" do
    Net::HTTPSuccess.expects(:===).returns(true)
    @mock_response.stubs(:body).returns('http://www.domain.com/post/1')
    @sender.handle_response(@mock_response, @params).should match(%r{poster})
  end

  it "should include the post type with a post summary" do
    Net::HTTPSuccess.expects(:===).returns(true)
    @mock_response.stubs(:body).returns('http://www.domain.com/post/1')
    @sender.handle_response(@mock_response, @params).should match(%r{widget})    
  end
  
  it 'should be able to handle a symbol type' do
    @params[:type] = :widget
    Net::HTTPSuccess.expects(:===).returns(true)
    @mock_response.stubs(:body).returns('http://www.domain.com/post/1')
    @sender.handle_response(@mock_response, @params).should match(%r{widget})    
  end
  
  it "should english-ize the post type for the post summary" do
    Net::HTTPSuccess.expects(:===).returns(true)
    @mock_response.stubs(:body).returns('http://www.domain.com/post/1')
    @sender.handle_response(@mock_response, @params.merge(:type => 'true_or_false')).should match(%r{true or false})    
  end
  
  it "should include the error string when an error occurs" do
    Net::HTTPSuccess.stubs(:===).returns(false)
    @mock_response.expects(:error!).returns('Really Bad Error')
    @sender.handle_response(@mock_response, @params).should match(%r{Really Bad Error})        
  end
  
  it "should include the poster name when reporting an error" do
    Net::HTTPSuccess.stubs(:===).returns(false)
    @mock_response.stubs(:error!).returns('Really Bad Error')
    @sender.handle_response(@mock_response, @params).should match(%r{poster})        
  end
  
  it "should include the post type when reporting an error" do
    Net::HTTPSuccess.stubs(:===).returns(false)
    @mock_response.stubs(:error!).returns('Really Bad Error')
    @sender.handle_response(@mock_response, @params).should match(%r{widget})            
  end
end

describe BotSender::Tumblr, "when posting a quote" do
  before(:each) do
    setup_for_posting
  end

  it "should authenticate with the email address and password" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:email] == @params[:email] and args[:password] == @params[:password]
    end
    @sender.do_quote(:quote => 'sibboleth, yo!', :source => 'ymendel')    
  end

  it "should include the group if provided" do
    group = 'elsewards.tumblr.com'
    setup_for_posting(:group => group)
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:group] == group
    end
    @sender.do_quote(:quote => 'sibboleth, yo!', :source => 'ymendel')    
  end

  it "should make a post to the post url" do
    Net::HTTP.expects(:post_form).with do |url, args|
      url == URI.parse(@params[:post_url])
    end
    @sender.do_quote(:quote => 'f*ckmuffler!', :source => 'vinbarnes')
  end

  it "should post a quote" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:type] == 'quote'
    end
    @sender.do_quote(:quote => 'sibboleth, yo!', :source => 'ymendel')
  end

  it "should set the quote body to the provided quote" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:quote] == 'sibboleth, yo!'
    end
    @sender.do_quote(:quote => 'sibboleth, yo!', :source => 'ymendel')
  end
  
  it 'should escape HTML entities in the quote body' do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:quote] == 'xmlrpc = &lt;win&gt;&lt;/win&gt;'
    end
    @sender.do_quote(:quote => 'xmlrpc = <win></win>', :source => 'vinbarnes')
  end
  
  it "should set the quote source to the provided source" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:source] == 'ymendel'
    end
    @sender.do_quote(:quote => 'sibboleth, yo!', :source => 'ymendel')
  end
  
  it "should make the quote source a link if a URL is provided" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:source] == '<a href="http://www.link.net/">ymendel</a>'
    end
    @sender.do_quote(:quote => 'sibboleth, yo!', :source => 'ymendel', :url => 'http://www.link.net/')
  end
  
  it "should handle empty arguments" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:source] == "" and args[:quote] == ''
    end
    @sender.do_quote()
  end
  
  it "should process the result to get a standard response" do
    Net::HTTP.stubs(:post_form).returns('fake response')
    @sender.expects(:handle_response).returns("fake response")
    @sender.do_quote(:quote => 'sibboleth, yo!', :source => 'ymendel').should == 'fake response'
  end
end

describe BotSender::Tumblr, "when posting a text item" do
  before(:each) do
    setup_for_posting
  end

  it "should authenticate with the email address and password" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:email] == @params[:email] and args[:password] == @params[:password]
    end
    @sender.do_text(:title => 'thoughts from the Swedish chef', :body => 'bork bork bork')
  end

  it "should include the group if provided" do
    group = 'elsewards.tumblr.com'
    setup_for_posting(:group => group)
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:group] == group
    end
    @sender.do_text(:title => 'thoughts from the Swedish chef', :body => 'bork bork bork')
  end

  it "should make a post to the post url" do
    Net::HTTP.expects(:post_form).with do |url, args|
      url == URI.parse(@params[:post_url])
    end
    @sender.do_text(:title => 'thoughts from the Swedish chef', :body => 'bork bork bork')
  end

  it "should post a text" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:type] == 'regular'
    end
    @sender.do_text(:title => 'thoughts from the Swedish chef', :body => 'bork bork bork')
  end

  it "should set the text title" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:title] == 'thoughts from the Swedish chef'
    end
    @sender.do_text(:title => 'thoughts from the Swedish chef', :body => 'bork bork bork')
  end
  
  it "should set the text body" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:body] == 'bork bork bork'
    end
    @sender.do_text(:title => 'thoughts from the Swedish chef', :body => 'bork bork bork')
  end
  
  it "should handle empty arguments" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:body] == "" and args[:title] == ''
    end
    @sender.do_text()
  end
  
  it "should process the result to get a standard response" do
    Net::HTTP.stubs(:post_form).returns('fake response')
    @sender.expects(:handle_response).returns("fake response")
    @sender.do_text(:title => 'thoughts from the Swedish chef', :body => 'bork bork bork').should == 'fake response'
  end
end

describe BotSender::Tumblr, "when posting a fact" do
  before(:each) do
    setup_for_posting
  end

  it "should authenticate with the email address and password" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:email] == @params[:email] and args[:password] == @params[:password]
    end
    @sender.do_fact(:title => 'FACT:  cardioid is a turd nugget', :body => 'word')
  end

  it "should include the group if provided" do
    group = 'elsewards.tumblr.com'
    setup_for_posting(:group => group)
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:group] == group
    end
    @sender.do_fact(:title => 'FACT:  cardioid is a turd nugget', :body => 'word')
  end

  it "should make a post to the post url" do
    Net::HTTP.expects(:post_form).with do |url, args|
      url == URI.parse(@params[:post_url])
    end
    @sender.do_fact(:title => 'FACT:  cardioid is a turd nugget', :body => 'word')
  end

  it "should post a text item" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:type] == 'regular'
    end
    @sender.do_fact(:title => 'FACT:  cardioid is a turd nugget', :body => 'word')
  end

  it "should set the title" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:title] == 'FACT:  cardioid is a turd nugget'
    end
    @sender.do_fact(:title => 'FACT:  cardioid is a turd nugget', :body => 'word')
  end
  
  it "should set the body" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:body] == 'word'
    end
    @sender.do_fact(:title => 'FACT:  cardioid is a turd nugget', :body => 'word')
  end
  
  it "should handle empty arguments" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:body] == "" and args[:title] == ''
    end
    @sender.do_fact()
  end
  
  it "should process the result to get a standard response" do
    Net::HTTP.stubs(:post_form).returns('fake response')
    @sender.expects(:handle_response).returns("fake response")
    @sender.do_fact(:title => 'FACT:  cardioid is a turd nugget', :body => 'word')
  end
end

describe BotSender::Tumblr, "when posting a true/false post" do
  before(:each) do
    setup_for_posting
  end

  it "should authenticate with the email address and password" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:email] == @params[:email] and args[:password] == @params[:password]
    end
    @sender.do_true_or_false(:title => 'T or F: cardioid is still a turd nugget', :body => 'word')
  end

  it "should include the group if provided" do
    group = 'elsewards.tumblr.com'
    setup_for_posting(:group => group)
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:group] == group
    end
    @sender.do_true_or_false(:title => 'T or F: cardioid is still a turd nugget', :body => 'word')
  end

  it "should make a post to the post url" do
    Net::HTTP.expects(:post_form).with do |url, args|
      url == URI.parse(@params[:post_url])
    end
    @sender.do_true_or_false(:title => 'T or F: cardioid is still a turd nugget', :body => 'word')
  end

  it "should post a text item" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:type] == 'regular'
    end
    @sender.do_true_or_false(:title => 'T or F: cardioid is still a turd nugget', :body => 'word')
  end

  it "should set the fact title" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:title] == 'T or F: cardioid is still a turd nugget'
    end
    @sender.do_true_or_false(:title => 'T or F: cardioid is still a turd nugget', :body => 'word')
  end
  
  it "should set the body" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:body] == 'word'
    end
    @sender.do_true_or_false(:title => 'T or F: cardioid is still a turd nugget', :body => 'word')
  end
  
  it "should handle empty arguments" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:body] == "" and args[:title] == ''
    end
    @sender.do_true_or_false()
  end
  
  it "should process the result to get a standard response" do
    Net::HTTP.stubs(:post_form).returns('fake response')
    @sender.expects(:handle_response).returns("fake response")
    @sender.do_true_or_false(:title => 'T or F: cardioid is still a turd nugget', :body => 'word')
  end
end

describe BotSender::Tumblr, "when posting a definition post" do
  before(:each) do
    setup_for_posting
  end

  it "should authenticate with the email address and password" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:email] == @params[:email] and args[:password] == @params[:password]
    end
    @sender.do_definition(:title => 'Definition: tardulism: the ideology of the tard culture', :body => 'word')
  end

  it "should include the group if provided" do
    group = 'elsewards.tumblr.com'
    setup_for_posting(:group => group)
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:group] == group
    end
    @sender.do_definition(:title => 'Definition: tardulism: the ideology of the tard culture', :body => 'word')
  end

  it "should make a post to the post url" do
    Net::HTTP.expects(:post_form).with do |url, args|
      url == URI.parse(@params[:post_url])
    end
    @sender.do_definition(:title => 'Definition: tardulism: the ideology of the tard culture', :body => 'word')
  end

  it "should post a text item" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:type] == 'regular'
    end
    @sender.do_definition(:title => 'Definition: tardulism: the ideology of the tard culture', :body => 'word')
  end

  it "should set the title" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:title] == 'Definition: tardulism: the ideology of the tard culture'
    end
    @sender.do_definition(:title => 'Definition: tardulism: the ideology of the tard culture', :body => 'word')
  end
  
  it "should set the body" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:body] == 'word'
    end
    @sender.do_definition(:title => 'Definition: tardulism: the ideology of the tard culture', :body => 'word')
  end
  
  it "should handle empty arguments" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:title] == '' and args[:body] == ''
    end
    @sender.do_definition()
  end
  
  it "should process the result to get a standard response" do
    Net::HTTP.stubs(:post_form).returns('fake response')
    @sender.expects(:handle_response).returns("fake response")
    @sender.do_definition(:title => 'Definition: tardulism: the ideology of the tard culture', :body => 'word')
  end
end

describe BotSender::Tumblr, "when posting a chat message" do
  before(:each) do
    setup_for_posting
  end
  
  it "should authenticate with the email address and password" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:email] == @params[:email] and args[:password] == @params[:password]
    end
    @sender.do_chat(:title => 'your mom called', :body => "me: whatup?\nyou: shizzle.")
  end

  it "should include the group if provided" do
    group = 'elsewards.tumblr.com'
    setup_for_posting(:group => group)
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:group] == group
    end
    @sender.do_chat(:title => 'your mom called', :body => "me: whatup?\nyou: shizzle.")
  end

  it "should make a post to the post url" do
    Net::HTTP.expects(:post_form).with do |url, args|
      url == URI.parse(@params[:post_url])
    end
    @sender.do_chat(:title => 'your mom called', :body => "me: whatup?\nyou: shizzle.")
  end

  it "should post a chat" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:type] == 'conversation'
    end
    @sender.do_chat(:title => 'your mom called', :body => "me: whatup?\nyou: shizzle.")
  end

  it "should set the chat title" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:title] == 'your mom called'
    end
    @sender.do_chat(:title => 'your mom called', :body => "me: whatup?\nyou: shizzle.")
  end
  
  it "should set the chat body" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:conversation] == "me: whatup?\nyou: shizzle."
    end
    @sender.do_chat(:title => 'your mom called', :body => "me: whatup?\nyou: shizzle.")
  end
  
  it "should handle empty arguments" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:conversation] == "" and args[:title] == ''
    end
    @sender.do_chat()
  end
  
  it "should process the result to get a standard response" do
    Net::HTTP.stubs(:post_form).returns('fake response')
    @sender.expects(:handle_response).returns("fake response")
    @sender.do_chat(:title => 'your mom called', :body => "me: whatup?\nyou: shizzle.").should == 'fake response'
  end
end  

describe BotSender::Tumblr, "when posting an image message" do
  before(:each) do
    setup_for_posting
  end
  
  it "should authenticate with the email address and password" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:email] == @params[:email] and args[:password] == @params[:password]
    end
    @sender.do_image(:source => 'http://www.upscaleaudio.com/rare/rickjames.jpg', :caption => "I'm Rick James, b*tch!")
  end

  it "should include the group if provided" do
    group = 'elsewards.tumblr.com'
    setup_for_posting(:group => group)
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:group] == group
    end
    @sender.do_image(:source => 'http://www.upscaleaudio.com/rare/rickjames.jpg', :caption => "I'm Rick James, b*tch!")
  end

  it "should make a post to the post url" do
    Net::HTTP.expects(:post_form).with do |url, args|
      url == URI.parse(@params[:post_url])
    end
    @sender.do_image(:source => 'http://www.upscaleaudio.com/rare/rickjames.jpg', :caption => "I'm Rick James, b*tch!")
  end

  it "should post an image" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:type] == 'photo'
    end
    @sender.do_image(:source => 'http://www.upscaleaudio.com/rare/rickjames.jpg', :caption => "I'm Rick James, b*tch!")
  end
  
  it "should set the image source url" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:source] == 'http://www.upscaleaudio.com/rare/rickjames.jpg'
    end
    @sender.do_image(:source => 'http://www.upscaleaudio.com/rare/rickjames.jpg', :caption => "I'm Rick James, b*tch!")
  end

  it "should set the image caption" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:caption] =~ Regexp.new(Regexp.quote("I'm Rick James, b*tch!"))
    end
    @sender.do_image(:source => 'http://www.upscaleaudio.com/rare/rickjames.jpg', :caption => "I'm Rick James, b*tch!")
  end
  
  it "should include a 'zoom' link to the original image" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:caption] =~ Regexp.new(Regexp.quote(%Q[<a href="http://www.upscaleaudio.com/rare/rickjames.jpg">zoom</a>]))
    end
    @sender.do_image(:source => 'http://www.upscaleaudio.com/rare/rickjames.jpg', :caption => "I'm Rick James, b*tch!")
  end
  
  it "should handle empty arguments" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:source] == "" and args[:caption] == ''
    end
    @sender.do_image()
  end
  
  it "should process the result to get a standard response" do
    Net::HTTP.stubs(:post_form).returns('fake response')
    @sender.expects(:handle_response).returns("fake response")
    @sender.do_image(:source => 'http://www.upscaleaudio.com/rare/rickjames.jpg', :caption => "I'm Rick James, b*tch!").should == 'fake response'
  end
end

describe BotSender::Tumblr, "when posting a video message" do
  before(:each) do
    setup_for_posting
  end
  
  it "should authenticate with the email address and password" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:email] == @params[:email] and args[:password] == @params[:password]
    end
    @sender.do_video(:embed => 'http://www.youtube.com/watch?v=Rd8OGmZtAws', :caption => "yoyoyo!")
  end

  it "should include the group if provided" do
    group = 'elsewards.tumblr.com'
    setup_for_posting(:group => group)
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:group] == group
    end
    @sender.do_video(:embed => 'http://www.youtube.com/watch?v=Rd8OGmZtAws', :caption => "yoyoyo!")
  end

  it "should make a post to the post url" do
    Net::HTTP.expects(:post_form).with do |url, args|
      url == URI.parse(@params[:post_url])
    end
    @sender.do_video(:embed => 'http://www.youtube.com/watch?v=Rd8OGmZtAws', :caption => "yoyoyo!")
  end

  it "should post a video" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:type] == 'video'
    end
    @sender.do_video(:embed => 'http://www.youtube.com/watch?v=Rd8OGmZtAws', :caption => "yoyoyo!")
  end
  
  it "should set the video source url" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:embed] == 'http://www.youtube.com/watch?v=Rd8OGmZtAws'
    end
    @sender.do_video(:embed => 'http://www.youtube.com/watch?v=Rd8OGmZtAws', :caption => "yoyoyo!")
  end  

  it "should set the video caption" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:caption] == 'yoyoyo!'
    end
    @sender.do_video(:embed => 'http://www.youtube.com/watch?v=Rd8OGmZtAws', :caption => "yoyoyo!")
  end
  
  it "should handle empty arguments" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:embed] == "" and args[:caption] == ''
    end
    @sender.do_video()
  end
  
  it "should process the result to get a standard response" do
    Net::HTTP.stubs(:post_form).returns('fake response')
    @sender.expects(:handle_response).returns("fake response")
    @sender.do_video(:embed => 'http://www.youtube.com/watch?v=Rd8OGmZtAws', :caption => "yoyoyo!").should == 'fake response'
  end
end

describe BotSender::Tumblr, "when posting a link message" do
  before(:each) do
    setup_for_posting
  end
  
  it "should authenticate with the email address and password" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:email] == @params[:email] and args[:password] == @params[:password]
    end
    @sender.do_link(:url => 'http://www.thewvsr.com/alli.htm', 
                    :name => "Alli Side Effects In Layman's Terms", 
                    :description => 'by Jeff Kay')
  end

  it "should include the group if provided" do
    group = 'elsewards.tumblr.com'
    setup_for_posting(:group => group)
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:group] == group
    end
    @sender.do_link(:url => 'http://www.thewvsr.com/alli.htm', 
                    :name => "Alli Side Effects In Layman's Terms", 
                    :description => 'by Jeff Kay')
  end

  it "should make a post to the post url" do
    Net::HTTP.expects(:post_form).with do |url, args|
      url == URI.parse(@params[:post_url])
    end
    @sender.do_link(:url => 'http://www.thewvsr.com/alli.htm', 
                    :name => "Alli Side Effects In Layman's Terms", 
                    :description => 'by Jeff Kay')
  end

  it "should post a link" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:type] == 'link'
    end
    @sender.do_link(:url => 'http://www.thewvsr.com/alli.htm', 
                    :name => "Alli Side Effects In Layman's Terms", 
                    :description => 'by Jeff Kay')
  end
  
  it "should set the link url" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:url] == 'http://www.thewvsr.com/alli.htm'
    end
    @sender.do_link(:url => 'http://www.thewvsr.com/alli.htm', 
                    :name => "Alli Side Effects In Layman's Terms", 
                    :description => 'by Jeff Kay')
  end  

  it "should set the link name" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:name] == "Alli Side Effects In Layman's Terms"
    end
    @sender.do_link(:url => 'http://www.thewvsr.com/alli.htm', 
                    :name => "Alli Side Effects In Layman's Terms", 
                    :description => 'by Jeff Kay')
  end

  it "should set the link description" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:name] == "Alli Side Effects In Layman's Terms"
    end
    @sender.do_link(:url => 'http://www.thewvsr.com/alli.htm', 
                    :name => "Alli Side Effects In Layman's Terms", 
                    :description => 'by Jeff Kay')
  end
  
  it "should handle empty arguments" do
    Net::HTTP.expects(:post_form).with do |url, args|
      args[:name] == "" and args[:url] == '' and args[:description] == ''
    end
    @sender.do_link()
  end
  
  it "should process the result to get a standard response" do
    Net::HTTP.stubs(:post_form).returns('fake response')
    @sender.expects(:handle_response).returns("fake response")
    @sender.do_link(:url => 'http://www.thewvsr.com/alli.htm', 
                    :name => "Alli Side Effects In Layman's Terms", 
                    :description => 'by Jeff Kay').should == 'fake response'
  end
end

# note: we don't currently support file uploads to tumblr, so we aren't supporting Audio posts

