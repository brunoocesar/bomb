local run = game:GetService("RunService")
local rs = game:GetService("ReplicatedStorage")
print("BOMB_PHASE1_SESSION", game.PlaceId, game.GameId, game.CreatorId, run:IsEdit(), run:IsClient(), run:IsServer())
print("BOMB_PHASE1_HIERARCHY", rs:FindFirstChild("Shared") ~= nil, rs:FindFirstChild("Assets") ~= nil, game:GetService("ServerScriptService"):FindFirstChild("Server") ~= nil)
if rs:FindFirstChild("Shared") then
    print("BOMB_PHASE1_SOURCE", rs.Shared:FindFirstChild("PhaseOne") ~= nil, rs.Shared:FindFirstChild("PhaseRewards") ~= nil)
end
