#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)
                  
require 'rubygems'
require 'ideviceinfo'
require 'update_img3file'
require 'irecoverymode'
require 'iactivate'
require 'irestore'

p RUBY_PLATFORM

if /darwin/ =~ RUBY_PLATFORM
  require 'osx_irestoremode'
else
  require 'cyg_irestoremode'
end

if __FILE__ == $0
  info=getdeviceinfo
  ecid = info["UniqueChipID"] #86872710412
  p ecid
  update_img3file(ecid) 
  enter_recovery
  enter_restore
  do_restore 
  do_activate(true)
end