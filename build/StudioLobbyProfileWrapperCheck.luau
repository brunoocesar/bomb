assert(game.PlaceId==140221183064352 and game:GetService("RunService"):IsStudio())
assert(game.ServerScriptService.Server:FindFirstChild("ProfileRepository"))
local Profiles=require(game.ServerScriptService.Server.Profiles)
local p=Profiles.open(-123456)
assert(p and p.localOnly and not p.data.visited)
p.data.visited=true
assert(Profiles.save(p,p.data,true))
assert(p.data.visited)
print("BOMB_LOBBY_PROFILE_WRAPPER_VERIFIED","local Studio only")