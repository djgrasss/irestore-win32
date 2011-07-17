#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'                                            
require 'pp'                                
require 'iservice'

def getdeviceinfo
  l = DeviceRelay.new
  
  l.query_type
  
  # pub_key = l.get_value("DevicePublicKey").read 
	pub_key = l.get_value("DevicePublicKey")
  p "pub_key:", pub_key
  #
  l.pair_device(pub_key)
  
  # l.validate_pair(pub_key)
  
  @session_id = l.start_session
  p "session_id:", @session_id
  
  # ssl_enable
  l.ssl_enable(true)
  d = l.get_value
  pp d
  l.ssl_enable(false)
  # 
  l.stop_session(@session_id)
end

if __FILE__ == $0
  getdeviceinfo
end
