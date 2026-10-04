-- Run in the Studio Command Bar. Uploads only the two original lobby PNGs.
-- Never saves or publishes the place. Successful uploads are retained for retry.
assert(game.PlaceId==140221183064352,"Unexpected place")
assert(game.CreatorId==204998424,"Unexpected creator")
assert(game:GetService("RunService"):IsEdit(),"Import requires edit context")
local allowed={
	["BombYourWay-CampBackground-v1.png"]="background",
	["BombYourWay-CampIcons-v1.png"]="icons",
}
_G.BombLobbyImport=_G.BombLobbyImport or {state="idle",uploaded={}}
local job=_G.BombLobbyImport
assert(job.state~="running" and job.state~="selecting","An import is already active")
job.state="selecting"
local files=game:GetService("StudioService"):PromptImportFilesAsync({"png"})
if not files or #files==0 then job.state="cancelled" return end
job.state="running"
local service=game:GetService("AssetService")
for _,file in ipairs(files) do
	local key=allowed[file.Name]
	if not key then job.state="failed" error("Only original lobby PNGs are permitted") end
	if not job.uploaded[key] then
		local ok,message=pcall(function()
			local editable=service:CreateEditableImageAsync(Content.fromUri(file:GetTemporaryId()))
			assert(editable,"Image could not load")
			local result,id=service:CreateAssetAsync(editable,Enum.AssetType.Image,{
				CreatorId=204998424,CreatorType=Enum.AssetCreatorType.Group,
				Name=file.Name,Description="Original cartoon camp artwork for Bomb Your Way!",
			})
			editable:Destroy()
			assert(result==Enum.CreateAssetResult.Success,tostring(result)..": "..tostring(id))
			job.uploaded[key]=id
			print("BOMB_LOBBY_UPLOADED",key,id)
		end)
		if not ok then job.state="failed" job.error=tostring(message) warn("BOMB_LOBBY_IMPORT_ERROR",message) return end
	end
end
job.state="complete"
print("BOMB_LOBBY_IMPORT_COMPLETE")
