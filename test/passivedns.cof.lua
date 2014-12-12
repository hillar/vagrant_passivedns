--[[

passivedns fields
:Fields:
    | name:"timestamp_s" type:double value:1.418298721e+09
    | name:"type" type:string value:"A"
    | name:"class" type:string value:"IN"
    | name:"timestamp_ms" type:double value:511594
    | name:"count" type:double value:1
    | name:"query" type:string value:"a1843636cac041db10ae198ce8a0e8ea3.profile.mad50.cloudfront.net."
    | name:"answer" type:string value:"54.230.63.186"
    | name:"client" type:string value:"213.184.49.190"
    | name:"ttl" type:double value:60
    | name:"server" type:string value:"205.251.197.26"

http://www.ietf.org/archive/id/draft-dulaunoy-kaplan-passive-dns-cof-02.txt

   {"count": 59, "time_first": 1384865833, "rrtype": "A",
   "rrname": "www.ietf.org", "rdata": "4.31.198.44",
   "time_last": 1389022219}

--]]

local ip = require("ip_address")
require "string"

function process_message ()
  local message = {Type = "cof.passivedns", Fields = {}}	
  -- TODO map timestamp_s & timestamp_ms
  local q = read_message("Fields[query]")	
  local a = read_message("Fields[answer]")
  -- message.Fields['Answer'] = a
  if  ip.v4:match(a) then
    message.Fields['rrtype'] = "A"
    message.Fields['rrname'] = q
  	message.Fields['rdata'] = a
  	local num = 0
  	a:gsub("%d+", function(s) num = num * 256 + tonumber(s) end)
    message.Fields['aton'] = num 
  elseif ip.v6:match(a) then
    message.Fields['rrtype'] = "AAAA"
    message.Fields['rrname'] = q
    message.Fields['rdata'] = a
    -- TODO convert to number
  else -- not IP
    -- TODO do something ...
      message.Fields['alias'] = q .. " -> " .. a
  end
  inject_message(message)  
  return 0
end

function timer_event(ns)
end