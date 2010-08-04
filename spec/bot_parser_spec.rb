require File.expand_path(File.join(File.dirname(__FILE__), *%w[spec_helper]))
require 'bot_parser'
require 'bot_filter'

describe BotParser do
  before(:each) do
    @parser = BotParser.new
  end
  
  it "should return nothing on an empty message" do
    @parser.parse('rick', 't3hchannel', '').should be_nil
  end
  
  it "should recognize a quote with a body and a source" do
    result = @parser.parse('rick', 't3hchannel', '"adios, turd nuggets" --J.P.')
    result[:type].should == :quote
    result[:quote].should == 'adios, turd nuggets'
    result[:source].should match(/J.P./)
  end
  
  it "should recognize a quote with a body and a source and a link" do
    result = @parser.parse('rick', 't3hchannel', '"adios, turd nuggets" --J.P. (http://imdb.com/title/tt0456554/)')
    result[:type].should == :quote
    result[:quote].should == 'adios, turd nuggets'
    result[:url].should == 'http://imdb.com/title/tt0456554/'
    result[:source].should match(/J.P./)    
  end
  
  it "should make poster and channel available in the results when matching a quote" do
    result = @parser.parse('rick', 't3hchannel', '"adios, turd nuggets" --J.P. (http://imdb.com/title/tt0456554/)')
    result[:poster].should == 'rick'
    result[:channel].should == 't3hchannel'
  end
    
  it "should recognize a JPEG image link" do
    result = @parser.parse('rick', 't3hchannel', 'http://citizenx.cx/img/tn/best_picture_ever.jpg')
    result[:type].should == :image
    result[:source].should == 'http://citizenx.cx/img/tn/best_picture_ever.jpg'
  end
  
  it "should recognize a PNG image link" do
    result = @parser.parse('rick', 't3hchannel', 'http://www.rickbradley.com/images/ricks_30th.png')
    result[:type].should == :image
    result[:source].should == 'http://www.rickbradley.com/images/ricks_30th.png'
  end
  
  it "should recognize a GIF image link" do
    result = @parser.parse('rick', 't3hchannel', 'http://citizenx.cx/img/tn/best_picture_ever_animated.gif')
    result[:type].should == :image    
    result[:source].should == 'http://citizenx.cx/img/tn/best_picture_ever_animated.gif'
  end
  
  it "should recognize an image link with a caption" do
    result = @parser.parse('rick', 't3hchannel', 'http://citizenx.cx/img/tn/best_picture_never.jpg Best Picture Never')
    result[:type].should == :image
    result[:source].should == 'http://citizenx.cx/img/tn/best_picture_never.jpg'
    result[:caption].should match(/Best Picture Never/)
  end
  
  it 'should recognize an image link with a title' do
    result = @parser.parse('rick', 't3hchannel', 'Picture of the day http://citizenx.cx/img/tn/best_picture_never.jpg')
    result[:type].should == :image
    result[:source].should == 'http://citizenx.cx/img/tn/best_picture_never.jpg'
    result[:title].should == 'Picture of the day'
  end
  
  it 'should recognize an image link with a title and caption' do
    result = @parser.parse('rick', 't3hchannel', 'Picture of the day http://citizenx.cx/img/tn/best_picture_never.jpg Best Picture Never')
    result[:type].should == :image
    result[:source].should == 'http://citizenx.cx/img/tn/best_picture_never.jpg'
    result[:title].should == 'Picture of the day'
    result[:caption].should match(/Best Picture Never/)
  end
  
  it "should make poster and channel available in the results when matching an image" do
    result = @parser.parse('rick', 't3hchannel', 'http://photos-b.ak.facebook.com/photos-ak-sctm/v122/61/43/625045653/n625045653_1275457_7998.jpg')
    result[:poster].should == 'rick'
    result[:channel].should == 't3hchannel'
  end
  
  it "should recognize a link post" do
    result = @parser.parse('rick', 't3hchannel', 'http://www.rickbradley.com/misc/communist_bloc(k)_party.html')
    result[:type].should == :link
    result[:url].should == 'http://www.rickbradley.com/misc/communist_bloc(k)_party.html'
    result[:name].should be_nil
  end

  it "should recognize an ignore link post" do
    @parser.parse('rick', 't3hchannel', '!http://www.rickbradley.com').should be_nil
  end

  it "should recognize an ignore link post with a title" do
    @parser.parse('rick', 't3hchannel', 'The best site eva! !http://www.rickbradley.com').should be_nil
  end

  it "should recognize an ignore link post with a description" do
    @parser.parse('rick', 't3hchannel', '!http://www.rickbradley.com The best site eva!').should be_nil
  end

  it "should recognize an ignore link post with a name and a description" do
    @parser.parse('rick', 't3hchannel', 'The best !http://www.rickbradley.com site eva!').should be_nil
  end
  
  it "should recognize a link with a name" do
    result = @parser.parse('rick', 't3hchannel', 'In Communist Russia, rocking you like hurricane http://www.rickbradley.com/misc/communist_bloc(k)_party.html')
    result[:type].should == :link
    result[:url].should == 'http://www.rickbradley.com/misc/communist_bloc(k)_party.html'
    result[:name].should == 'In Communist Russia, rocking you like hurricane'
  end
  
  it "should recognize a link post with descriptive text" do
    result = @parser.parse('rick', 't3hchannel', 'http://www.rickbradley.com/misc/communist_bloc(k)_party.html ROCKING!')
    result[:type].should == :link
    result[:url].should == 'http://www.rickbradley.com/misc/communist_bloc(k)_party.html'
    result[:name].should be_nil
    result[:description].should match(/ROCKING!/)    
  end
  
  it "should recognize a link post with both a name and a descriptive text" do
    result = @parser.parse('rick', 't3hchannel', 'Please Rocking! http://www.rickbradley.com/misc/communist_bloc(k)_party.html ROCKING!')
    result[:type].should == :link
    result[:url].should == 'http://www.rickbradley.com/misc/communist_bloc(k)_party.html'
    result[:name].should == 'Please Rocking!'
    result[:description].should match(/ROCKING!/)        
  end
  
  it "should make poster and channel available in the results when matching a link" do
    result = @parser.parse('rick', 't3hchannel', 'Please Rocking! http://www.rickbradley.com/misc/communist_bloc(k)_party.html ROCKING!')
    result[:poster].should == 'rick'
    result[:channel].should == 't3hchannel'
  end
  
  it "should recognize a video link" do
    result = @parser.parse('rick', 't3hchannel', 'http://youtube.com/watch?v=uwEXywdSpNQ')
    result[:type].should == :video
    result[:embed].should == 'http://youtube.com/watch?v=uwEXywdSpNQ'
  end
  
  it "should recognize a video link with a description" do
    result = @parser.parse('rick', 't3hchannel', 'http://youtube.com/watch?v=uwEXywdSpNQ  Robot Chicken')
    result[:type].should == :video
    result[:embed].should == 'http://youtube.com/watch?v=uwEXywdSpNQ' 
    result[:caption].should match(/Robot Chicken/)
  end
  
  it 'should recognize a video link with a title' do
    result = @parser.parse('rick', 't3hchannel', 'Video of the day http://youtube.com/watch?v=uwEXywdSpNQ')
    result[:type].should == :video
    result[:embed].should == 'http://youtube.com/watch?v=uwEXywdSpNQ'
    result[:title].should == 'Video of the day'
  end
  
  it 'should recognize a video link with a title and description' do
    result = @parser.parse('rick', 't3hchannel', 'Video of the day http://youtube.com/watch?v=uwEXywdSpNQ Robot Chicken')
    result[:type].should == :video
    result[:embed].should == 'http://youtube.com/watch?v=uwEXywdSpNQ'
    result[:title].should == 'Video of the day'
    result[:caption].should match(/Robot Chicken/)
  end
  
  it "should recognize a video link under www.youtube.com" do
    result = @parser.parse('rick', 't3hchannel', 'http://www.youtube.com/watch?v=uwEXywdSpNQ')
    result[:type].should == :video
    result[:embed].should == 'http://www.youtube.com/watch?v=uwEXywdSpNQ'
  end
  
  it "should recognize a video link under a different-language subdomain (like il.youtube.com)" do
    result = @parser.parse('rick', 't3hchannel', 'http://il.youtube.com/watch?v=4N1M7Kwl81A')
    result[:type].should == :video
    result[:embed].should == 'http://il.youtube.com/watch?v=4N1M7Kwl81A'
  end
  
  it "should recognize a video link under a country code domain (like www.youtube.co.uk)" do
    result = @parser.parse('rick', 't3hchannel', 'http://www.youtube.co.uk/watch?v=IrV1rC8qr44')
    result[:type].should == :video
    result[:embed].should == 'http://www.youtube.co.uk/watch?v=IrV1rC8qr44'
  end
  
  it "should make poster and channel available in the results when matching a video link" do
    result = @parser.parse('rick', 't3hchannel', 'http://youtube.com/watch?v=uwEXywdSpNQ  Robot Chicken')
    result[:poster].should == 'rick'
    result[:channel].should == 't3hchannel'
  end

  it "should recognize a fact post" do
    result = @parser.parse('rick', 't3hchannel', "fact: zed shaw doesn't do pushups, he pushes the earth down")
    result[:type].should == :fact
    result[:title].should == "FACT: zed shaw doesn't do pushups, he pushes the earth down"
  end

  it "should recognize a 'T or F' post" do
    result = @parser.parse('rick', 't3hchannel', "T or F: the human body has more than one sphincter")
    result[:type].should == :true_or_false
    result[:title].should == "True or False?  the human body has more than one sphincter"
  end
  
  it "should recognize a true/false post when spelled out" do
    result = @parser.parse('rick', 't3hchannel', "true or false: the human body has more than one sphincter")
    result[:type].should == :true_or_false
    result[:title].should == "True or False?  the human body has more than one sphincter"    
  end
  
  it "should recognize a true/false post with '?' or ':' as a separator" do
    result = @parser.parse('rick', 't3hchannel', "true or false? the human body has more than one sphincter")
    result[:type].should == :true_or_false
    result[:title].should == "True or False?  the human body has more than one sphincter"        
  end
  
  it "should recognize a definition post" do
    result = @parser.parse('rick', 't3hchannel', "definition: tardulism: the ideology of the tard culture")
    result[:type].should == :definition
    result[:title].should == "DEFINITION: tardulism: the ideology of the tard culture"
  end
  
  it "should recognize a definition post with ':' or '=' as a separator" do
    result = @parser.parse('rick', 't3hchannel', "definition: tardulism = the ideology of the tard culture")
    result[:type].should == :definition
    result[:title].should == "DEFINITION: tardulism: the ideology of the tard culture"
  end
  
  it "should recognize a definition post with natural text" do
    result = @parser.parse('rick', 't3hchannel', "define tardulism as the ideology of the tard culture")
    result[:type].should == :definition
    result[:title].should == "DEFINITION: tardulism: the ideology of the tard culture"
  end
  
  it "should return nothing for an unrecognized message" do
    @parser.parse('rick', 't3hchannel', "This is some wack shizzle, m'nizzle.").should be_nil
  end
end

describe BotParser, 'when registering formats' do
  before :each do
    BotParser.clear_formats
  end
  
  it 'should require a format name' do
    lambda { BotParser.register_format }.should raise_error(ArgumentError)
  end
  
  it 'should require a format' do
    lambda { BotParser.register_format(:format_name) }.should raise_error(ArgumentError)
  end
  
  it 'should require a block' do
    lambda { BotParser.register_format(:format_name, /format/) }.should raise_error(ArgumentError)
  end
  
  it 'should accept a format name, format, and block' do
    lambda { BotParser.register_format(:format_name, /format/) {} }.should_not raise_error(ArgumentError)
  end
  
  it 'should accept a format name, format, description, and block' do
    lambda { BotParser.register_format(:format_name, /format/, 'description') {} }.should_not raise_error(ArgumentError)
  end
  
  it 'should provide access to formats' do
    BotParser.should respond_to(:formats)
  end
  
  it 'should provide a way to clear formats' do
    BotParser.register_format(:format_name, /format/) {}
    BotParser.formats.should_not be_empty
    BotParser.clear_formats
    BotParser.formats.should be_empty
  end
  
  it 'should store given format' do
    block = lambda {}
    BotParser.register_format(:format_name, /format/, 'description', &block)
    format = BotParser.formats.detect { |f|  f.name == :format_name and f.format == /format/ and f.description == 'description' and f.block == block }
    format.should_not be_nil
  end
end
