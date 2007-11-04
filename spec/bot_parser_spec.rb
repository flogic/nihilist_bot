require File.dirname(__FILE__) + '/spec_helper'
require 'bot_parser'

describe BotParser do
  before(:each) do
    @parser = BotParser.new
  end
  
  should "return nothing on an empty message" do
    @parser.parse('rick', 't3hchannel', '').should be_nil
  end
  
  should "recognize a quote with a body and a source" do
    result = @parser.parse('rick', 't3hchannel', '"adios, turd nuggets" --J.P.')
    result[:type].should == 'quote'
    result[:quote].should == 'adios, turd nuggets'
    result[:source].should match(/J.P./)
  end
  
  should "recognize a quote with a body and a source and a link" do
    result = @parser.parse('rick', 't3hchannel', '"adios, turd nuggets" --J.P. (http://imdb.com/title/tt0456554/)')
    result[:type].should == 'quote'
    result[:quote].should == 'adios, turd nuggets'
    result[:url].should == 'http://imdb.com/title/tt0456554/'
    result[:source].should match(/J.P./)    
  end
  
  should "make poster and channel available in the results when matching a quote" do
    result = @parser.parse('rick', 't3hchannel', '"adios, turd nuggets" --J.P. (http://imdb.com/title/tt0456554/)')
    result[:poster].should == 'rick'
    result[:channel].should == 't3hchannel'
  end
  
  should "put quote poster into quote caption" do
    result = @parser.parse('rick', 't3hchannel', '"I\'m a little teapot." --J.P.')
    result[:source].should match(/posted by rick/)        

    result = @parser.parse('rick', 't3hchannel', '"adios, turd nuggets" --J.P. (http://imdb.com/title/tt0456554/)')
    result[:source].should match(/posted by rick/)        
  end
  
  should "recognize a JPEG image link" do
    result = @parser.parse('rick', 't3hchannel', 'http://citizenx.cx/img/tn/best_picture_ever.jpg')
    result[:type].should == 'image'
    result[:source].should == 'http://citizenx.cx/img/tn/best_picture_ever.jpg'
  end
  
  should "recognize a PNG image link" do
    result = @parser.parse('rick', 't3hchannel', 'http://www.rickbradley.com/images/ricks_30th.png')
    result[:type].should == 'image'
    result[:source].should == 'http://www.rickbradley.com/images/ricks_30th.png'
  end
  
  should "recognize a GIF image link" do
    result = @parser.parse('rick', 't3hchannel', 'http://citizenx.cx/img/tn/best_picture_ever_animated.gif')
    result[:type].should == 'image'    
    result[:source].should == 'http://citizenx.cx/img/tn/best_picture_ever_animated.gif'
  end
  
  should "recognize an image link with a caption" do
    result = @parser.parse('rick', 't3hchannel', 'http://citizenx.cx/img/tn/best_picture_never.jpg Best Picture Never')
    result[:type].should == 'image'
    result[:source].should == 'http://citizenx.cx/img/tn/best_picture_never.jpg'
    result[:caption].should match(/Best Picture Never/)
  end
  
  should "put image link poster into image caption" do
    result = @parser.parse('rick', 't3hchannel', 'http://photos-b.ak.facebook.com/photos-ak-sctm/v122/61/43/625045653/n625045653_1275457_7998.jpg')
    result[:caption].should match(/posted by rick/)

    result = @parser.parse('rick', 't3hchannel', 'http://photos-b.ak.facebook.com/photos-ak-sctm/v122/61/43/625045653/n625045653_1275457_7998.jpg  BOING!!!')
    result[:caption].should match(/posted by rick/)
  end
  
  should "make poster and channel available in the results when matching an image" do
    result = @parser.parse('rick', 't3hchannel', 'http://photos-b.ak.facebook.com/photos-ak-sctm/v122/61/43/625045653/n625045653_1275457_7998.jpg')
    result[:poster].should == 'rick'
    result[:channel].should == 't3hchannel'
  end
  
  should "recognize a link post" do
    result = @parser.parse('rick', 't3hchannel', 'http://www.rickbradley.com/misc/communist_bloc(k)_party.html')
    result[:type].should == 'link'
    result[:url].should == 'http://www.rickbradley.com/misc/communist_bloc(k)_party.html'
    result[:name].should == ''
  end
  
  should "recognize a link with a name" do
    result = @parser.parse('rick', 't3hchannel', 'In Communist Russia, rocking you like hurricane http://www.rickbradley.com/misc/communist_bloc(k)_party.html')
    result[:type].should == 'link'
    result[:url].should == 'http://www.rickbradley.com/misc/communist_bloc(k)_party.html'
    result[:name].should == 'In Communist Russia, rocking you like hurricane'
  end
  
  should "recognize a link post with descriptive text" do
    result = @parser.parse('rick', 't3hchannel', 'http://www.rickbradley.com/misc/communist_bloc(k)_party.html ROCKING!')
    result[:type].should == 'link'
    result[:url].should == 'http://www.rickbradley.com/misc/communist_bloc(k)_party.html'
    result[:name].should == ''
    result[:description].should match(/ROCKING!/)    
  end
  
  should "recognize a link post with both a name and a descriptive text" do
    result = @parser.parse('rick', 't3hchannel', 'Please Rocking! http://www.rickbradley.com/misc/communist_bloc(k)_party.html ROCKING!')
    result[:type].should == 'link'
    result[:url].should == 'http://www.rickbradley.com/misc/communist_bloc(k)_party.html'
    result[:name].should == 'Please Rocking!'
    result[:description].should match(/ROCKING!/)        
  end
  
  should "put link poster into the link description" do
    result = @parser.parse('rick', 't3hchannel', 'Please Rocking! http://www.rickbradley.com/misc/communist_bloc(k)_party.html ROCKING!')
    result[:type].should == 'link'
    result[:url].should == 'http://www.rickbradley.com/misc/communist_bloc(k)_party.html'
    result[:name].should == 'Please Rocking!'
    result[:description].should match(/posted by rick/)        
  end
  
  should "make poster and channel available in the results when matching a link" do
    result = @parser.parse('rick', 't3hchannel', 'Please Rocking! http://www.rickbradley.com/misc/communist_bloc(k)_party.html ROCKING!')
    result[:poster].should == 'rick'
    result[:channel].should == 't3hchannel'
  end
  
  should "recognize a video link" do
    result = @parser.parse('rick', 't3hchannel', 'http://youtube.com/watch?v=uwEXywdSpNQ')
    result[:type].should == 'video'
    result[:embed].should == 'http://youtube.com/watch?v=uwEXywdSpNQ'
  end
  
  should "recognize a video link with a description" do
    result = @parser.parse('rick', 't3hchannel', 'http://youtube.com/watch?v=uwEXywdSpNQ  Robot Chicken')
    result[:type].should == 'video'
    result[:embed].should == 'http://youtube.com/watch?v=uwEXywdSpNQ' 
    result[:caption].should match(/Robot Chicken/)   
  end
  
  should "put video poster into the description body" do
    result = @parser.parse('rick', 't3hchannel', 'http://youtube.com/watch?v=uwEXywdSpNQ  Robot Chicken')
    result[:caption].should match(/posted by rick/)
  end
  
  should "make poster and channel available in the results when matching a video link" do
    result = @parser.parse('rick', 't3hchannel', 'http://youtube.com/watch?v=uwEXywdSpNQ  Robot Chicken')
    result[:poster].should == 'rick'
    result[:channel].should == 't3hchannel'
  end

  should "recognize a fact post" do
    result = @parser.parse('rick', 't3hchannel', "fact: zed shaw doesn't do pushups, he pushes the earth down")
    result[:type].should == 'fact'
    result[:title].should == "FACT: zed shaw doesn't do pushups, he pushes the earth down"
    result[:body].should match(/posted by rick/)
  end

  should "return nothing for an unrecognized message" do
    @parser.parse('rick', 't3hchannel', "This is some wack shizzle, m'nizzle.").should be_nil
  end
end