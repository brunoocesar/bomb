local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AnalyticsService = game:GetService("AnalyticsService")

local Simulation = require(ReplicatedStorage.Shared.Simulation)
local Tutorial = require(ReplicatedStorage.Shared.Tutorial)
local Profiles = require(script.Parent.Profiles)
local remotes = ReplicatedStorage.Assets.TutorialRemotes
local sessions = {}
local loading = {}
Players.CharacterAutoLoads = false

local function send(player, session)
	local state = session.sim:snapshot()
	state.paused = session.paused
	state.saveStatus = session.profile.localOnly and "Local Studio session" or session.saveStatus
	remotes.State:FireClient(player, state)
end

local function save(session, release)
	if session.saving then
		return
	end
	session.saving = true
	local version = session.dirtyVersion
	local data = session.sim:checkpoint()
	task.spawn(function()
		local ok = Profiles.save(session.profile, data, release)
		session.saving = false
		if ok then
			session.savedVersion = version
			session.lastSave = os.clock()
			session.saveStatus = "Checkpoint saved"
		else
			session.saveStatus = "Save pending - retrying"
		end
	end)
end

local function addPlayer(player)
	if loading[player] or sessions[player] then
		return
	end
	loading[player] = true
	local profile = Profiles.open(player.UserId)
	loading[player] = nil
	if not player.Parent then
		if profile then
			Profiles.save(profile, profile.data, true)
		end
		return
	end
	if not profile then
		remotes.State:FireClient(
			player,
			{ error = "Progress could not load. Please rejoin; your saved game has not been replaced." }
		)
		return
	end
	local session = {
		sim = Simulation.new(Tutorial, profile.data),
		profile = profile,
		direction = nil,
		inputAt = 0,
		paused = false,
		dirtyVersion = 1,
		savedVersion = 1,
		saveStatus = "Checkpoint loaded",
		lastSave = os.clock(),
		nextSaveAttempt = 0,
		tokens = 30,
		tokenAt = os.clock(),
	}
	sessions[player] = session
	send(player, session)
end

remotes.Input.OnServerEvent:Connect(function(player, action, value)
	local session = sessions[player]
	if not session then
		if action == "ready" then
			task.spawn(addPlayer, player)
		end
		return
	end
	local now = os.clock()
	session.tokens = math.min(30, session.tokens + (now - session.tokenAt) * 20)
	session.tokenAt = now
	if session.tokens < 1 then
		return
	end
	session.tokens = session.tokens - 1
	if action == "move" then
		if value == "up" or value == "down" or value == "left" or value == "right" or value == "stop" then
			session.direction = value ~= "stop" and value or nil
			session.inputAt = now
		end
	elseif action == "bomb" and not session.paused then
		session.sim:placeBomb()
	elseif action == "pause" and type(value) == "boolean" then
		session.paused, session.direction = value, nil
	elseif action == "restart" and session.sim.mode ~= "won" then
		session.sim.profile.deaths = session.sim.profile.deaths + 1
		session.sim:loadStage()
		session.sim:emit("player_died")
		session.paused, session.direction = false, nil
	elseif action == "replay" and session.sim.mode == "won" then
		session.sim:restartPhase()
		session.paused, session.direction = false, nil
	elseif action == "ready" then
		send(player, session)
	end
end)

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed = elapsed + dt
	if elapsed < 0.05 then
		return
	end
	local steps = math.min(math.floor(elapsed / 0.05), 5)
	elapsed = elapsed % 0.05
	for player, session in pairs(sessions) do
		if os.clock() - session.inputAt > 1 then
			session.direction = nil
		end
		if not session.paused then
			for _ = 1, steps do
				session.sim:step(0.05, session.direction)
			end
		end
		for _, event in ipairs(session.sim.events) do
			if
				event == "checkpoint_reached"
				or event == "secret_found"
				or event == "frog_rescued"
				or event == "item_collected"
				or event == "phase_completed"
				or event == "player_died"
				or event == "phase_started"
			then
				session.dirtyVersion = session.dirtyVersion + 1
				session.saveStatus = "Save pending"
			end
			if not RunService:IsStudio() then
				pcall(function()
					AnalyticsService:LogCustomEvent(player, event, 1, { stage = tostring(session.sim.stage) })
				end)
			end
		end
		table.clear(session.sim.events)
		if
			os.clock() >= session.nextSaveAttempt
			and (session.dirtyVersion > session.savedVersion or os.clock() - session.lastSave >= 60)
		then
			session.nextSaveAttempt = os.clock() + 5
			save(session, false)
		end
		send(player, session)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local session = sessions[player]
	sessions[player] = nil
	if session then
		local deadline = os.clock() + 10
		while session.saving and os.clock() < deadline do
			task.wait(0.1)
		end
		Profiles.save(session.profile, session.sim:checkpoint(), true)
	end
end)

game:BindToClose(function()
	local pending = 0
	for _, session in pairs(sessions) do
		pending = pending + 1
		task.spawn(function()
			local deadline = os.clock() + 15
			while session.saving and os.clock() < deadline do
				task.wait(0.1)
			end
			Profiles.save(session.profile, session.sim:checkpoint(), true)
			pending = pending - 1
		end)
	end
	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)
