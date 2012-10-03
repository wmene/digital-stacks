require 'dor/rights_auth'
require 'helpers/cacheable'
require 'rest_client'

module Dor

  # Add find and caching to Dor::RightsAuth since it is application specific
  class RightsAuth
  
    extend Cacheable
    
    def RightsAuth.find(obj_id)
      obj_id =~ /^druid:(.*)$/
    
      cache_id = "RightsAuth-#{$1}"
      self.fetch_from_cache_or_service(cache_id) { self.fetch_and_build($1) }
    rescue RestClient::Exception => rce
      LyberCore::Log.exception rce
      nil
    end
    
    # Fetch the rightsMetadata xml from the RightsMD service
    # Parse the xml and create a Dor::RightsAuth object
    #
    # @param [String] no_ns_druid A druid without the 'druid' namespace prefix
    # @return Dor::RightsAuth created after parsing rightsMetadata xml
    def RightsAuth.fetch_and_build(no_ns_druid)
      xml = RestClient.get( DigiStacks.config.rights.md_service_url  + "/#{no_ns_druid}.xml")
      RightsAuth.parse(xml)
    end
  
    def RightsAuth.old_find(obj_id)
      r = Dor::RightsAuth.new
      obj_id =~ /^druid:(.*)$/
      r.rights_xml = Nokogiri::XML(RestClient.get(DigiStacks.config.rights.md_service_url  + "/#{$1}.xml"))
      r
    end
  
  end
end
