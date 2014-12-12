require "cjson"
local util = require("util") 
-- https://github.com/mozilla-services/lua_sandbox/blob/master/modules/util.lua


local message = {
   Type = "IGNORE",
   Fields = {}
}

local Type = read_config("type") or "UNDEFINED"
local DEBUG = read_config("debug") or false 


function process_message()

   local raw_message = read_message("Payload")
   local ok, json = pcall(cjson.decode, raw_message)
   if not ok then
        if DEBUG then inject_payload("txt", "debug", "json not ok : " .. json) end
      return 0 
   end
   -- if json has nested struc, then there will be one of errors
   -- inject_message(msg) :: could not encode protobuf - unsupported type: nil
   -- pcall(inject_message,msg) :: Failed after a successful inject_message call: 
   -- to go around this error, turn json to 'flat'
   -- see also some discussion
   -- https://github.com/mozilla-services/heka/issues/889
   local flat = {}
   util.table_to_fields(json, flat, nil)
   if DEBUG then inject_payload("txt", "debug", cjson.encode(flat) , " <- flatten json") end
   
   message.Fields =  flat
   message.Type = Type

   if DEBUG then inject_payload("txt", "debug", cjson.encode(message) , " <- message before inject") end

   if not pcall(inject_message, message) then 
        if DEBUG then inject_payload("txt", "debug", "inject message failed") end
        return -1 
   end
   
   return 0

end