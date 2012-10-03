require 'spec_helper'

# TODO need to configure apache for
# WebAuthLdapAttribute suPrivilegeGroup
# WebAuthLdapSeparator Directive
# This will enable read of stanford: privgroups
# Might be an issue for workgroup manager priv groups
# aa111bb2222

describe FileService do

  def app
    @app ||= FileService
  end
      
  describe "GET /:druid/:file_name" do
    before(:each) do
      xml =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <world />
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      rights = Dor::RightsAuth.parse xml
      
      @path = File.join('/stacks', 'aa', '123', 'bb', '4567', 'file_name')
      File.should_receive(:exists?).and_return true #.with(path).and_return true
      Dor::RightsAuth.should_receive(:find).with('druid:aa123bb4567').and_return(rights)
      
      # Mock call to x_send_file
      app.class_eval do
        helpers do
          def x_send_file(p)
            p.should == File.join('/stacks', 'aa', '123', 'bb', '4567', 'file_name')
          end
        end
      end
      
      get '/druid:aa123bb4567/file_name', nil, 'WEBAUTH_USER' => 'somesunetid'
    end
    
    context "normal behavior" do
      
      it "responds to /druid:12345/file_name" do
        last_response.should be_ok
      end

      it "checks if user is authorized for druid/file" do
        #expectation in before(:each) block
      end

      it "tests the existence of a file by determining druid tree from id" do
        #expectation in before(:each) block
      end

      it "calls send_file to stream the content back" do
        #expectation in before(:each) block
      end
      
      it "sends the file if the file is readable, not stanford-only, and public" do
        #expectation in before(:each) block
      end
      
    end
        
  end
  
  context "Attempt to access stanford-only content from /file path" do
    
    context "normal behavior" do
      
      before(:each) do
        xml =<<-EOXML
        <objectType>
          <rightsMetadata>
            <access type="read">
              <machine>
                <group>stanford</group>
              </machine>
            </access>
          </rightsMetadata>
        </objectType>
        EOXML
        @rights = Dor::RightsAuth.parse xml

        Dor::RightsAuth.should_receive(:find).with('druid:aa123bb4567').and_return(@rights)
        File.stub!(:exists?).and_return true

      end

      it "redirects to /file/auth/{druid}/{file}" do

        get '/druid:aa123bb4567/file_name', nil

        last_response.should be_redirect
        last_response.headers['Location'].should =~ /\/file\/auth\/druid:aa123bb4567\/file_name/
      end
    end
    
    context "stanford-only with a rule" do
      before(:each) do
        xml =<<-EOXML
        <objectType>
          <rightsMetadata>
            <access type="read">
              <machine>
                <group rule="no-download">stanford</group>
              </machine>
            </access>
          </rightsMetadata>
        </objectType>
        EOXML
        @rights = Dor::RightsAuth.parse xml

        Dor::RightsAuth.should_receive(:find).with('druid:aa123bb4567').and_return(@rights)
        File.stub!(:exists?).and_return true
      end

      it "redirects to /file/auth/{druid}/{file}" do

        get '/druid:aa123bb4567/file_name', nil

        last_response.should be_redirect
        last_response.headers['Location'].should =~ /\/file\/auth\/druid:aa123bb4567\/file_name/
      end
    end

  end
  
  context "Certain files with stanford-only access, but world object level access" do
    
    before(:each) do
      rxml =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <file>interviews1.doc</file> 
            <file>interviews2.doc</file> 
            <machine> 
              <group>stanford</group> 
            </machine>
          </access>
          <access type="read">
            <machine>
              <world />
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      RestClient.stub!(:get).and_return(rxml)
      
      @rights = Dor::RightsAuth.fetch_and_build('aa123bb4567')

      Dor::RightsAuth.should_receive(:find).with('druid:aa123bb4567').and_return(@rights)
      File.stub!(:exists?).and_return true
    end
    
    it "redirects to the auth path when the specific file is stanford-only" do
      get '/druid:aa123bb4567/interviews2.doc', nil
      
      last_response.should be_redirect
      last_response.headers['Location'].should =~ /\/file\/auth\/druid:aa123bb4567\/interviews2.doc/
    end
    
    it "serves up the file if it is not listed with file-specific stanford-only access" do
      # Mock call to x_send_file
      app.class_eval do
        helpers do
          def x_send_file(p)
            p.should == File.join('/stacks', 'aa', '123', 'bb', '4567', 'public.doc')
          end
        end
      end
      
      get '/druid:aa123bb4567/public.doc'
    end
  end
    
  context "Certain files with world access, but stanford-only object level access" do
    
    before(:each) do
      rxml =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <file>public1.doc</file> 
            <file>public2.doc</file> 
            <machine> 
              <world /> 
            </machine>
          </access>
          <access type="read">
            <machine>
              <group>stanford</group>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      RestClient.stub!(:get).and_return(rxml)
      
      @rights = Dor::RightsAuth.fetch_and_build('aa123bb4567')

      Dor::RightsAuth.should_receive(:find).with('druid:aa123bb4567').and_return(@rights)
      File.stub!(:exists?).and_return true
    end
    
    it "serves up the file if it is listed as having world access" do
      # Mock call to x_send_file
      app.class_eval do
        helpers do
          def x_send_file(p)
            p.should == File.join('/stacks', 'aa', '123', 'bb', '4567', 'public2.doc')
          end
        end
      end
      
      get '/druid:aa123bb4567/public2.doc'
    end
    
    it "redirects to the auth path for non-listed files because the object is stanford-only" do
      get '/druid:aa123bb4567/everything_else.doc', nil
      
      last_response.should be_redirect
      last_response.headers['Location'].should =~ /\/file\/auth\/druid:aa123bb4567\/everything_else.doc/
    end
    
    
  end
  
  context "error handling for the /file unauthenticated path" do
  
    it "returns a 403 Forbidden if the content is unreadable (no access='read' block)" do
      xml =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      rights = Dor::RightsAuth.parse xml
    
      Dor::RightsAuth.should_receive(:find).with('druid:aa123bb4567').and_return(rights)
      File.stub!(:exists?).and_return true

      get '/druid:aa123bb4567/file_name', nil
    
      last_response.should_not be_ok
      last_response.body.should == "Forbidden"
      last_response.status.should == 403
    end
  
    it "returns a 403 Forbidden if the object is not stanford-only and not public (agent auth only)" do
      xml =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <agent>only-this-app</agent>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      rights = Dor::RightsAuth.parse xml
      Dor::RightsAuth.should_receive(:find).with('druid:aa123bb4567').and_return(rights)
      File.stub!(:exists?).and_return true
          
      get '/druid:aa123bb4567/file_name', nil
    
      last_response.should_not be_ok
      last_response.body.should == "Forbidden"
      last_response.status.should == 403
    end
  end
end