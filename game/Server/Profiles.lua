local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Repository = require(script.Parent.ProfileRepository)
local store = nil
if not RunService:IsStudio() then
	store = DataStoreService:GetDataStore("BombYourWay_Tutorial_v1")
end
return Repository.new(store, os.time, function()
	return HttpService:GenerateGUID(false)
end)
