#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'iservice'
require 'plist_ext'

class InfoService < DeviceService
  
  def enter_recovery
    # obj = {"ProtocolVersion"=>"2", "Request" => "QueryType" }
    obj = {"Request" => "EnterRecovery" }
    write_plist(@socket, obj)
    p read_plist(@socket)

    p "sleeping"
    sleep(10)
  end
  
end

def enter_recovery
  d = InfoService.new(PORT_RESTORE)
  d.enter_recovery 
end

if __FILE__ == $0
  enter_recovery
end

# 
# irecovery -c "setenv auto-boot true"
# irecovery -c "saveenv"
# irecovery -c "reboot"
# 
# idevice_id -l | awk -F= '{print "ideviceenterrecovery " $1}' |bash
# # idevice_id -l
# # ideviceenterrecovery -d 39150e1823d53b7c2a8e4ff543881e762392120a 
