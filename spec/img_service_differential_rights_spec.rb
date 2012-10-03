require "spec_helper"
require 'json'

describe ImageService do
  
  def app
    @app ||= ImageService
  end
  
  describe "unauthenticated /image routing" do
    
    context "object/world readable with su-only file" do
      
      before(:each) do
        xml =<<-EOXML
        <objectType>
          <rightsMetadata>
            <access type="read">
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <file>img-su-only.jp2</file>
              <machine>
                <group>stanford</group>
              </machine>
            </access>
          </rightsMetadata>
        </objectType>
        EOXML
        rights = Dor::RightsAuth.parse xml
        Dor::RightsAuth.should_receive(:find).with('druid:aa123bb4567').and_return(rights)
      end

      it "redirects to /image/auth/{druid}/{file} when specific file is stanford-only" do
        get '/aa123bb4567/img-su-only', nil

        last_response.should be_redirect
        last_response.headers['Location'].should =~ /\/image\/auth\/aa123bb4567\/img-su-only/
      end

      it "redirects to /image/auth/{druid}/{file} when specific file, with extension, is stanford-only " do
        get '/aa123bb4567/img-su-only.jpg', nil

        last_response.should be_redirect
        last_response.headers['Location'].should =~ /\/image\/auth\/aa123bb4567\/img-su-only.jpg/
      end
      
      it "redirects to /image/auth/{druid}/{file} when specific file, with size-suffix and extension, is stanford-only" do
        get '/aa123bb4567/img-su-only_large.jpg', nil

        last_response.should be_redirect
        last_response.headers['Location'].should =~ /\/image\/auth\/aa123bb4567\/img-su-only_large.jpg/
      end
    end

  end

  describe "authenticated /image/auth routing" do
    
    context "object/su-only with agent only file" do
      before(:each) do
        xml =<<-EOXML
        <objectType>
          <rightsMetadata>
            <access type="read">
              <machine>
                <group>stanford</stanford>
              </machine>
            </access>
            <access type="read">
              <file>app-only.jp2</file>
              <machine>
                <agent>admin-app</agent>
              </machine>
            </access>
          </rightsMetadata>
        </objectType>
        EOXML
        rights = Dor::RightsAuth.parse xml
        Dor::RightsAuth.should_receive(:find).with('druid:aa123bb4567').and_return(rights)
      end
      
      it "prevents requests for agent only file" do
        get '/auth/aa123bb4567/app-only.jpg', nil

        last_response.should_not be_ok
        last_response.status.should == 403
      end
      
    end
  end
  
  describe "application /image/app routing" do
    before(:each) do
      app.class_eval do
        helpers do          
          def valid_apps
            {'spec-user', 'spec'}
          end
          
          def image_service(params)
             200
          end
        end
      end
      
      authorize 'spec-user', 'spec'
    end
    context "object/su-only with agent only file" do
      before(:each) do
        xml =<<-EOXML
        <objectType>
          <rightsMetadata>
            <access type="read">
              <machine>
                <group>stanford</stanford>
              </machine>
            </access>
            <access type="read">
              <file>app-only.jp2</file>
              <machine>
                <agent>spec-user</agent>
              </machine>
            </access>
          </rightsMetadata>
        </objectType>
        EOXML
        rights = Dor::RightsAuth.parse xml
        Dor::RightsAuth.should_receive(:find).with('druid:aa123bb4567').and_return(rights)
      end
      
      it "serves up requests for files intended for this agent" do
        get '/app/aa123bb4567/app-only.jpg', nil

        last_response.should be_ok
        last_response.should_not be_redirect
      end
      
      it "prevents requests for stanford-only file" do
        get '/app/aa123bb4567/other-su-only.jpg', nil

        last_response.should_not be_ok
        last_response.status.should == 403
      end

    end
  end
  
end