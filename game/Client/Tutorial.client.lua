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
local mapImages = require(ReplicatedStorage.Shared.MapImages)
local mapCatalog = require(ReplicatedStorage.Shared.MapCatalog)
local ui = assets:WaitForChild("TutorialUI"):Clone()
ui.Parent = player:WaitForChild("PlayerGui")
local board = ui.PlayArea.Board
local state, previousState = nil, nil
local held = {}
local inputOrder = 0
local currentDirection = "stop"
local lastRefresh = 0
local moveTween, frogTween = nil, nil
local gamepadDirection = nil
local campView = false

local function applyAuthoredLayout()
	local size = ui.AbsoluteSize
	local compact = size.X > size.Y * 1.4 and size.Y < 550
	local layout = assets:WaitForChild(compact and "TutorialCompactUI" or "TutorialUI")
	for _, name in ipairs({ "Header", "Hint", "PlayArea", "Controls" }) do
		ui[name].Size = layout[name].Size
		ui[name].Position = layout[name].Position
	end
	for _, name in ipairs({ "Up", "Left", "Down", "Right", "Bomb" }) do
		ui.Controls[name].Size = layout.Controls[name].Size
		ui.Controls[name].Position = layout.Controls[name].Position
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
	if state and (state.paused or state.mode ~= "playing") then
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
	if state and not state.paused and state.mode == "playing" then
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
	campView = false
	releaseInputs()
	remotes.Input:FireServer("replay")
end)
ui.ResultOverlay.Panel.Camp.Activated:Connect(function()
	campView = not campView
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then
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
		return "Exit open! Follow the glowing arrow."
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

local function blastSprite(x, y)
	if not state.blasts[x .. ":" .. y] then
		return nil
	end
	local horizontal = state.blasts[(x - 1) .. ":" .. y] or state.blasts[(x + 1) .. ":" .. y]
	local vertical = state.blasts[x .. ":" .. (y - 1)] or state.blasts[x .. ":" .. (y + 1)]
	return horizontal and vertical and "blastCore"
		or horizontal and "blastHorizontal"
		or vertical and "blastVertical"
		or "blastCore"
end

local function updateBoard()
	board.Ground.Image = state.stage == 1 and mapImages.garden or mapImages.courtyard
	board.Exit.Position = UDim2.fromScale((state.exitX - 1) / definition.width, (state.exitY - 1) / definition.height)
	local exitOpen = state.energy == state.totalEnergy
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
			setMapSprite(tile.Bomb, state.bombs[cell] and "bomb" or nil)
			setMapSprite(tile.Blast, blastSprite(x, y))
		end
	end
	for index = 1, 4 do
		local enemy = state.enemies[index]
		local view = board["Enemy_" .. index]
		setMapSprite(view, enemy and enemy.alive and "enemy" or nil)
		if enemy then
			view.Position = UDim2.fromScale((enemy.x - 0.85) / definition.width, (enemy.y - 0.85) / definition.height)
		end
	end
	local target = UDim2.fromScale((state.x - 1) / definition.width, (state.y - 1) / definition.height)
	local frogTarget = UDim2.fromScale((state.x - 1.075) / definition.width, (state.y - 0.8) / definition.height)
	local changedStage = not previousState or previousState.revision ~= state.revision
	local moved = not previousState or previousState.x ~= state.x or previousState.y ~= state.y
	if changedStage or moved then
		if moveTween then
			moveTween:Cancel()
			frogTween:Cancel()
		end
		if changedStage then
			board.Hero.Position, board.Frog.Position = target, frogTarget
		else
			moveTween = TweenService:Create(
				board.Hero,
				TweenInfo.new(definition.moveInterval * 0.75, Enum.EasingStyle.Linear),
				{ Position = target }
			)
			frogTween = TweenService:Create(
				board.Frog,
				TweenInfo.new(definition.moveInterval * 0.75, Enum.EasingStyle.Linear),
				{ Position = frogTarget }
			)
			moveTween:Play()
			frogTween:Play()
		end
	end
	board.Frog.Visible = state.frog
	board.Hero.Vector.LeftEye.Visible = state.direction ~= "up"
	board.Hero.Vector.RightEye.Visible = state.direction ~= "up"
	board.Hero.Vector.Smile.Visible = state.direction ~= "up"
	board.Hero.Vector.Belly.Visible = state.direction ~= "up"
	board.Hero.Visible = state.mode ~= "dead"
end

local function setSprite(view, kind, animation, direction)
	local sequence = catalog.animations[kind][animation][direction]
	if not sequence then
		sequence = catalog.animations[kind].idle[direction]
	end
	local atlasId, row, first, last = unpack(sequence)
	local imageId = images[atlasId]
	local enabled = imageId ~= ""
	view.Sprite.Visible = enabled
	view.Vector.Visible = not enabled
	if not enabled then
		return
	end
	local column = first + math.floor(state.time * 8) % (last - first + 1)
	local atlas = catalog.atlases[atlasId]
	local frame = atlas.frames[row * 8 + column + 1]
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
		ui.Status.Text = "Progress unavailable"
		releaseInputs()
		return
	end
	previousState, state = state, nextState
	ui.Header.Stage.Text = definition.stages[state.stage].name:upper()
	ui.Header.Energy.Text = string.format("ENERGY %d/%d", state.energy, state.totalEnergy)
	ui.Header.Stats.Text = string.format("B %d | R %d", state.capacity, state.range)
	ui.Hint.Text = hint()
	ui.Status.Text = string.format(
		"%s  |  Coins %d  |  %s",
		state.frog and "Frog shield" or "No shield",
		state.coins,
		state.saveStatus
	)
	ui.PauseOverlay.Visible = state.paused and state.mode ~= "won"
	if not ui.PauseOverlay.Visible then
		ui.PauseOverlay.Panel.Restart.Text = "RESTART STAGE"
	end
	ui.Death.Visible = state.mode == "dead"
	ui.ResultOverlay.Visible = state.mode == "won"
	ui.ResultOverlay.Panel.Title.Text = campView and "YOUR REWARDS" or "TUTORIAL COMPLETE!"
	ui.ResultOverlay.Panel.Detail.Text = string.format(
		"Completion: earned\nExploration: %s\nNo deaths: %s\nCoins: %d | Frog collection: %s\n%s",
		state.secret and "earned" or "find the cracked crate",
		state.noDeathsMedal and "earned" or "try again",
		state.coins,
		state.frogUnlocked and "unlocked" or "not rescued",
		state.saveStatus
	)
	updateBoard()
	if state.paused or state.mode ~= "playing" or (previousState and state.revision ~= previousState.revision) then
		releaseInputs()
	end
end)

RunService.RenderStepped:Connect(function()
	if not state then
		return
	end
	if os.clock() - lastRefresh > 0.35 and currentDirection ~= "stop" then
		lastRefresh = os.clock()
		remotes.Input:FireServer("move", currentDirection)
	end
	local animation = currentDirection == "stop" and "idle" or "walk"
	setSprite(board.Hero, "hero", state.frog and "mounted" or animation, state.direction)
	setSprite(board.Frog, "frog", animation, state.direction)
	if board.Exit.Sparkle.Visible then
		board.Exit.Sparkle.Rotation = state.time * 70 % 360
		board.Exit.Sparkle.ImageTransparency = 0.15 + math.sin(state.time * 4) * 0.1
	end
	board.Hero.Vector.BackgroundTransparency = state.invulnerable and (math.floor(state.time * 10) % 2) * 0.35 or 0
	for y = 1, definition.height do
		for x = 1, definition.width do
			local cell = x .. ":" .. y
			local activeBomb = state.bombs[cell]
			if activeBomb then
				local pulse = math.sin(state.time * (8 + 10 / math.max(activeBomb.at - state.time, 0.1)))
				board["Cell_" .. x .. "_" .. y].Bomb.ImageColor3 = pulse > 0 and Color3.fromRGB(255, 205, 160)
					or Color3.fromRGB(255, 255, 255)
			end
		end
	end
end)

remotes.Input:FireServer("ready")
