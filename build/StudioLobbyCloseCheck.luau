assert(game.PlaceId==140221183064352 and game:GetService("RunService"):IsStudio())
local source=game.ServerScriptService.Server.ProfileRepository
assert(source.Source:find("function Profiles.close",1,true),"Rojo close patch missing")
local module=source:Clone()
module.Name="ProfileRepositoryCloseDiagnostic"
module.Parent=source.Parent
local Repository=require(module)
local records={}
local fail=true
local store={}
function store:UpdateAsync(key,callback)
 if fail then error("temporary QA transport failure") end
 local result=callback(records[key])
 if result then records[key]=result end
 return result
end
local profiles=Repository.new(store,os.time,function() return "qa-token" end)
fail=false
local p=profiles.open("isolated-close-test")
p.data.visited=true; p.data.coins=41
fail=true
task.spawn(function()
 task.wait(.1); fail=false
end)
task.spawn(function()
 assert(profiles.close(p,p.data,2),"Close retry failed in Roblox")
 assert(records[p.key].data.coins==41 and not records[p.key].lock)
 print("BOMB_LOBBY_CLOSE_RETRY_VERIFIED",records[p.key].data.coins)
 module:Destroy()
end)