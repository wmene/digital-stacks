#!/usr/bin/env ruby
require 'rubygems'

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib"))
require 'helpers/cacheable'
require 'rights_auth'

DigiStacks.config.rights.md_service_url = 'http://purl-test.stanford.edu'
LyberCore::Log.set_logfile($stdout)

require 'benchmark'
Benchmark.bmbm do |x|
      x.report("RightsAuth: memcached") { RightsAuth.find('druid:bb110sm8219') }
      x.report("RightsAuth: no cache")  { RightsAuth.old_find('druid:bb110sm8219') }
end

