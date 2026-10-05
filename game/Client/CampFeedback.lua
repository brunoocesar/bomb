local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Audio = require(game:GetService("ReplicatedStorage").Shared.CampAudio)
local Feedback = {}
Feedback.__index = Feedback

function Feedback.new(assets)
	local self = setmetatable({ enabled = true, roots = {}, connections = {} }, Feedback)
	self.assets = assets.CampFeedback:Clone()
	self.assets.Parent = SoundService
	self.assets.Music.SoundId = Audio.music
	self.assets.Click.SoundId = Audio.click
	self.assets.Reward.SoundId = Audio.reward
	for name, keys in pairs({
		ClickHaptic = { { 0, 0.15 }, { 30, 0.15 }, { 55, 0 } },
		ImpactHaptic = {
			{ 0, 0.3 },
			{ 60, 0.2 },
			{ 120, 0 },
		},
	}) do
		local effect = self.assets[name]
		effect.Parent = Workspace
		local waveform = {}
		for _, key in ipairs(keys) do
			table.insert(waveform, FloatCurveKey.new(key[1], key[2], Enum.KeyInterpolationMode.Linear))
		end
		effect:SetWaveformKeys(waveform)
		self[name] = effect
	end
	return self
end

function Feedback:bind(root)
	table.insert(self.roots, root)
	for _, button in ipairs(root:GetDescendants()) do
		if button:IsA("GuiButton") then
			table.insert(
				self.connections,
				button.Activated:Connect(function()
					if self.assets.Click.SoundId ~= "" then
						self.assets.Click:Play()
					end
					if self.enabled then
						self.ClickHaptic:Play()
					end
				end)
			)
		end
	end
end

function Feedback:update(state, previous)
	self.enabled = state.settings.vibration and not state.settings.reducedEffects
	local gain = state.settings.muted and 0 or 1
	self.assets.Music.Volume = state.settings.music * 0.25 * gain
	self.assets.Click.Volume = state.settings.sfx * 0.35 * gain
	self.assets.Reward.Volume = state.settings.sfx * 0.45 * gain
	if state.location == "lobby" and self.assets.Music.SoundId ~= "" then
		if not self.assets.Music.IsPlaying then
			self.assets.Music:Play()
		end
	else
		self.assets.Music:Pause()
	end
	if not self.enabled then
		self.ClickHaptic:Stop()
		self.ImpactHaptic:Stop()
	end
	if not previous then
		return
	end
	if state.location == "lobby" and state.coins > previous.coins and self.assets.Reward.SoundId ~= "" then
		self.assets.Reward:Play()
	end
	if
		self.enabled
		and state.location == "adventure"
		and (state.mode == "dead" and previous.mode ~= "dead" or previous.frog and not state.frog)
	then
		self.ImpactHaptic:Play()
	end
end

function Feedback:destroy()
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	self.ClickHaptic:Destroy()
	self.ImpactHaptic:Destroy()
	self.assets:Destroy()
end
return Feedback
