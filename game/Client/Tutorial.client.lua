local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local assets = ReplicatedStorage:WaitForChild("Assets")
local remotes = assets:WaitForChild("TutorialRemotes")
local definition = require(ReplicatedStorage.Shared.Tutorial)
local catalog = require(ReplicatedStorage.Shared.SpriteCatalog)
local images = require(ReplicatedStorage.Shared.SpriteImages)
-- Load the complete pack before the frog is rescued; do not stall controls.
task.spawn(function()
	local ids = {}
	for _, pack in pairs(require(ReplicatedStorage.Shared.SkinPacks).packs) do
		for _, atlasId in pairs(pack) do
			table.insert(ids, images[atlasId])
		end
	end
	game:GetService("ContentProvider"):PreloadAsync(ids)
end)
local mapImages = require(ReplicatedStorage.Shared.MapImages)
local mapCatalog = require(ReplicatedStorage.Shared.MapCatalog)
local phaseArt = definition.phaseId == "world1_phase1" and require(ReplicatedStorage.Shared.PhaseOneArt) or nil
local ActorMotion = require(ReplicatedStorage.Shared.ActorMotion)
local PlayerMovement = require(ReplicatedStorage.Shared.PlayerMovement)
local playerPrediction = require(ReplicatedStorage.Shared.PlayerPrediction).new(definition.moveInterval)
local SpriteLayout = require(ReplicatedStorage.Shared.SpriteLayout)
local spriteAnimation = require(ReplicatedStorage.Shared.SpriteAnimation).new()
local BlastVisual = require(ReplicatedStorage.Shared.BlastVisual)
local Feedback = require(ReplicatedStorage.Shared.FeedbackPresentation)
local ArenaLayout = require(ReplicatedStorage.Shared.ArenaLayout)
local Preferences = require(script.Parent.Preferences)
local uiTemplate = assets:WaitForChild(phaseArt and "PhaseOneUI" or "TutorialUI")
local ui = uiTemplate:Clone()
local lobby = require(script.Parent.LobbyController).new(player, assets, remotes)
local campFeedback = require(script.Parent.CampFeedback).new(assets)
campFeedback:bind(ui)
campFeedback:bind(lobby.ui)
ui:SetAttribute("ArenaDebug", false)
ui.Parent = player:WaitForChild("PlayerGui")
local board = ui.PlayArea.Board
local debugOverlay = require(script.Parent.ArenaDebug).new(board, definition.width, definition.height)
local state, previousState = nil, nil
local held = {}
local inputOrder = 0
local currentDirection = { 0, 0 }
local lastRefresh = 0
local stateReceivedAt = os.clock()
local gamepadDirection = nil
local wideLayout = false
local pendingAnalogInput = false
local revealUntil = 0
local retireSmoke = {}
local enemySlots = 4
for _, stage in ipairs(definition.stages) do
	enemySlots = math.max(enemySlots, #(stage.enemySpawns or {}))
end

local function applyAuthoredLayout()
	local size = ui.AbsoluteSize
	if size.X < 1 or size.Y < 1 then
		return
	end
	local deviceArea = GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets)
	local coreArea = GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
	local geometry = ArenaLayout.compute(
		size.X,
		size.Y,
		math.max(0, coreArea.Min.Y - deviceArea.Min.Y),
		definition.width,
		definition.height
	)
	wideLayout = geometry.wide
	local function place(view, rect)
		view.Position = UDim2.fromOffset(rect[1], rect[2])
		view.Size = UDim2.fromOffset(rect[3], rect[4])
	end
	place(ui.Header, geometry.header)
	place(ui.Hint, geometry.hint)
	place(ui.PlayArea, geometry.board)
	ui.Header.BackgroundTransparency = geometry.wide and 1 or 0
	ui.Hint.TextWrapped = true
	ui.Controls.Position = UDim2.fromOffset(0, 0)
	ui.Controls.Size = UDim2.fromScale(1, 1)
	for name, rect in pairs(geometry.buttons) do
		place(ui.Controls[name], rect)
	end
	if geometry.wide then
		for name, rect in pairs(geometry.headerParts) do
			place(ui.Header[name], rect)
		end
	else
		for _, name in ipairs({ "Stage", "Energy", "Stats", "Pause" }) do
			ui.Header[name].Position = uiTemplate.Header[name].Position
			ui.Header[name].Size = uiTemplate.Header[name].Size
		end
	end
	if state then
		Preferences.controls(ui, state.settings)
		Preferences.text(ui, state.settings.largeText)
		ui.Header.Stats.Text = Feedback.stats(state, size.X < 600)
		ui.Header.Energy.Text =
			string.format(wideLayout and "ENERGY %d/%d" or "ENERGY\n%d/%d", state.energy, state.totalEnergy)
	end
end
ui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyAuthoredLayout)
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(applyAuthoredLayout)
applyAuthoredLayout()

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local keyDirections = {
	[Enum.KeyCode.W] = "up",
	[Enum.KeyCode.Up] = "up",
	[Enum.KeyCode.A] = "left",
	[Enum.KeyCode.Left] = "left",
	[Enum.KeyCode.S] = "down",
	[Enum.KeyCode.Down] = "down",
	[Enum.KeyCode.D] = "right",
	[Enum.KeyCode.Right] = "right",
	[Enum.KeyCode.DPadUp] = "up",
	[Enum.KeyCode.DPadDown] = "down",
	[Enum.KeyCode.DPadLeft] = "left",
	[Enum.KeyCode.DPadRight] = "right",
}

local function sendDirection()
	local active = {}
	for _, value in pairs(held) do
		active[value.direction] = true
	end
	local x = (active.right and 1 or 0) - (active.left and 1 or 0)
	local y = (active.down and 1 or 0) - (active.up and 1 or 0)
	if next(active) == nil and gamepadDirection then
		x, y = gamepadDirection[1], gamepadDirection[2]
	end
	if state and (state.location == "lobby" or state.paused or state.mode ~= "playing") then
		x, y = 0, 0
	end
	x, y = PlayerMovement.vector({ x, y })
	if x ~= currentDirection[1] or y ~= currentDirection[2] then
		currentDirection = playerPrediction:setInput(state, { x, y }, os.clock())
		if gamepadDirection and next(active) == nil and os.clock() - lastRefresh < 0.05 then
			pendingAnalogInput = true
		else
			remotes.Input:FireServer("move", currentDirection)
			lastRefresh = os.clock()
			pendingAnalogInput = false
		end
	end
end

local function releaseInputs()
	table.clear(held)
	gamepadDirection = nil
	sendDirection()
end

local function pressInput(input, direction)
	inputOrder = inputOrder + 1
	held[input] = { direction = direction, order = inputOrder }
	sendDirection()
end

local function bomb()
	if state and state.location ~= "lobby" and not state.paused and state.mode == "playing" then
		remotes.Input:FireServer(state.canInteractChest and "interact" or "bomb")
	end
end

for buttonName, direction in pairs({ Up = "up", Down = "down", Left = "left", Right = "right" }) do
	ui.Controls[buttonName].InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			pressInput(input, direction)
		end
	end)
end
ui.Controls.Bomb.Activated:Connect(bomb)

local function pause()
	if state and state.mode == "playing" then
		releaseInputs()
		remotes.Input:FireServer("pause", not state.paused)
		ui.PauseOverlay.Panel.Restart.Text = "RESTART STAGE"
	end
end
ui.Header.Pause.Activated:Connect(pause)
ui.PauseOverlay.Panel.Resume.Activated:Connect(pause)
ui.PauseOverlay.Panel.Settings.Activated:Connect(function()
	releaseInputs()
	remotes.Input:FireServer("settings")
end)
ui.PauseOverlay.Panel.Camp.Activated:Connect(function()
	if state and state.lobbyUnlocked then
		releaseInputs()
		remotes.Input:FireServer("lobby")
	end
end)
ui.PauseOverlay.Panel.Restart.Activated:Connect(function()
	if ui.PauseOverlay.Panel.Restart.Text ~= "CONFIRM RESTART" then
		ui.PauseOverlay.Panel.Restart.Text = "CONFIRM RESTART"
		return
	end
	releaseInputs()
	remotes.Input:FireServer("restart")
	ui.PauseOverlay.Panel.Restart.Text = "RESTART STAGE"
end)
ui.ResultOverlay.Panel.Replay.Activated:Connect(function()
	releaseInputs()
	remotes.Input:FireServer("replay")
end)
ui.ResultOverlay.Panel.Camp.Activated:Connect(function()
	releaseInputs()
	remotes.Input:FireServer("lobby")
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or (state and state.location == "lobby") or UserInputService:GetFocusedTextBox() then
		return
	end
	if keyDirections[input.KeyCode] then
		pressInput(input.KeyCode, keyDirections[input.KeyCode])
	elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
		bomb()
	elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
		if state and state.canInteractChest and not state.paused then
			remotes.Input:FireServer("interact")
		end
	elseif input.KeyCode == Enum.KeyCode.P or input.KeyCode == Enum.KeyCode.ButtonStart then
		pause()
	end
end)
UserInputService.InputEnded:Connect(function(input)
	held[input] = nil
	held[input.KeyCode] = nil
	sendDirection()
end)
UserInputService.InputChanged:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Thumbstick1 then
		local vector = input.Position
		local magnitude = math.sqrt(vector.X * vector.X + vector.Y * vector.Y)
		if magnitude < 0.18 then
			gamepadDirection = nil
		else
			local strength = math.min(1, (magnitude - 0.18) / 0.82)
			gamepadDirection = { vector.X / magnitude * strength, -vector.Y / magnitude * strength }
		end
		sendDirection()
	end
end)
UserInputService.WindowFocusReleased:Connect(function()
	releaseInputs()
	if state and state.mode == "playing" and not state.paused then
		remotes.Input:FireServer("pause", true)
	end
end)
UserInputService.GamepadDisconnected:Connect(releaseInputs)

local function hint()
	if state.mode == "dead" then
		return "Stay out of the blast cross. Your stage will restart."
	elseif state.energy == state.totalEnergy then
		return Feedback.exitHint
	elseif not state.firstMove then
		return UserInputService.TouchEnabled and "Use the direction buttons to move."
			or "Move with WASD, arrows, or the left stick."
	elseif not state.firstBomb then
		return "Place a bomb next to the crate: Space / A / BOMB."
	elseif not state.firstBlock then
		return "Step aside! Explosions travel in straight lines."
	elseif state.stage == 2 and not state.frogUnlocked then
		return "Rescue the frog ahead. It can protect you from one hit!"
	else
		return state.chest and "Destroy both energy crates to unlock the Sun Chest."
			or "Destroy the glowing energy crates to open the exit."
	end
end

local tileSprites = {
	["#"] = "wall",
	B = "wood",
	A = "capacityCrate",
	L = "rangeCrate",
	S = "secretCrate",
	C = "coinCrate",
	E = "energy",
}
if phaseArt then
	for _, token in ipairs({ "B", "A", "L", "S" }) do
		tileSprites[token] = "hay"
	end
end

local mapSpriteNames = {}
local function setMapSprite(view, name)
	if mapSpriteNames[view] == name then
		return
	end
	mapSpriteNames[view] = name
	view.Visible = name ~= nil
	if not name then
		return
	end
	local art = phaseArt and phaseArt.frames[name] and phaseArt or nil
	local rect = art and art.frames[name] or mapCatalog.frames[name]
	local scaleX = (art and art.atlasSize[1] or mapImages.atlasSize[1])
		/ (art and art.imageSize[1] or mapCatalog.imageSize[1])
	local scaleY = (art and art.atlasSize[2] or mapImages.atlasSize[2])
		/ (art and art.imageSize[2] or mapCatalog.imageSize[2])
	local left, top = math.round(rect[1] * scaleX), math.round(rect[2] * scaleY)
	local right = math.round((rect[1] + rect[3]) * scaleX)
	local bottom = math.round((rect[2] + rect[4]) * scaleY)
	view.Image = art and art.atlas or mapImages.atlas
	view.ImageRectOffset = Vector2.new(left, top)
	view.ImageRectSize = Vector2.new(right - left, bottom - top)
end

local effects, itemReveals = {}, {}
local function updateFeedback()
	if not previousState or previousState.revision ~= state.revision then
		table.clear(effects)
		table.clear(itemReveals)
		for _, view in ipairs(board.Effects:GetChildren()) do
			view.Visible = false
		end
		board.Exit.Gate.ImageTransparency = 0
	end
	local destroyed, revealed = Feedback.changes(previousState, state)
	for cell, at in pairs(revealed) do
		itemReveals[cell] = at
	end
	for _, effect in ipairs(destroyed) do
		local slot = 1
		for index = 1, Feedback.poolSize do
			if not effects[index] or state.time - effects[index].at >= Feedback.duration then
				slot = index
				break
			elseif effects[index].at < effects[slot].at then
				slot = index
			end
		end
		effects[slot] = effect
		local view = board.Effects[string.format("Destroy_%02d", slot)]
		view.Position = UDim2.fromScale((effect.x - 1) / definition.width, (effect.y - 1) / definition.height)
		view.Visible = true
		setMapSprite(view.Impact, "sparkle")
		for index = 1, 4 do
			local piece = view["Piece_" .. index]
			setMapSprite(piece, tileSprites[effect.tile])
			local rectSize, offset = piece.ImageRectSize, piece.ImageRectOffset
			local half = Vector2.new(math.floor(rectSize.X / 2), math.floor(rectSize.Y / 2))
			piece.ImageRectOffset = offset + Vector2.new((index - 1) % 2 * half.X, math.floor((index - 1) / 2) * half.Y)
			piece.ImageRectSize = half
			-- Restore the full crop on the next pooled use before splitting it again.
			mapSpriteNames[piece] = nil
		end
	end
end

local function updateBoard()
	updateFeedback()
	board.Ground.Image = state.stage == 1 and mapImages.garden or mapImages.courtyard
	if phaseArt then
		board.Ground.Image = state.stage == 1 and phaseArt.entrance or phaseArt.courtyard
		for index = 1, 3 do
			setMapSprite(board.Decorations["Flower_" .. index], state.stage == 1 and "blueFlowers" or nil)
		end
		setMapSprite(board.Decorations.Ribbon, state.stage == 2 and "goldRibbon" or nil)
		for index = 1, 4 do
			setMapSprite(board.Decorations["Sun_" .. index], state.stage == 2 and "sunStatue" or nil)
			board.Decorations["Sun_" .. index].ZIndex = SpriteLayout.depth(index <= 2 and 5 or 7, definition.height) + 2
		end
		board.SealWires.Visible = state.chest ~= nil and not state.chestUnlocked
		board.Chest.Visible = state.chest ~= nil
		if state.chest then
			local chest = state.chest
			board.Chest.Position = UDim2.fromScale(chest.x / definition.width, chest.y / definition.height)
			local collected = state.mode == "won"
			local name = collected and "chestOpen" or "chestClosed"
			setMapSprite(board.Chest.Sprite, name)
			local rect = phaseArt.frames[name]
			board.Chest.Sprite.AnchorPoint = Vector2.new(0.5, 1)
			board.Chest.Sprite.Position = UDim2.fromScale(0.5, 1)
			board.Chest.Sprite.Size = UDim2.fromScale(rect[3] / 304, rect[4] / 304 * 1.5)
			board.Chest.Sprite.ZIndex = SpriteLayout.depth(chest.y + chest.height, definition.height) + 2
			board.Chest.Seal.Text = state.chestUnlocked and "OPEN THE CHEST"
				or string.format("SUN SEAL %d/%d", state.energy, state.totalEnergy)
			board.Chest.SunKey.Visible = collected
			setMapSprite(board.Chest.SunKey, collected and "sunKey" or nil)
			for index, x in ipairs({ 4, 12 }) do
				local wire = board.SealWires["Wire_" .. index]
				local size = board.AbsoluteSize
				local from = Vector2.new((x - 0.5) / definition.width * size.X, 2.5 / definition.height * size.Y)
				local to = Vector2.new(7.5 / definition.width * size.X, 5.5 / definition.height * size.Y)
				local delta = to - from
				wire.AnchorPoint = Vector2.new(0.5, 0.5)
				local midpoint = (from + to) * 0.5
				wire.Position = UDim2.fromOffset(midpoint.X, midpoint.Y)
				wire.Size = UDim2.fromOffset(delta.Magnitude, 3)
				wire.Rotation = math.deg(math.atan2(delta.Y, delta.X))
				wire.BackgroundTransparency = state.tiles[x .. ":3"] and 0.65 or 0.15
			end
		end
	end
	board.Exit.Visible = state.exitX > 0
	board.Exit.Position = UDim2.fromScale((state.exitX - 1) / definition.width, (state.exitY - 1) / definition.height)
	local exitOpen = state.energy == state.totalEnergy
	board.Exit.Glow.Visible = exitOpen
	board.Exit.Pointer.Visible = exitOpen
	board.Exit.OpenLabel.Visible = exitOpen
	setMapSprite(board.Exit.Gate, exitOpen and "exitOpen" or "exitClosed")
	setMapSprite(board.Exit.Sparkle, exitOpen and "sparkle" or nil)
	board.Exit.Remaining.Visible = not exitOpen
	board.Exit.Remaining.Text = tostring(state.totalEnergy - state.energy)
	if exitOpen and previousState and previousState.energy ~= previousState.totalEnergy then
		board.Exit.Gate.ImageTransparency = 0.4
		TweenService:Create(board.Exit.Gate, TweenInfo.new(0.35), { ImageTransparency = 0 }):Play()
	end
	for y = 1, definition.height do
		for x = 1, definition.width do
			local cell = x .. ":" .. y
			local tile = board["Cell_" .. x .. "_" .. y]
			local object = state.tiles[cell]
			setMapSprite(tile.Object, tileSprites[object])
			setMapSprite(tile.Item, state.items[cell])
			tile.ItemGlow.Visible = state.items[cell] ~= nil
			if not state.items[cell] then
				itemReveals[cell] = nil
			end
			setMapSprite(tile.Bomb, state.bombs[cell] and "bomb" or nil)
			local parts = BlastVisual.parts(state, x, y)
			tile.Blast.Visible = parts ~= nil
			for _, name in ipairs({ "Up", "Right", "Down", "Left", "Core" }) do
				setMapSprite(tile.Blast[name], parts and parts[name] or nil)
			end
			tile.Object.ZIndex = SpriteLayout.depth(y, definition.height) + 2
		end
	end
	for index = 1, enemySlots do
		local enemy = state.enemies[index]
		if phaseArt and previousState and previousState.revision == state.revision then
			local previous = previousState.enemies[index]
			if enemy and enemy.retired and previous and previous.alive then
				local x, y = ActorMotion.position(previous, state.time)
				retireSmoke[index] = { at = os.clock(), x = x, y = y }
			end
		end
		local view = board["Enemy_" .. index]
		local name = enemy and enemy.alive and "enemy" or nil
		if name and phaseArt then
			name = enemy.kind .. "_" .. enemy.direction
		end
		setMapSprite(view, name)
	end
	board.Frog.Size = board.Hero.Size
	local exitDepth = SpriteLayout.depth(state.exitY, definition.height)
	board.Exit.Gate.ZIndex = exitOpen and 35 or exitDepth + 2
	board.Exit.Sparkle.ZIndex = exitOpen and 35 or exitDepth + 2
	board.Exit.Remaining.ZIndex = exitDepth + 2
	board.Frog.Visible = false
	board.Hero.Vector.LeftEye.Visible = state.direction ~= "up"
	board.Hero.Vector.RightEye.Visible = state.direction ~= "up"
	board.Hero.Vector.Smile.Visible = state.direction ~= "up"
	board.Hero.Vector.Belly.Visible = state.direction ~= "up"
	board.Hero.Visible = state.mode ~= "dead"
	board.Frog.Visible = false
end

local function setSprite(view, kind, animation, direction, time)
	local frame, atlasId = spriteAnimation:select(view, state.skinPack, kind, animation, direction, time)
	local imageId = images[atlasId]
	local enabled = imageId ~= ""
	view.Sprite.Visible = enabled
	view.Vector.Visible = not enabled
	if not enabled then
		return
	end
	local atlas = catalog.atlases[atlasId]
	local width, height, x, y = SpriteLayout.frame(frame, kind, state.frog, direction)
	view.Sprite.ScaleType = Enum.ScaleType.Stretch
	view.Sprite.Size = UDim2.fromScale(width, height)
	view.Sprite.Position = UDim2.fromScale(x, y)
	local deliveredSize = images.imageSizes[atlasId]
	local scaleX = deliveredSize[1] / atlas.imageSize[1]
	local scaleY = deliveredSize[2] / atlas.imageSize[2]
	local left = math.round(frame.rect[1] * scaleX)
	local top = math.round(frame.rect[2] * scaleY)
	local right = math.round((frame.rect[1] + frame.rect[3]) * scaleX)
	local bottom = math.round((frame.rect[2] + frame.rect[4]) * scaleY)
	view.Sprite.Image = imageId
	view.Sprite.ImageRectOffset = Vector2.new(left, top)
	view.Sprite.ImageRectSize = Vector2.new(right - left, bottom - top)
end

if phaseArt then
	ui.ChestReveal.Panel.Skip.Activated:Connect(function()
		revealUntil = 0
		ui.ChestReveal.Visible = false
		ui.ResultOverlay.Visible = state and state.mode == "won"
	end)
end

remotes.State.OnClientEvent:Connect(function(nextState)
	if nextState.error then
		ui.ErrorOverlay.Visible = true
		ui.ErrorOverlay.Panel.Detail.Text = nextState.error
		ui.Status.Mount.Text = "Progress unavailable"
		ui.Status.Coins.Text = ""
		releaseInputs()
		return
	end
	previousState, state = state, nextState
	playerPrediction:receive(state, os.clock())
	campFeedback:update(state, previousState)
	ui.Enabled = state.location == "adventure"
	lobby:update(state)
	if
		not previousState
		or previousState.settings.leftHanded ~= state.settings.leftHanded
		or previousState.settings.controlsOpacity ~= state.settings.controlsOpacity
		or previousState.settings.largeText ~= state.settings.largeText
	then
		applyAuthoredLayout()
	end
	stateReceivedAt = os.clock()
	ui.Header.Stage.Text = definition.stages[state.stage].name:upper()
	ui.Header.Energy.Text =
		string.format(wideLayout and "ENERGY %d/%d" or "ENERGY\n%d/%d", state.energy, state.totalEnergy)
	ui.Header.Stats.Text = Feedback.stats(state, ui.AbsoluteSize.X < 600)
	ui.Hint.Text = hint()
	if state.chest then
		if state.mode == "claiming" then
			ui.Hint.Text = "Saving your Sun Key... " .. (state.saveStatus or "")
		elseif state.canInteractChest then
			ui.Hint.Text = "Open the chest • E / X / OPEN"
		elseif state.chestUnlocked then
			ui.Hint.Text = "The Sun Chest is ready. Approach any clear side."
		end
	end
	ui.Controls.Bomb.Text = state.canInteractChest and "OPEN" or state.mode == "claiming" and "SAVING" or "BOMB"
	ui.Status.Mount.Text = Feedback.mount(state)
	ui.Status.Mount.TextColor3 = state.frog and Color3.fromRGB(133, 242, 215) or Color3.fromRGB(255, 244, 221)
	ui.Status.Coins.Text = string.format("COINS %d", state.coins)
	ui.PauseOverlay.Panel.Save.Text = Feedback.saveMessage(state)
	ui.PauseOverlay.Panel.Camp.Visible = state.lobbyUnlocked
	ui.PauseOverlay.Visible = state.paused and state.mode ~= "won"
	if not ui.PauseOverlay.Visible then
		ui.PauseOverlay.Panel.Restart.Text = "RESTART STAGE"
	end
	ui.Death.Visible = state.mode == "dead"
	if phaseArt and state.mode == "won" and (not previousState or previousState.mode ~= "won") then
		revealUntil = os.clock() + 2.2
		setMapSprite(ui.ChestReveal.Panel.Key, "sunKey")
		local newKey = not previousState or not previousState.phaseKeys[definition.keyId]
		setMapSprite(ui.ChestReveal.Panel.Coins, newKey and "coins" or nil)
		ui.ChestReveal.Panel.Detail.Text = newKey and "World 1 • Sun Key 1/4\n+20 coins • Reward saved."
			or "World 1 • Sun Key already owned\nNo duplicate rewards."
	end
	if phaseArt then
		ui.ChestReveal.Visible = state.mode == "won" and os.clock() < revealUntil
	end
	ui.ResultOverlay.Visible = state.mode == "won" and os.clock() >= revealUntil
	ui.ResultOverlay.Panel.Title.Text = definition.phaseName:upper() .. " COMPLETE!"
	ui.ResultOverlay.Panel.Camp.Text = "CAMP"
	ui.ResultOverlay.Panel.Detail.Text = string.format(
		"Completion: earned\nExploration: %s\nNo deaths: %s\nCoins: %d | Frog collection: %s\n%s",
		state.secret and "earned" or "find the cracked crate",
		state.noDeathsMedal and "earned" or "try again",
		state.coins,
		state.frogUnlocked and "unlocked" or "not rescued",
		Feedback.saveMessage(state)
	)
	if phaseArt then
		local secrets = 0
		for _, stage in ipairs(definition.stages) do
			if state.phaseSecrets[stage.secretId] then
				secrets += 1
			end
		end
		ui.ResultOverlay.Panel.Detail.Text = string.format(
			"Sun Key: saved • World 1: 1/4\nSecrets: %d/2\nNo deaths: %s\nCoins: %d • Pond Frog: %s\n%s",
			secrets,
			state.noDeathsMedal and "earned" or "try again",
			state.coins,
			state.frogUnlocked and "rescued" or "not rescued",
			Feedback.saveMessage(state)
		)
	end
	updateBoard()
	if
		state.location == "lobby"
		or state.paused
		or state.mode ~= "playing"
		or (previousState and state.revision ~= previousState.revision)
	then
		releaseInputs()
	end
end)

local layerOffsets = {}
local function actorLayer(view, base)
	if not layerOffsets[view] then
		local offsets = {}
		local lowest = math.huge
		for _, child in ipairs(view.Vector:GetDescendants()) do
			if child:IsA("GuiObject") then
				lowest = math.min(lowest, child.ZIndex)
			end
		end
		lowest = math.min(lowest, view.Vector.ZIndex)
		offsets[view.Vector] = view.Vector.ZIndex - lowest
		for _, child in ipairs(view.Vector:GetDescendants()) do
			if child:IsA("GuiObject") then
				offsets[child] = child.ZIndex - lowest
			end
		end
		layerOffsets[view] = offsets
	end
	view.ZIndex, view.Sprite.ZIndex = base, base
	for child, offset in pairs(layerOffsets[view]) do
		child.ZIndex = base + math.min(offset, 1)
	end
end

RunService.RenderStepped:Connect(function()
	if not state or state.location ~= "adventure" then
		return
	end
	if phaseArt and state.mode == "won" and ui.ChestReveal.Visible and os.clock() >= revealUntil then
		ui.ChestReveal.Visible = false
		ui.ResultOverlay.Visible = true
	end
	if phaseArt then
		for index = 1, enemySlots do
			local smoke = retireSmoke[index]
			local view = board.RetireSmoke["Smoke_" .. index]
			local age = smoke and (os.clock() - smoke.at) / 0.6 or 2
			view.Visible = age < 1
			if age < 1 then
				view.Position = UDim2.fromScale(
					(smoke.x - 0.95) / definition.width,
					(smoke.y - 0.6 - age * 0.35) / definition.height
				)
				for _, puff in ipairs(view:GetChildren()) do
					if puff:IsA("Frame") then
						puff.BackgroundTransparency = 0.2 + age * 0.8
					end
				end
			end
		end
	end
	if
		pendingAnalogInput and os.clock() - lastRefresh >= 0.05
		or os.clock() - lastRefresh > 0.35 and (currentDirection[1] ~= 0 or currentDirection[2] ~= 0)
	then
		lastRefresh = os.clock()
		remotes.Input:FireServer("move", currentDirection)
		pendingAnalogInput = false
	end
	-- Bounded extrapolation of the same simulation trajectory; freeze on pause/death.
	local renderTime = state.time
	if not state.paused and state.mode == "playing" then
		renderTime += math.min(os.clock() - stateReceivedAt, 0.05)
	end
	local playerX, playerY = playerPrediction:advance(
		state,
		os.clock(),
		not state.paused and state.mode == "playing" and os.clock() - stateReceivedAt < 0.15
	)
	local visualDirection = PlayerMovement.facing(currentDirection[1], currentDirection[2], state.direction)
	local moving = not state.paused and (currentDirection[1] ~= 0 or currentDirection[2] ~= 0)
	local animation = moving and "walk" or "idle"
	for index, effect in pairs(effects) do
		local view = board.Effects[string.format("Destroy_%02d", index)]
		local age = renderTime - effect.at
		if age >= Feedback.duration or state.settings.reducedEffects then
			view.Visible = false
			effects[index] = nil
		else
			view.Impact.ImageTransparency = math.clamp(age / 0.15, 0, 1)
			for pieceIndex = 1, 4 do
				local pose = Feedback.fragment(pieceIndex, age)
				local piece = view["Piece_" .. pieceIndex]
				piece.Position = UDim2.fromScale(pose.x, pose.y)
				piece.Size = UDim2.fromScale(pose.size, pose.size)
				piece.Rotation = pose.rotation
				piece.ImageTransparency = pose.transparency
			end
		end
	end
	if board.Exit.Glow.Visible and not state.settings.reducedEffects then
		board.Exit.Glow.BackgroundTransparency = 0.75 + math.sin(renderTime * 4) * 0.1
		board.Exit.Pointer.Position = UDim2.fromScale(0.5, -0.25 + math.sin(renderTime * 4) * 0.025)
	end
	local origin = UDim2.fromScale((playerX - 1) / definition.width, (playerY - 1) / definition.height)
	board.Hero.Position, board.Frog.Position = origin, origin
	local depth = SpriteLayout.depth(playerY, definition.height)
	board.PlayerShadow.Visible = state.mode ~= "dead"
	board.PlayerShadow.Position =
		UDim2.fromScale((playerX - 0.5) / definition.width, (playerY - 0.18) / definition.height)
	board.PlayerShadow.Size =
		UDim2.fromScale((state.frog and 0.78 or 0.54) / definition.width, 0.18 / definition.height)
	board.PlayerShadow.ZIndex = depth - 1
	actorLayer(board.Frog, depth)
	actorLayer(board.Hero, depth + 1)
	-- Match vector fallback to the same support point, including the rider's seat.
	local seat = state.frog and SpriteLayout.seats[visualDirection] or SpriteLayout.ground
	board.Hero.Vector.Position = UDim2.fromScale(seat[1] - 0.38, seat[2] - 0.7875)
	board.Frog.Vector.Position = UDim2.fromScale(0.12, 0.0325)
	debugOverlay:enable(RunService:IsStudio() and ui:GetAttribute("ArenaDebug") == true)
	debugOverlay:obstacles(state)
	local cellX, cellY = ActorMotion.cell(state, renderTime)
	debugOverlay:actor("Player", playerX, playerY, cellX, cellY, state.mode ~= "dead")
	for index = 1, enemySlots do
		local enemy = state.enemies[index]
		local view = board["Enemy_" .. index]
		local shadow = board["EnemyShadow_" .. index]
		shadow.Visible = enemy ~= nil and enemy.alive
		if enemy then
			local enemyX, enemyY = ActorMotion.position(enemy, renderTime)
			view.AnchorPoint = Vector2.new(0.5, 1)
			view.Position = UDim2.fromScale((enemyX - 0.5) / definition.width, (enemyY - 0.18) / definition.height)
			view.Size = UDim2.fromScale(0.8 / definition.width, (0.8 * 182 / 244) / definition.height)
			if phaseArt and enemy.alive then
				local name = enemy.kind .. "_" .. enemy.direction
				setMapSprite(view, name)
				local rect = phaseArt.frames[name]
				view.Size = UDim2.fromScale(rect[3] * 0.003 / definition.width, rect[4] * 0.003 / definition.height)
			end
			view.ZIndex = SpriteLayout.depth(enemyY, definition.height) + 1
			shadow.Position = UDim2.fromScale((enemyX - 0.5) / definition.width, (enemyY - 0.18) / definition.height)
			shadow.ZIndex = SpriteLayout.depth(enemyY, definition.height) - 1
			local enemyCellX, enemyCellY = ActorMotion.cell(enemy, renderTime)
			debugOverlay:actor("Enemy" .. index, enemyX, enemyY, enemyCellX, enemyCellY, enemy.alive)
		else
			debugOverlay:actor("Enemy" .. index, 1, 1, 1, 1, false)
		end
	end
	setSprite(board.Hero, state.frog and "mounted" or "hero", animation, visualDirection, renderTime)
	setSprite(board.Frog, "frog", animation, visualDirection, renderTime)
	ui.Status.FrogIcon.Image = board.Frog.Sprite.Image
	ui.Status.FrogIcon.ImageRectOffset = board.Frog.Sprite.ImageRectOffset
	ui.Status.FrogIcon.ImageRectSize = board.Frog.Sprite.ImageRectSize
	ui.Status.FrogIcon.Visible = board.Frog.Sprite.Image ~= ""
	ui.Status.FrogIcon.ImageTransparency = state.frog and 0 or 0.65
	if board.Exit.Sparkle.Visible and not state.settings.reducedEffects then
		board.Exit.Sparkle.Rotation = state.time * 70 % 360
		board.Exit.Sparkle.ImageTransparency = 0.15 + math.sin(state.time * 4) * 0.1
	end
	board.Hero.Vector.BackgroundTransparency = state.invulnerable and (math.floor(state.time * 10) % 2) * 0.35 or 0
	for y = 1, definition.height do
		for x = 1, definition.width do
			local cell = x .. ":" .. y
			local activeBomb = state.bombs[cell]
			if state.items[cell] then
				local tile = board["Cell_" .. x .. "_" .. y]
				local pose = Feedback.item(itemReveals[cell] and renderTime - itemReveals[cell] or 0.5)
				tile.Item.Size = UDim2.fromScale(pose.size, pose.size)
				tile.Item.Position = UDim2.fromScale((1 - pose.size) / 2, pose.y - pose.size / 2)
				tile.ItemGlow.BackgroundTransparency = pose.glow
			end
			if activeBomb then
				local pulse = math.sin(state.time * (8 + 10 / math.max(activeBomb.at - state.time, 0.1)))
				board["Cell_" .. x .. "_" .. y].Bomb.ImageColor3 = pulse > 0 and Color3.fromRGB(255, 205, 160)
					or Color3.fromRGB(255, 255, 255)
			end
		end
	end
end)

remotes.Input:FireServer("ready")
