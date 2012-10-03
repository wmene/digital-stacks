require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Dor::RightsAuth do
  before(:all) do
    DigiStacks.config.rights.md_service_url = 'http://purl-test.stanford.edu'
  end
  
  describe "#stanford_only?" do
    
    it "returns true if the object has stanford-only read access" do
      rights =<<-EOXML
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
      RestClient.stub!(:get).and_return(rights)
      
      r = Dor::RightsAuth.fetch_and_build('bd186zk8210')
      r.stanford_only_unrestricted?.should be_true
    end
    
  end
  
  describe "error handling" do
    
    it "returns nil if it cannot find RightsMetadata" do
      Dor::RightsAuth.find('druid:does-not-exist').should be_nil
    end
    
  end
  
  describe "#find" do
    it "should try to grab Dor::RightsAuth from local cache before calling rightsMD service" do
      stub_auth = Dor::RightsAuth.new
      stub_auth.obj_lvl = Dor::EntityRights.new
      stub_auth.obj_lvl.world = Dor::Rights.new(true, nil)
      Dor::RightsAuth.should_receive(:fetch_from_cache_or_service).and_return stub_auth
      
      r = Dor::RightsAuth.find('blah')
      r.should be_public_unrestricted
    end
    
  end

end