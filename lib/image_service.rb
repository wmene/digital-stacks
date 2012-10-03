
require 'stacks_base'
require 'helpers/iiif_translator'
require 'json'
require 'securerandom'
require 'curl'

class ImageService < StacksBase
  
  include IiifTranslator
  
  enable :sessions
  
  def with_exception_logging(&block)
    @restricted_request = false
    yield
  rescue Exception => e
    LyberCore::Log.exception e
    throw :halt, [500, e.to_s + "\nSee logs for exception detail"]
  end
  
  def thumb_square_tile_request?
    return true if(params[:filename] =~ /_(thumb|square)\..{3,4}$/ || params[:filename] =~ /_(thumb|square)$/)
    
    region = params[:region]
    return false if(region.nil?)
    unless (region =~ /^\d+,\d+,(\d+),(\d+)$/ )
      raise ArgumentError.new( "Invalid region parameter '#{region}' - must be of the format 'X,Y,W,H'" )
    end
    pixel_request = $1.to_i * $2.to_i
    if(pixel_request <= ImageServiceRequest::MAX_TILE_PIXELS)
      return true
    else
      return false
    end
  end
  
  def available_sizes_request?
    params[:filename] =~ /(xml|json)/i
  end
  
  def handle_available_sizes_request
    LyberCore::Log.info("ImageService received [Params]: #{params.inspect}")
    image_request = ImageServiceRequest.new(params, @restricted_request)
    
    md = DjatokaMetadata.find(image_request.stacks_file_path)
    if(params[:filename] =~ /xml/)
      available_sizes_content =  md.to_available_size_xml
    else
      # Return json by default
      available_sizes_content = JSON.pretty_generate(md.to_available_size_hash)
    end
    return [200, {'content-type' => Rack::Mime.mime_type(File.extname(params[:filename]))}, available_sizes_content]  
  end
  
  def redirect_to_auth_path
    auth_path = "/image/auth/#{params[:id]}/#{params[:filename]}"
    qs = request.query_string
    auth_path << (qs == "" ? "" : "?#{qs}")
    redirect auth_path
  end
  
  # Strips file extension and requested image size from params[:filename] and adds .jp2 file extension
  def jp2_base_filename
    fname = params[:filename]
    fname.chomp(File.extname(fname)).split(ImageServiceRequest::SIZE_REGEX).first << '.jp2'
  end
    
  # Unauthenticated path
  get '/:id/:filename/?' do
    with_exception_logging do
      if available_sizes_request?
        # can't return from a block, use next
        # http://stackoverflow.com/questions/2325471/using-return-in-a-ruby-block
        next handle_available_sizes_request
      end
      
      su_only, su_rule = rights.stanford_only_rights_for_file(jp2_base_filename)
      if(su_only && !thumb_square_tile_request?)
        if(session[:webauth_user])
          LyberCore::Log.debug("session[:webauth_user]: #{session[:webauth_user]}")
          image_service(params)
        else
          redirect_to_auth_path
        end
        next
      end

      restrict_or_authorize_request(DigiStacks::Auth::NO_AUTH)
      image_service(params)
    end 
  end
  
  def webauthed?
    user = request.env['WEBAUTH_USER']
    return false if(user.nil? || user.empty?)
    true
  end
  
  # Authenticated path
  get '/auth/:id/:filename/?' do
    with_exception_logging do
      # Set the webauth user into the session so that we don't have to redirect for subsequent requests
      if webauthed?
        LyberCore::Log.debug('request.env[WEBAUTH_USER]: ' << request.env['WEBAUTH_USER'])
        session[:webauth_user] = request.env['WEBAUTH_USER']
      end
      if available_sizes_request?
        # can't return from a block, use next
        # http://stackoverflow.com/questions/2325471/using-return-in-a-ruby-block
        next handle_available_sizes_request
      end
      
      restrict_or_authorize_request(DigiStacks::Auth::WEBAUTH)
      with_exception_logging { image_service(params)}
    end
  end
    
  # App path
  get '/app/:id/:filename/?' do
    with_exception_logging do
      authenticate
    
      if available_sizes_request?
        # can't return from a block, use next
        # http://stackoverflow.com/questions/2325471/using-return-in-a-ruby-block
        next handle_available_sizes_request
      end

      restrict_or_authorize_request(DigiStacks::Auth::AGENT)
      image_service(params)
    end
  end
  
  # IIIF path
  get '/iiif/*' do
    # create new values for PATH_INFO and QUERY_STRING from translated params
    id, new_query_string = translate
    # Ugly hack, but this is the only way to pass a query string to another route
    # See http://stackoverflow.com/a/9085477/358724
    @original_params = nil
    call! env.merge "PATH_INFO" => '/' << id , "QUERY_STRING" => new_query_string
  end
  
  get '/other/:druid/:file' do
    params.inspect
  end
  
  # Checks request to see if it is for thumb, square, or tile.
  # If not any of these, then check authorization for this auth_type
  # @param [Symbol] auth_type one of the constants defined in DigitStacks::Auth - NO_AUTH, WEBAUTH, or AGENT
  def restrict_or_authorize_request(auth_type)
    if(thumb_square_tile_request?)
      @restricted_request = true
    elsif( !authorized?(auth_type, jp2_base_filename) )
      throw(:halt, [403, "Not authorized\n"])
    end
  end

  # core image service
  def image_service(params)
    LyberCore::Log.info("ImageService received [Params]: #{params.inspect}")
    image_request = ImageServiceRequest.new(params, @restricted_request)
        
    # Toggle image delivery behavior based on the supplied 'action' parameter
    action = params[:action]
    url = image_request.url
    LyberCore::Log.debug("image_request.url: #{CGI::unescape(url)}")
    #file_contents = RestClient.get url
    if( action.eql? 'download' )
      send_opts = {:filename => "#{params[:filename]}.#{image_request.format}", :type => "#{image_request.mime_type}", :disposition => "attachment"}
    else
      send_opts = {:type => "#{image_request.mime_type}", :disposition => "inline"}
    end
    path = ''
    curl = Curl::Easy.perform(url)
    File.open(File.join(Sinatra::Application.root, "..", "tmp", "image", SecureRandom.hex(10)), "wb") do |f|
      f << curl.body_str
      path = f.path
    end

    x_send_file path, send_opts
  end

  


end

