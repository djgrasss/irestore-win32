#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)
                  
require 'rubygems'
require 'pp'	
require 'base64'
require 'net/https'
require 'uri'
require 'img3file'
require 'fileutils' 
require 'pathname'
require 'plist_ext'
require 'ipsw_ext'

### gc-apple-dump_02
# checkUnbrickHealth 
def checkhealth
	obj = {
		"ECID" 					=> 86872710412,
		"ICCID" 				=> "89860109158380264868",
		"IMEI"					=> "012037007915703",
		"IMSI"					=> "460018445986486",
		"SerialNumber" 	=> "889437758M8"
		}
	payload = obj.to_plist(:xml1)
	
	uri_albert_serv = "https://albert.apple.com/WebObjects/ALUnbrick.woa/wa/ALActivationMonitor/checkUnbrickHealth"
	uri = URI.parse(uri_albert_serv)
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	request = Net::HTTP::Post.new(uri.request_uri)
	request["x-apple-store-front"] = "143465-2,12" 
	request["x-apple-tz"] = "28800"
	request["User-Agent"] = "InetURL/1.0" 
	request["Content-Length"] = payload.length
	request["Content-Type"] = "application/x-apple-plist"
	request.body = payload                    
	response = http.request(request)  
	p response.body 
end

def update_img3file
  ### unzip
  # system("mkdir -p #{PATH_DMG}")
  # system("unzip -d #{PATH_DMG} #{FILE_IPSW}")  

  ### tss request 
  # gc-apple-dump_03
  # tssrqst_fn = "./amai/debug/tss-request.plist"
  # payload = File.open(tssrqst_fn).read
  buffer = File.open(FILE_MANIFEST_PLIST).read
  p buffer
  obj = PropertyList.load(buffer)
  # pp obj["BuildIdentities"][0]

  # pp obj
  rqst_obj = {
  	"@APTicket" => true, "@BBTicket" => true,  "@HostIpAddress" =>  "172.16.191.1",
  	"@HostPlatformInfo" => "mac", "@UUID" => "6D27AA8B-FE93-442D-B957-46BCC347D5FC",  "@VersionInfo" =>  "libauthinstall-68.1",
  	"ApECID" =>  86872710412, "ApProductionMode" => true
  }

  tmp = obj["BuildIdentities"][0] 
  manifest_info = {}

  tmp.each do |k, v|
  	case k
  	when "ApBoardID", "ApChipID", "ApSecurityDomain"
  		rqst_obj[k] = v
  	when "UniqueBuildID"
  		v.blob = true
  		rqst_obj[k] = v  
  	when "Manifest"
  		hash = {} 
  		tmp["Manifest"].each do |mk, mv|
  			#pp mk, mv   
  			unless mk =~ /Info/ 
  				hash[mk] ={}
  		 	 	mv.each do |vk, vv|
   					#pp vk, vv
  	        case vk
  					when "Info"
  					  manifest_info = manifest_info.merge({mk => vv["Path"]})
  					when "PartialDigest", "Digest"
  						vv.blob = true
  						hash[mk] = hash[mk].merge({vk => vv})
  					else
    					hash[mk] = hash[mk].merge({vk => vv}) 
  					end
  				end     
  			end
  		end
  		rqst_obj = rqst_obj.merge(hash)
  	end
  end        

  #pp manifest_info   

  # pp rqst_obj
  payload = PropertyList.dump(rqst_obj, :xml1)
  p payload 

  # http post 
  uri_gs_serv = "http://gs.apple.com/TSS/controller?action=2"
  #uri_gs_serv = "http://cydia.saurik.com/TSS/controller?action=2"
  #uri_gs_serv = "http://127.0.0.1:8080/TSS/controller?action=2" 
  uri = URI.parse(uri_gs_serv)
  http = Net::HTTP.new(uri.host, uri.port)       
  request = Net::HTTP::Post.new(uri.request_uri)
  request["User-Agent"] = "InetURL/1.0" 
  request["Content-Length"] = payload.length
  request["Content-Type"] = 'text/xml; charset="utf-8"'  
  request.body = payload                    
  response = http.request(request)  
  p response.body
  # STATUS=0&MESSAGE=SUCCESS&REQUEST_STRING=
  buffer = response.body.split("&REQUEST_STRING=")[1]
  # tssresp_fn = "./amai/debug/tss-response.plist"
  # buffer = File.open(tssresp_fn).read
  obj = PropertyList.load(buffer)
  
  pp obj 
  ### patch img3
  manifest_info.each do |k, v|
    p k
    if obj.include?(k)
	#pp k, v 
	filename = File.join(PATH_DMG, v)    
	img3 = Img3File.new
	data = File.open(filename,'r').read
	img3.parse(StringIO.new(data)) 

	### change the img3 file
	blob = obj[k]["Blob"]
	img3.update_elements(StringIO.new(blob), blob.length)
			  
	tmp_filename = File.join(PATH_DMG_NEW, v) 
	FileUtils.mkdir_p(Pathname.new(tmp_filename).dirname)    
	f = File.open(tmp_filename, "wb")
	f.write(img3.to_s) 
	f.close        
    end
  end
end 

if __FILE__ == $0
  update_img3file
end

