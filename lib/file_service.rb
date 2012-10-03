
require 'stacks_base'

class FileService < StacksBase
  
  # Validate the druid and make sure the requested file exists
  # This filter will match all the currently defined get routes
  before %r{(/app|/auth)?/(.*)/(.*)} do
    id = params[:captures][1]
    file_name = params[:captures][2]
    
    LyberCore::Log.info("Received [Params]- id: #{id} file_name: #{file_name}")
    
   #is the id valid?
    if(id =~ /^druid:([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/i)
      @file_path = File.join(DigiStacks.config.stacks.storage_root, $1, $2, $3, $4, file_name)
    else
      throw :halt, [400, "Invalid objectId"]
    end

    unless(File.exists?(@file_path))
      throw :halt, [404, "File Not Found"]
    end

  end

  get '/:id/:file_name' do
    # Redirect to the /auth route if file or object is stanford-only
    su_only, rule = rights.stanford_only_rights_for_file(params[:file_name])
    if(su_only)
      redirect "/file/auth/#{params[:id]}/#{params[:file_name]}"
    end

    unless(authorized? DigiStacks::Auth::NO_AUTH, params[:file_name])
       throw :halt, [403, "Forbidden"]
    end

    LyberCore::Log.debug("sending file")
    x_send_file @file_path
  end

  get '/auth/:id/:file_name' do

    # Prevent the /auth path from being a backdoor to <agent> only items
    if( (!authorized?(DigiStacks::Auth::WEBAUTH, params[:file_name]) ) ||
        (!rights.stanford_only_unrestricted? && !rights.public_unrestricted?))
      throw :halt, [403, "Forbidden"]
    end

    x_send_file @file_path
  end
  
  # Protected app access to the service
  get '/app/:id/:file_name' do
    app_protected!
    x_send_file @file_path
  end

end

