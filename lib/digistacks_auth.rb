require 'yaml'

module DigiStacks

  module Auth

    NO_AUTH = :no_auth
    WEBAUTH = :webauth
    AGENT   = :agent
    
    def rights
      @rights ||= lambda {
        id = params[:id]
        id = 'druid:' << id unless( /^druid:/ =~ id)
        Dor::RightsAuth.find(id)
      }.call
    end
    
    module App
      APP_LOGIN_FILE = File.join(Sinatra::Application.root, 'logins.yml')
      
      def load_logins
        YAML.load_file(APP_LOGIN_FILE) 
      rescue Exception => e
        LyberCore::Log.warn(e.message + "\n" + e.backtrace.join("\n"))
        LyberCore::Log.warn("!!!!! Unable to load app logins file #{APP_LOGIN_FILE}")
        LyberCore::Log.warn("!!!!! Creating an empty hash of logins.  All login attempts will fail.")
        {}
      end
      
      def valid_apps
        @@va ||= load_logins
      end
            
      def app_protected!
        authenticate
        unless authorized? DigiStacks::Auth::AGENT, params[:file_name]
          throw(:halt, [403, "Not authorized\n"])
        end
      end

      def authenticate
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        unless(@auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials[1] == valid_apps[@auth.username])
          response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
          throw(:halt, [401, "Not authorized\n"])
        end
      end
         
      # TODO treat no-download differently than the file service   
      def authorized?(auth_type, filename = nil)
        throw(:halt, [404, "Unable to find RightsMetadata for #{params[:id]}\n"]) if(rights.nil?)
        
        # Immediately return true for world-unrestricted files
        # TODO will we ever have a rule for a different agent that is more restrictive when world is unrestricted?
        return true if rights.world_unrestricted_file? filename
        
        case auth_type
        when NO_AUTH
          auth_val, rule = rights.world_rights_for_file filename
        when WEBAUTH
          auth_val, rule = rights.stanford_only_rights_for_file filename
        when AGENT
          auth_val, rule = rights.agent_rights_for_file filename, @auth.username
        end
        
        if(!auth_val || rule)  # if the auth value is false or a rule exists (we assume it's no-download), then deny
          LyberCore::Log.warn("#{auth_type} has unknown rule attribute: #{rule}.  Not authorizing agent") if rule && rule != 'no-download'
          # TODO we will need to handle rules other than no-download here
          return false
        else
          return true
        end  
      end
      
    end
  end
end