-- Imports the reviewed phase 1 artwork into the authorized group; no place publish.
assert(game.PlaceId == 140221183064352, "Unexpected place")
assert(game.CreatorId == 204998424, "Unexpected creator")
assert(game:GetService("RunService"):IsEdit(), "Import requires edit context")
local allowed = {
	["BombYourWay-Phase1Objects-v1.png"] = "atlas",
	["BombYourWay-Phase1Entrance-v1.png"] = "entrance",
	["BombYourWay-Phase1Courtyard-v1.png"] = "courtyard",
}
_G.BombPhaseOneImport = _G.BombPhaseOneImport or { state = "idle", uploaded = {} }
local job = _G.BombPhaseOneImport
assert(job.state ~= "running" and job.state ~= "selecting", "An import is already active")
job.state = "selecting"
local files = game:GetService("StudioService"):PromptImportFilesAsync({ "png" })
if not files or #files == 0 then
	job.state = "cancelled"
	return
end
job.state = "running"
local service = game:GetService("AssetService")
for _, file in ipairs(files) do
	local name = allowed[file.Name]
	if not name then
		job.state = "failed"
		error("Only reviewed phase 1 import PNGs are permitted")
	end
	if not job.uploaded[name] then
		local ok, message = pcall(function()
			local editable = service:CreateEditableImageAsync(Content.fromUri(file:GetTemporaryId()))
			assert(editable, "Image could not load")
			local size = editable.Size
			local result, id = service:CreateAssetAsync(editable, Enum.AssetType.Image, {
				CreatorId = 204998424,
				CreatorType = Enum.AssetCreatorType.Group,
				Name = file.Name,
				Description = "Original Awakening Fields art for Bomb Your Way!",
			})
			editable:Destroy()
			assert(result == Enum.CreateAssetResult.Success, tostring(result) .. ": " .. tostring(id))
			job.uploaded[name] = id
			print("BOMB_PHASE1_UPLOADED", name, id, size.X, size.Y)
		end)
		if not ok then
			job.state = "failed"
			job.error = tostring(message)
			warn("BOMB_PHASE1_IMPORT_ERROR", message)
			return
		end
	end
end
job.state = "complete"
print("BOMB_PHASE1_IMPORT_COMPLETE")
