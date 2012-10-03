require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ImageServiceRequest do

  context "initialization" do

    before(:each) do
      @params = { :id => 'bb718gz5962', :filename => 'bb718gz5962_10_0001' }
    end

    context "of file formats and mime types" do

      it "defaults to 'jpg' format and 'image/jpeg' mime type if no 'format' parameter is specified" do
        request = ImageServiceRequest.new(@params)
        request.format.should == 'jpg'
        request.mime_type.should == 'image/jpeg'
        request.djatoka_region.query.format.should =~ /image\/jpeg/
      end

      it "defaults to 'jpg' format and 'image/jpeg' mime type if an empty 'format' parameter is specified" do
        @params[:filename] = 'file_without_extension'
        request = ImageServiceRequest.new(@params)
        request.format.should == 'jpg'
        request.mime_type.should == 'image/jpeg'
        request.djatoka_region.query.format.should =~ /image\/jpeg/
      end

      it "throws an exception if an invalid 'format' parameter is specified" do
        pending
        # This no longer applies since filenames can have periods in them
        @params[:filename] = 'some_file.dummy_file_format'
        lambda { ImageServiceRequest.new(@params) }.should raise_error(ArgumentError)
      end
      
      it "handles base filnames with periods in them" do
        @params[:filename] = 'some_file.with_a_period'
        request = ImageServiceRequest.new(@params)
        request.format.should == 'jpg'
        request.mime_type.should == 'image/jpeg'
        request.djatoka_region.query.format.should =~ /image\/jpeg/
      end
      
      it "throws an exception if an invalid parameter is passed in" do
        @params[:illegal_param] = 'causes validation to fail'
        lambda { ImageServiceRequest.new(@params) }.should raise_error(ArgumentError)
      end

      it "initializes the file format and mime type for valid 'format' parameters (jpg, png, gif, tif, bmp)" do
        @params[:filename] = 'bb718gz5962_10_0001.jpg'
        request = ImageServiceRequest.new(@params)
        request.format.should eql('jpg')
        request.mime_type.should eql('image/jpeg')
        request.djatoka_region.query.format.should =~ /image\/jpeg/
        lambda { ImageServiceRequest.new(@params) }.should_not raise_error(ArgumentError)

        @params[:filename] = 'bb718gz5962_10_0001.png'
        request = ImageServiceRequest.new(@params)
        request.format.should eql('png')
        request.mime_type.should eql('image/png')
        request.djatoka_region.query.format.should =~ /image\/png/
        lambda { ImageServiceRequest.new(@params) }.should_not raise_error(ArgumentError)

        @params[:filename] = 'bb718gz5962_10_0001.gif'
        request = ImageServiceRequest.new(@params)
        request.format.should eql('gif')
        request.mime_type.should eql('image/gif')
        request.djatoka_region.query.format.should =~ /image\/gif/
        lambda { ImageServiceRequest.new(@params) }.should_not raise_error(ArgumentError)

        @params[:filename] = 'bb718gz5962_10_0001.tif'
        request = ImageServiceRequest.new(@params)
        request.format.should eql('tif')
        request.mime_type.should eql('image/tiff')
        request.djatoka_region.query.format.should =~ /image\/tiff/
        lambda { ImageServiceRequest.new(@params) }.should_not raise_error(ArgumentError)

        @params[:filename] = 'bb718gz5962_10_0001.bmp'
        request = ImageServiceRequest.new(@params)
        request.format.should eql('bmp')
        request.mime_type.should eql('image/bmp')
        request.djatoka_region.query.format.should =~ /image\/bmp/
        lambda { ImageServiceRequest.new(@params) }.should_not raise_error(ArgumentError)
      end
    end
    
    context "list of available size renderings" do
      it "handles a format of xml" do
        @params[:filename] = 'image.xml'
        request = ImageServiceRequest.new(@params)
        request.format.should eql('xml')
        lambda { ImageServiceRequest.new(@params) }.should_not raise_error(ArgumentError)
      end
      
      it "handles a format of json" do
        @params[:filename] = 'image.json'
        request = ImageServiceRequest.new(@params)
        request.format.should eql('json')
        lambda { ImageServiceRequest.new(@params) }.should_not raise_error(ArgumentError)
      end
      
      describe "#available_sizes?" do
        it "returns true if the image format is xml or json" do
          @params[:filename] = 'image.xml'
          request = ImageServiceRequest.new(@params)
          request.available_sizes?.should be_true
          @params[:filename] = 'image.json'
          request = ImageServiceRequest.new(@params)
          request.available_sizes?.should be_true
        end
      end
    end

    context "initialize size categories" do

      before(:each) do
        DjatokaMetadata.stub!(:find).and_return(stub(:md).as_null_object)
      end

      it "should be initialized with a nil size category if no 'size' parameter is specified" do
        request = ImageServiceRequest.new(@params)
        request.size.should be_nil
      end

      it "should be initialized with a nil size category if an unknown 'size' parameter is specified" do
        @params[:filename] = 'bb718gz5962_10_0001_smallest'
        request = ImageServiceRequest.new(@params)
        request.size.should be_nil
      end

      it "should not throw an exception if the 'size' parameter could not be determined" do
        @params[:filename] = 'bb718gz5962_10_0001_dummy_size'
        lambda { ImageServiceRequest.new(@params) }.should_not raise_error(ArgumentError)
      end

      it "should be initialized with a square size category if a square 'size' parameter is specified" do
        @params[:filename] = 'bb718gz5962_10_0001_square'
        request = ImageServiceRequest.new(@params)
        request.size.should eql('square')
      end

      it "should be initialized with a thumb size category if a thumb 'size' parameter is specified" do
        @params[:filename] = 'bb718gz5962_10_0001_thumb'
        request = ImageServiceRequest.new(@params)
        request.size.should eql('thumb')
      end

      it "should be initialized with a small size category if a small 'size' parameter is specified" do
        @params[:filename] = 'bb718gz5962_10_0001_small'
        request = ImageServiceRequest.new(@params)
        request.size.should eql('small')
      end

      it "should be initialized with a medium size category if a medium 'size' parameter is specified" do
        @params[:filename] = 'bb718gz5962_10_0001_medium'
        request = ImageServiceRequest.new(@params)
        request.size.should eql('medium')
      end

      it "should be initialized with a large size category if a large 'size' parameter is specified" do
        @params[:filename] = 'bb718gz5962_10_0001_large'
        request = ImageServiceRequest.new(@params)
        request.size.should eql('large')
      end

      it "should be initialized with a full size category if a full 'size' parameter is specified" do
        @params[:filename] = 'bb718gz5962_10_0001_full'
        request = ImageServiceRequest.new(@params)
        request.size.should eql('full')
      end

      it "should be initialized with a nil size category if an extra large 'size' parameter is specified" do
        @params[:filename] = 'bb718gz5962_10_0001_xlarge'
        request = ImageServiceRequest.new(@params)
        request.size.should eql('xlarge')
      end

      it "should be initialized with a full size category if a full 'size' parameter is specified" do
        @params[:filename] = 'bb718gz5962_10_0001_full'
        request = ImageServiceRequest.new(@params)
        request.size.should eql('full')
      end

    end
   
    context "file path" do
      it "initializes the stacks file path" do
        request = ImageServiceRequest.new(@params)
        
        request.stacks_file_path.should == 'file://' << DigitalStacks::STACKS_DATA_STORE << '/bb/718/gz/5962/bb718gz5962_10_0001.jp2'
      end
      
      it "handles two periods in the filename" do
        @params[:filename] = '2011-023Cham-1.0_0002'
        req = ImageServiceRequest.new(@params)
        req.get_file_prefix(@params[:filename]).should == '2011-023Cham-1.0_0002'
        req.stacks_file_path.should == 'file://' << DigitalStacks::STACKS_DATA_STORE << '/bb/718/gz/5962/2011-023Cham-1.0_0002.jp2'
      end
      
      it "handles more than two periods in the filename" do
        @params[:filename] = '2011-023Cham-1.0_0002.aazz'
        req = ImageServiceRequest.new(@params)
        req.get_file_prefix(@params[:filename]).should == '2011-023Cham-1.0_0002.aazz'
        req.stacks_file_path.should == 'file://' << DigitalStacks::STACKS_DATA_STORE << '/bb/718/gz/5962/2011-023Cham-1.0_0002.aazz.jp2'
      end
      
    end
  
    context "#build_djatoka_zoom_request" do
        
      it "sets the level from a zoom request" do
        md =  { :max_width => 4800, :max_height => 2400, :max_levels => 6 }
        dm = DjatokaMetadata.new(md, 'file:///stacks/aa/123/bb/4567/image_003.jp2')
        DjatokaMetadata.should_receive(:find).and_return(dm)
        
        @params[:zoom] = '36'
        request = ImageServiceRequest.new(@params)
        request.djatoka_region.query.level.should eql "5"
        request.djatoka_region.query.scale.should eql "0.72"
      end
      
    end
  
    context "restricted requests" do
      before(:each) do
        DjatokaMetadata.stub!(:find).and_return(stub(:md).as_null_object)
      end

      it "does not throw an exception if only valid params (for a restricted request) are passed in" do
        @params[:filename] = 'bb718gz5962_10_0001_thumb.png'
        request = ImageServiceRequest.new(@params, true)
        request.format.should eql('png')
        lambda { ImageServiceRequest.new(@params, true) }.should_not raise_error(ArgumentError)
      end

      it "does not throw an exception if only valid params (for a restricted request) without format are passed in" do
        @params[:filename] = 'bb718gz5962_10_0001_thumb'
        request = ImageServiceRequest.new(@params, true)
        request.format.should eql('jpg')
        lambda { ImageServiceRequest.new(@params, true) }.should_not raise_error(ArgumentError)
      end
      
      it "does not throw an exception if only valid params (for a restricted request) including region are passed in" do
        @params[:filename] = 'bb718gz5962_10_0001'
        @params[:region] = '10,10,512,512'
        request = ImageServiceRequest.new(@params, true)
        request.format.should eql('jpg')
        lambda { ImageServiceRequest.new(@params, true) }.should_not raise_error(ArgumentError)
      end

      it "throws an exception if restricted params are passed in" do
        @params[:filename] = 'bb718gz5962_10_0001_thumb.jpg'
        @params[:h]='1000'
        lambda { ImageServiceRequest.new(@params,true) }.should raise_error(ArgumentError)
      end
    end
  
    context "setting requested image size" do
      before(:each) do
        DjatokaMetadata.stub!(:find).and_return(stub(:md).as_null_object)
      end

      it "parses allowed sizes from the filename" do
        @params[:filename] = 'bb718gz5962_10_0001_thumb.png'
        request = ImageServiceRequest.new(@params)
        request.size.should == "thumb"
      end

      it "does not set @size if the filename does not end with a valid size " do
        @params[:filename] = 'bb718gz5962_10_0001.png'
        request = ImageServiceRequest.new(@params)
        request.size.should be_nil
      end
    end
  
    context "setting rotation" do
      it "sets rotation from the user request paramater of rotate" do
        @params[:rotate] = '180'
        request = ImageServiceRequest.new(@params)
        request.djatoka_region.query.rotate.should == '180'
      end
      
      it "rejects negative rotations" do
        @params[:rotate] = '-180'
        lambda { ImageServiceRequest.new(@params) }.should raise_error(ArgumentError)
      end
      
      it "rejects rotations that aren't multiples of 90" do
        @params[:rotate] = '92'
        lambda { ImageServiceRequest.new(@params) }.should raise_error(ArgumentError)
      end
    end
    
    context "setting output scale" do
      it "sets scale from the user request w and h parameters" do
        @params[:w] = '800'
        @params[:h] = '600'
        request = ImageServiceRequest.new(@params)
        request.djatoka_region.query.scale.should == '800,600'
      end
      
      it "sets height to 0 if width is only requested" do
        @params[:w] = '800'
        request = ImageServiceRequest.new(@params)
        request.djatoka_region.query.scale.should == '800,0'
      end
      
      it "sets width to 0 if height is only requested" do
        @params[:h] = '600'
        request = ImageServiceRequest.new(@params)
        request.djatoka_region.query.scale.should == '0,600'
      end
      
      it "rejects negative values for width" do
        @params[:w] = '-800'
        lambda { ImageServiceRequest.new(@params) }.should raise_error(ArgumentError)
        
        @params[:w] = '600'
        @params[:h] = '-300'
        lambda { ImageServiceRequest.new(@params) }.should raise_error(ArgumentError)
      end  
    end
    
    context "setting region" do
      context "with zoom" do
        it "sets region and level when the user specifies a zoom level and region" do
          md =  { :max_width => 4800, :max_height => 2400, :max_levels => 6 }
          dm = DjatokaMetadata.new(md, 'file:///stacks/aa/123/bb/4567/image_003.jp2')
          DjatokaMetadata.should_receive(:find).and_return(dm)
          
          @params[:zoom] = '25'
          @params[:region] = '256,512,256,256'
          request = ImageServiceRequest.new(@params)
          request.djatoka_region.query.region.should == '2048,1024,256,256'
          request.djatoka_region.query.level.should  == "4"
          request.djatoka_region.query.scale.should == nil
        end
      end
      
      context "with pre-cast size" do
        it "sets region and level when the user specifies a pre-cast image size and region" do
          md =  { :max_width => 4800, :max_height => 2400, :max_levels => 6 }
          dm = DjatokaMetadata.new(md, 'file:///stacks/aa/123/bb/4567/image_003.jp2')
          DjatokaMetadata.should_receive(:find).and_return(dm)
          
          @params[:filename] = 'bb718gz5962_10_0001_xlarge'
          @params[:region] = '256,512,256,256'
          request = ImageServiceRequest.new(@params)
          request.djatoka_region.query.region.should == '1024,512,256,256'
          request.djatoka_region.query.level.should  == "5"
          request.djatoka_region.query.scale.should == nil
        end
      end
      
      context "without zoom or size" do
        it "sets region from the user request paramater of region" do
          @params[:region] = '1000,2000,800,600'
          request = ImageServiceRequest.new(@params)
          request.djatoka_region.query.region.should == '2000,1000,600,800'
        end

        it "rejects regions that aren't of the format x,y,w,h" do
          @params[:region] = '800,600'
          lambda { ImageServiceRequest.new(@params) }.should raise_error(ArgumentError)
        end
        
        
      end

      
    end
    
    describe "#build_pre_cast_size_request" do
      
      before(:each) do
        md =  { :max_width => 4800, :max_height => 2400, :max_levels => 6 }
        dm = DjatokaMetadata.new(md, 'file:///stacks/aa/123/bb/4567/image_003.jp2')
        DjatokaMetadata.stub!(:find).and_return(dm)
      end

      it "determines the djatoka level from the requested pre-cast size" do
        @params[:filename] = 'bb718gz5962_10_0001_medium'
        request = ImageServiceRequest.new(@params)
        request.djatoka_region.query.level.should == "3"
      end
        
      it "sets djatoka level and scale" do
        @params[:filename] = 'bb718gz5962_10_0001_thumb'
        request = ImageServiceRequest.new(@params)
        request.djatoka_region.query.level.should == "3"
        request.djatoka_region.query.scale.should == "400"
      end
      
      it "sets djatoka level, region, and scale" do
        @params[:filename] = 'bb718gz5962_10_0001_square'
        request = ImageServiceRequest.new(@params)
        request.djatoka_region.query.level.should == "1"
        request.djatoka_region.query.scale.should == "100"
        request.djatoka_region.query.region.should == "0,1200,75,75"
      end
    end
  end

end

