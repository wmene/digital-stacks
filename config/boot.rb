require 'socket'
ENV["RACK_ENV"] = "test" if(Socket.gethostname =~ /test/)
  
ENV["RACK_ENV"] ||= "development"

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default, ENV["RACK_ENV"].to_sym)

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
Dir["./lib/**/*.rb"].each { |f| require f }

LyberCore::Log.set_logfile(File.join(File.dirname(__FILE__), "..", "log", "digistacks_services.log"))
if(ENV["RACK_ENV"] == "production")
  LyberCore::Log.set_level(1)
else
  LyberCore::Log.set_level(0)
end

tmp_image_dir = File.expand_path(File.dirname(__FILE__) + '/../tmp/image')
Dir.mkdir(tmp_image_dir) unless File.exists?(tmp_image_dir)

# Patch to recognize jp2 as a mime type for this older version of sinatra
Rack::Mime::MIME_TYPES.merge!( {'.jp2' => 'image/jp2' } )

env_file = File.expand_path(File.dirname(__FILE__) + "/environments/#{ENV['RACK_ENV']}")
require env_file