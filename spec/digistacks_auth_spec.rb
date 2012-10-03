require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class DummyApp
  include DigiStacks::Auth
  include DigiStacks::Auth::App
  
  attr_accessor :auth
  
  def params 
    {:id => ''}
  end
  
end

describe DigiStacks::Auth::App do
  before(:each) do
    @app = DummyApp.new
  end
  
  
  describe "#authorized?" do

    it "returns true if the agent has permission to access the object" do
      xml =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <file>restricted.doc</file>
            <machine>
              <group>stanford</group>
            </machine>
          </access>
          <access type="read">
            <file>app-only.doc</file>
            <machine>
              <agent>exclusive-app</agent>
            </machine>
          </access>
          <access type="read">
            <file>no-dl.doc</file>
            <machine>
              <world rule="no-download"/>
              <group>stanford</group>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      rights = Dor::RightsAuth.parse xml
      Dor::RightsAuth.stub!(:find).and_return(rights)
      @app.auth = stub('auth')
      @app.auth.stub(:username).and_return('exclusive-app')
      
      @app.authorized?(DigiStacks::Auth::NO_AUTH).should be_true
      @app.authorized?(DigiStacks::Auth::NO_AUTH, 'restricted.doc').should be_false
      @app.authorized?(DigiStacks::Auth::NO_AUTH, 'public.doc').should be_true
      @app.authorized?(DigiStacks::Auth::NO_AUTH, 'no-dl.doc').should be_false
      
      @app.authorized?(DigiStacks::Auth::WEBAUTH, 'restricted.doc').should be_true
      
      # Agent not named for this file
      @app.authorized?(DigiStacks::Auth::AGENT, 'restricted.doc').should be_false
      # Agent named for this file
      @app.authorized?(DigiStacks::Auth::AGENT, 'app-only.doc').should be_true
      # File not listed, use object level rights
      @app.authorized?(DigiStacks::Auth::AGENT, 'public.doc').should be_true
    end
  end

end
