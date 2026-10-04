local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

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
local ActorMotion = require(ReplicatedStorage.Shared.ActorMotion)
local SpriteLayout = require(ReplicatedStorage.Shared.SpriteLayout)
local SkinPacks = require(ReplicatedStorage.Shared.SkinPacks)
local BlastVisual = require(ReplicatedStorage.Shared.BlastVisual)
local Feedback = require(ReplicatedStorage.Shared.FeedbackPresentation)
local ArenaLayout = require(ReplicatedStorage.Shared.ArenaLayout)
local Preferences = require(script.Parent.Preferences)
local ui = assets:WaitForChild("TutorialUI"):Clone()
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
local currentDirection = "stop"
local lastRefresh = 0
local stateReceivedAt = os.clock()
local gamepadDirection = nil
local wideLayout = false

local function applyAuthoredLayout()
	local size = ui.AbsoluteSize
	if size.X < 1 or size.Y < 1 then
		return
	end
	local geometry = ArenaLayout.compute(size.X, size.Y)
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
			ui.Header[name].Position = assets.TutorialUI.Header[name].Position
			ui.Header[name].Size = assets.TutorialUI.Header[name].Size
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
	local direction, order = gamepadDirection or "stop", 0
	for _, value in pairs(held) do
		if value.order > order then
			direction, order = value.direction, value.order
		end
	end
	if state and (state.location == "lobby" or state.paused or state.mode ~= "playing") then
		direction = "stop"
	end
	if direction ~= currentDirection then
		currentDirection = direction
		remotes.Input:FireServer("move", direction)
		lastRefresh = os.clock()
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
		remotes.Input:FireServer("bomb")
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
		if math.max(math.abs(vector.X), math.abs(vector.Y)) < 0.35 then
			gamepadDirection = nil
		elseif math.abs(vector.X) > math.abs(vector.Y) then
			gamepadDirection = vector.X > 0 and "right" or "left"
		else
			gamepadDirection = vector.Y > 0 and "up" or "down"
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
		return "Destroy the glowing energy crates to open the exit."
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
	local rect = mapCatalog.frames[name]
	local scaleX = mapImages.atlasSize[1] / mapCatalog.imageSize[1]
	local scaleY = mapImages.atlasSize[2] / mapCatalog.imageSize[2]
	local left, top = math.round(rect[1] * scaleX), math.round(rect[2] * scaleY)
	local right = math.round((rect[1] + rect[3]) * scaleX)
	local bottom = math.round((rect[2] + rect[4]) * scaleY)
	view.Image = mapImages.atlas
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
			tile.Object.ZIndex = SpriteLayout.depth(y) + 2
		end
	end
	for index = 1, 4 do
		local enemy = state.enemies[index]
		local view = board["Enemy_" .. index]
		setMapSprite(view, enemy and enemy.alive and "enemy" or nil)
	end
	board.Frog.Size = board.Hero.Size
	local exitDepth = SpriteLayout.depth(state.exitY)
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

local function setSprite(view, kind, animation, direction)
	local sequence = catalog.animations[kind][animation][direction]
	if not sequence then
		sequence = catalog.animations[kind].idle[direction]
	end
	local atlasId, row, first, last = unpack(sequence)
	atlasId = SkinPacks.atlas(state.skinPack, kind, atlasId)
	local imageId = images[atlasId]
	local enabled = imageId ~= ""
	view.Sprite.Visible = enabled
	view.Vector.Visible = not enabled
	if not enabled then
		return
	end
	local column = first + math.floor(state.time * 8) % (last - first + 1)
	local atlas = catalog.atlases[atlasId]
	local frame = atlas.frames[row * atlas.columns + column + 1]
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
	ui.ResultOverlay.Visible = state.mode == "won"
	ui.ResultOverlay.Panel.Title.Text = "FIRST SPARK COMPLETE!"
	ui.ResultOverlay.Panel.Camp.Text = "CAMP"
	ui.ResultOverlay.Panel.Detail.Text = string.format(
		"Completion: earned\nExploration: %s\nNo deaths: %s\nCoins: %d | Frog collection: %s\n%s",
		state.secret and "earned" or "find the cracked crate",
		state.noDeathsMedal and "earned" or "try again",
		state.coins,
		state.frogUnlocked and "unlocked" or "not rescued",
		Feedback.saveMessage(state)
	)
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
	if os.clock() - lastRefresh > 0.35 and currentDirection ~= "stop" then
		lastRefresh = os.clock()
		remotes.Input:FireServer("move", currentDirection)
	end
	-- Bounded extrapolation of the same simulation trajectory; freeze on pause/death.
	local renderTime = state.time
	if not state.paused and state.mode == "playing" then
		renderTime += math.min(os.clock() - stateReceivedAt, 0.05)
	end
	local moving = state.motion and renderTime < state.motion.at + state.motion.duration
	local animation = moving and "walk" or "idle"
	local playerX, playerY = ActorMotion.position(state, renderTime)
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
	local depth = SpriteLayout.depth(playerY)
	board.PlayerShadow.Visible = state.mode ~= "dead"
	board.PlayerShadow.Position =
		UDim2.fromScale((playerX - 0.5) / definition.width, (playerY - 0.18) / definition.height)
	board.PlayerShadow.Size =
		UDim2.fromScale((state.frog and 0.78 or 0.54) / definition.width, 0.18 / definition.height)
	board.PlayerShadow.ZIndex = depth - 1
	actorLayer(board.Frog, depth)
	actorLayer(board.Hero, depth + 1)
	-- Match vector fallback to the same support point, including the rider's seat.
	local seat = state.frog and SpriteLayout.seats[state.direction] or SpriteLayout.ground
	board.Hero.Vector.Position = UDim2.fromScale(seat[1] - 0.38, seat[2] - 0.7875)
	board.Frog.Vector.Position = UDim2.fromScale(0.12, 0.0325)
	debugOverlay:enable(RunService:IsStudio() and ui:GetAttribute("ArenaDebug") == true)
	debugOverlay:obstacles(state)
	local cellX, cellY = ActorMotion.cell(state, renderTime)
	debugOverlay:actor("Player", playerX, playerY, cellX, cellY, state.mode ~= "dead")
	for index = 1, 4 do
		local enemy = state.enemies[index]
		local view = board["Enemy_" .. index]
		local shadow = board["EnemyShadow_" .. index]
		shadow.Visible = enemy ~= nil and enemy.alive
		if enemy then
			local enemyX, enemyY = ActorMotion.position(enemy, renderTime)
			view.AnchorPoint = Vector2.new(0.5, 1)
			view.Position = UDim2.fromScale((enemyX - 0.5) / definition.width, (enemyY - 0.18) / definition.height)
			view.Size = UDim2.fromScale(0.8 / definition.width, (0.8 * 182 / 244) / definition.height)
			view.ZIndex = SpriteLayout.depth(enemyY) + 1
			shadow.Position = UDim2.fromScale((enemyX - 0.5) / definition.width, (enemyY - 0.18) / definition.height)
			shadow.ZIndex = SpriteLayout.depth(enemyY) - 1
			local enemyCellX, enemyCellY = ActorMotion.cell(enemy, renderTime)
			debugOverlay:actor("Enemy" .. index, enemyX, enemyY, enemyCellX, enemyCellY, enemy.alive)
		else
			debugOverlay:actor("Enemy" .. index, 1, 1, 1, 1, false)
		end
	end
	setSprite(board.Hero, state.frog and "mounted" or "hero", animation, state.direction)
	setSprite(board.Frog, "frog", animation, state.direction)
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
