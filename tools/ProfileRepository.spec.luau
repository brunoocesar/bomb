local Repository=require("../game/Server/ProfileRepository")
local Data=require("../game/Shared/ProfileData")
local Progress=require("../game/Shared/LobbyProgress")
local records={}
local failure=false
local now=100000
local serial=0
local store={}
function store:UpdateAsync(key,callback)
 if failure then error("injected transport failure") end
 local result=callback(records[key])
 if result then records[key]=result end
 return result
end
local function service()
 return Repository.new(store,function() return now end,function() serial+=1; return tostring(serial) end)
end
local checks=0
local function expect(value,reason) assert(value,reason); checks+=1 end
local first=service()
local a=first.open(42)
expect(a~=nil and not Data.isReturning(a.data),"fresh profile enters adventure")
expect(service().open(42)==nil,"live session lock prevents second opener")
a.data.visited=true; a.data.completed=true; a.data.stage=2; a.data.frogUnlocked=true
Progress.setting(a.data,"muted",true)
a.data.coins=20
expect(Progress.claim(a.data,"supply",now),"claim eligible reward")
expect(first.save(a,a.data,true),"save and release")
local second=service()
local b=second.open(42)
expect(b~=nil and Data.isReturning(b.data),"new service restores lobby entry")
expect(b.data.stage==2 and b.data.frogUnlocked,"checkpoint and rescue survive")
expect(b.data.settings.muted,"mute survives reconnect")
expect(b.data.coins==23 and not Progress.claim(b.data,"supply",now),"reward is not duplicated after reconnect")
expect(not first.save(a,a.data,false),"old token cannot overwrite new session")
failure=true
expect(not second.save(b,b.data,false) and not b.busy,"temporary save failure permits retry")
expect(service().open(99)==nil,"failed load cannot start replacement profile")
failure=false
expect(second.save(b,b.data,false),"retry saves current data")
now+=181
local third=service()
local c=third.open(42)
expect(c~=nil,"expired lock recovers abrupt disconnect")
expect(not second.save(b,b.data,false),"expired owner cannot overwrite new owner")
expect(c.data.coins==23,"recovery preserves balance")
expect(third.save(c,c.data,true),"normal release after recovery")
print("Profile repository passed:",checks,"checks; injected store, not Roblox cloud transport.")