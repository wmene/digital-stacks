require 'sinatra/base'
require 'sinatra-xsendfile'

module DigiStacks
  
  # Values are set in config/environments/{ENV['RACK_ENV']}.rb
  def self.config
    @@conf ||= Confstruct::Configuration.new
  end
  
end

class StacksBase < Sinatra::Base
  include Sinatra::Xsendfile
  include DigiStacks::Auth
  include DigiStacks::Auth::App
  
  enable :sessions
  #use Rack::Session::Pool, :expire_after => 60 * 60 * 24 * 365
end