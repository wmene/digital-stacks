require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class Trans
  attr_accessor :iiif_params, :request # To simulate #params and #request from Sinatra::Base
  
  include IiifTranslator
end

describe IiifTranslator do
  before(:each) do
    @t = Trans.new
    @t.request = stub('stub_request')
  end
  
  describe "#trans_region" do
    
    it "translates 'full' into nil and appends '_full' to id" do
      @t.iiif_params = {:region => 'full', :id => 'druid:abc/image1'}
      @t.trans_region.should == {}
      @t.iiif_params[:id].should == 'druid:abc/image1_full'
    end
    
    it "translate pct: into absolute pixel dimensions" do
      pending # have to do a djatoka metadata lookup first
    end
    
    it "passes x,y,w,h as received" do
      @t.iiif_params = {:region => '25,332,523,235'}
      @t.trans_region.should == {:region =>'25,332,523,235'}
    end
    
    it "returns throws an exception if region does not match any valid API string" do
      pending
    end
  end
  
  describe "#trans_size" do
    
    it "translates 'full' into nil" do
      @t.iiif_params = {:size => 'full'}
      @t.trans_size.should == {}
    end
    
    it "translates 'w,' into a hash with :w " do
      @t.iiif_params = {:size => '400,'}
      @t.trans_size.should == {:w => '400'}
    end
    
    it "translates ',h' into a hash with :h " do
      @t.iiif_params = {:size => ',500'}
      @t.trans_size.should == {:h => '500'}
    end
    
    it "translates 'pct:n into a scaling of the extracted region" do
      pending
      # @t.iiif_params = {:size => 'pct:36'}
      # @t.trans_size.should == {:zoom => '36'}
    end
    
    it "translates 'w,h' into a hash with :w and :h" do
      @t.iiif_params = {:size => '800,600'}
      @t.trans_size.should == {:w => '800', :h => '600'}
    end
    
    it "translates '!w,h' into a best fit scaling" do
      pending # not provided by djatoka
    end  
  end
  
  describe "#trans_rotate" do
    it "passes value of :rotate as a hash with :rotate" do
      @t.iiif_params = {:rotate => '90'}
      @t.trans_rotate.should == {:rotate => '90'}
    end
    
    it "passes a value of 0 as nil" do
      @t.iiif_params = {:rotate => '0'}
      @t.trans_rotate.should == {}
    end
  end
  
  describe "#parse_request" do
    it "parses the raw path into the @iiif_params hash" do
      @t.stub_chain(:request, :path).and_return("/image/iiif/druid%3Aaa12bb1234%2Ffileabc/5,3,10,100/full/90/native.jpg")
      @t.parse_request
      @t.iiif_params[:id].should == 'druid:aa12bb1234/fileabc'
      @t.iiif_params[:region].should == '5,3,10,100'
      @t.iiif_params[:size].should == 'full'
      @t.iiif_params[:rotate].should == '90'
      @t.iiif_params[:quality].should == 'native'
      @t.iiif_params[:format].should == 'jpg'
    end
    
    it "parses an iiif request without format" do
      @t.stub_chain(:request,:path).and_return("/image/iiif/druid%3Aaa12bb1234%2Ffileabc/5,3,10,100/full/90/native")
      @t.parse_request
      @t.iiif_params[:quality].should == 'native'
      @t.iiif_params[:format].should be_nil
    end
    
    it "parses an iiif information request" do
      @t.stub_chain(:request,:path).and_return("/image/iiif/druid%3Aaa12bb1234%2Ffileabc/info.json")
      @t.parse_request
      @t.iiif_params[:info].should be_true
      @t.iiif_params[:format].should == 'json'
    end
  end
  
  describe "#translate" do
    it "translates the iiif params from the request into PATH_INFO and QUERY_STRING values for re-routing to old API " do
      @t.stub_chain(:request,:path).and_return("/image/iiif/druid%3Aaa12bb1234%2Ffileabc/5,3,10,100/1000,/90/native.jpg")
      new_image_id, new_query = @t.translate
      new_image_id.should == 'druid:aa12bb1234/fileabc.jpg'
      new_query.should == 'region=5,3,10,100&rotate=90&w=1000'
    end
    
    it "builds query string correctly when translated params are nil" do
      @t.stub_chain(:request,:path).and_return("/image/iiif/druid%3Aaa12bb1234%2Ffileabc/full/1000,/90/native.jpg")
      new_image_id, new_query = @t.translate
      new_query.should == 'rotate=90&w=1000'
    end
    
    it "builds image ids without format" do
      @t.stub_chain(:request,:path).and_return("/image/iiif/aa12bb1234%2Ffileabc/full/1000,/90/native")
      new_image_id, new_query = @t.translate
      new_image_id.should == 'aa12bb1234/fileabc_full'
    end
    
    it "builds image ids with full and format" do
      @t.stub_chain(:request,:path).and_return("/image/iiif/aa12bb1234%2Ffileabc/full/1000,/90/native.png")
      new_image_id, new_query = @t.translate
      new_image_id.should == 'aa12bb1234/fileabc_full.png'
    end
    
    it "builds an available sizes/format request" do
      @t.stub_chain(:request,:path).and_return("/image/iiif/aa12bb1234%2Ffileabc/info.xml")
      new_image_id, new_query = @t.translate
      new_image_id.should == 'aa12bb1234/fileabc.xml'
      new_query.should == ''
    end
  end
  
  
end