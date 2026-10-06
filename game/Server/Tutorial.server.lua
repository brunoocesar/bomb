local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AnalyticsService = game:GetService("AnalyticsService")

local Simulation = require(ReplicatedStorage.Shared.Simulation)
local Tutorial = require(ReplicatedStorage.Shared.Tutorial)
local LobbyProgress = require(ReplicatedStorage.Shared.LobbyProgress)
local ProfileData = require(ReplicatedStorage.Shared.ProfileData)
local PhaseRewards = require(ReplicatedStorage.Shared.PhaseRewards)
local Profiles = require(script.Parent.Profiles)
local remotes = ReplicatedStorage.Assets.TutorialRemotes
local sessions = {}
local loading = {}
Players.CharacterAutoLoads = false

local function send(player, session)
	local state = session.sim:snapshot()
	state.paused = session.paused
	state.inputSequence = session.inputSequence or 0
	state.location = session.location
	state.lobbyUnlocked = session.lobbyUnlocked or session.sim.profile.completed
	state.settings = session.sim.profile.settings
	state.daily = session.sim.profile.daily
	state.supplies = session.sim.profile.supplies
	state.campBadge = session.sim.profile.campBadge
	state.rewardSeen = session.sim.profile.rewardSeen
	state.completed = session.sim.profile.completed
	state.finished = session.sim.profile.finished
	state.visited = session.sim.profile.visited
	state.ownedSkinPacks = session.sim.profile.ownedSkinPacks
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
	local claiming = session.sim.mode == "claiming"
	if claiming then
		data = PhaseRewards.keyCandidate(data, Tutorial.phaseId)
		if not data then
			session.saving = false
			return
		end
	end
	task.spawn(function()
		local ok = Profiles.save(session.profile, data, release)
		if ok then
			if claiming then
				session.sim:confirmChestClaim(data)
			end
			session.savedVersion = version
			session.lastSave = os.clock()
			session.saveStatus = session.dirtyVersion == version and "Checkpoint saved" or "Save pending"
		else
			session.saveStatus = "Save pending - retrying"
		end
		session.saving = false
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
	local returning = ProfileData.isReturning(profile.data)
	LobbyProgress.initialize(profile.data, os.time())
	profile.data.visited = true
	local session = {
		sim = Simulation.new(Tutorial, profile.data),
		profile = profile,
		direction = nil,
		inputAt = 0,
		paused = false,
		location = returning and "lobby" or "adventure",
		lobbyUnlocked = returning,
		dirtyVersion = 1,
		savedVersion = 0,
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
	if action == "settings" and session.location == "adventure" then
		session.location, session.direction, session.paused = "settings", nil, true
		session.sim:steer("stop")
		send(player, session)
	elseif action == "closeSettings" and session.location == "settings" then
		session.location = "adventure"
		send(player, session)
	elseif
		action == "lobby"
		and session.sim.mode ~= "claiming"
		and (session.lobbyUnlocked or session.sim.profile.completed)
	then
		session.location, session.direction, session.paused = "lobby", nil, false
		session.sim:steer("stop")
		save(session, false)
		send(player, session)
	elseif action == "continue" and session.location == "lobby" and not session.sim.profile.finished then
		session.location, session.direction, session.paused = "adventure", nil, false
		session.sim:emit("lobby_continue_clicked")
		send(player, session)
	elseif action == "playPhase" and session.location == "lobby" and value == Tutorial.phaseId then
		if session.sim.profile.finished then
			session.sim:restartPhase()
		end
		session.location, session.direction, session.paused = "adventure", nil, false
		send(player, session)
	elseif action == "claimReward" and session.location == "lobby" then
		if LobbyProgress.claim(session.sim.profile, value, os.time()) then
			session.sim:emit("reward_claimed")
		end
		send(player, session)
	elseif action == "setting" and type(value) == "table" then
		if LobbyProgress.setting(session.sim.profile, value.name, value.value) then
			session.sim:emit("settings_changed")
		end
		send(player, session)
	elseif
		action == "campBadge"
		and session.location == "lobby"
		and type(value) == "boolean"
		and session.sim.profile.supplies.count == 7
	then
		session.sim.profile.campBadge = value
		session.sim:emit("cosmetic_equipped")
		send(player, session)
	elseif action == "rewardSeen" and session.location == "lobby" then
		session.sim.profile.rewardSeen = true
		session.sim:emit("settings_changed")
	elseif action == "move" and session.location == "adventure" then
		if
			value == "up"
			or value == "down"
			or value == "left"
			or value == "right"
			or value == "stop"
			or (
				type(value) == "table"
				and type(value[1]) == "number"
				and type(value[2]) == "number"
				and value[1] == value[1]
				and value[2] == value[2]
				and math.abs(value[1]) <= 1
				and math.abs(value[2]) <= 1
			)
		then
			session.direction = value
			if
				type(value) == "table"
				and type(value[3]) == "number"
				and value[3] >= 0
				and value[3] < 2147483647
				and value[3] % 1 == 0
			then
				session.inputSequence = value[3]
			end
			session.inputAt = now
			if not session.paused then
				session.sim:steer(session.direction)
				send(player, session)
			end
		end
	elseif action == "equipSkinPack" then
		if session.sim:equipSkinPack(value) then
			send(player, session)
		end
	elseif action == "bomb" and session.location == "adventure" and not session.paused then
		session.sim:placeBomb()
	elseif action == "interact" and session.location == "adventure" and not session.paused then
		if session.sim:interactChest() then
			session.direction = nil
			session.dirtyVersion += 1
			session.nextSaveAttempt = 0
			save(session, false)
		end
	elseif action == "pause" and session.location == "adventure" and type(value) == "boolean" then
		session.paused, session.direction = value, nil
		session.sim:steer("stop")
	elseif
		action == "restart"
		and session.location == "adventure"
		and session.sim.mode ~= "won"
		and session.sim.mode ~= "claiming"
	then
		session.sim.profile.deaths = session.sim.profile.deaths + 1
		session.sim:loadStage()
		session.sim:emit("player_died")
		session.paused, session.direction = false, nil
	elseif action == "replay" and session.sim.mode == "won" then
		session.sim:restartPhase()
		session.paused, session.direction = false, nil
		session.location = "adventure"
	elseif action == "ready" then
		send(player, session)
	end
end)

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed = elapsed + dt
	local sendState = elapsed >= 0.05
	if sendState then
		elapsed = elapsed % 0.05
	end
	-- Physics uses all elapsed time; network snapshots keep their existing rate.
	local steps = math.max(1, math.ceil(dt / 0.025))
	for player, session in pairs(sessions) do
		if os.clock() - session.inputAt > 1 then
			session.direction = "stop"
		end
		if sendState then
			LobbyProgress.refresh(session.sim.profile, os.time())
		end
		if not session.paused and session.location == "adventure" then
			for _ = 1, steps do
				session.sim:step(dt / steps, session.direction)
			end
		end
		for _, event in ipairs(session.sim.events) do
			LobbyProgress.event(session.sim.profile, event, os.time())
			if
				event == "checkpoint_reached"
				or event == "secret_found"
				or event == "frog_rescued"
				or event == "item_collected"
				or event == "phase_completed"
				or event == "player_died"
				or event == "phase_started"
				or event == "cosmetic_equipped"
				or event == "settings_changed"
				or event == "reward_claimed"
				or event == "energy_box_destroyed"
				or event == "chest_unlocked"
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
		if sendState then
			send(player, session)
		end
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
		Profiles.close(session.profile, session.sim:checkpoint(), math.max(0, deadline - os.clock()))
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
			Profiles.close(session.profile, session.sim:checkpoint(), math.max(0, deadline - os.clock()))
			pending = pending - 1
		end)
	end
	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)
