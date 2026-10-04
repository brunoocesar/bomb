local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Shared = ReplicatedStorage.Shared
local Layout = require(Shared.LobbyLayout)
local Progress = require(Shared.LobbyProgress)
local Art = require(Shared.LobbyArt)
local Images = require(Shared.LobbyImages)
local Catalog = require(Shared.SpriteCatalog)
local SpriteImages = require(Shared.SpriteImages)
local Packs = require(Shared.SkinPacks)
local Tutorial = require(Shared.Tutorial)
local MapImages = require(Shared.MapImages)
local Preferences = require(script.Parent.Preferences)

local Controller = {}
Controller.__index = Controller
local directions = { "down", "left", "up", "right" }
local navNames = { "Adventure", "Character", "Frogs", "Shop" }
local canvasHeights =
	{ Adventure = 412, Character = 428, Frogs = 448, Shop = 484, Missions = 588, Profile = 472, Settings = 624 }

local function place(view, rect)
	view.Position = UDim2.fromOffset(rect[1], rect[2])
	view.Size = UDim2.fromOffset(rect[3], rect[4])
end

local function icon(view, number)
	local rect = Art.frames[number]
	local sx, sy = Images.iconSize[1] / Art.sourceSize[1], Images.iconSize[2] / Art.sourceSize[2]
	local x, y = math.round(rect[1] * sx), math.round(rect[2] * sy)
	view.Image = Images.icons
	view.ImageRectOffset = Vector2.new(x, y)
	view.ImageRectSize = Vector2.new(math.round((rect[1] + rect[3]) * sx) - x, math.round((rect[2] + rect[4]) * sy) - y)
end

local function sprite(view, pack, kind, animation, direction, time)
	local sequence = Catalog.animations[kind][animation][direction]
	local atlasId = Packs.atlas(pack, kind, sequence[1])
	local atlas = Catalog.atlases[atlasId]
	local column = sequence[3] + math.floor(time * 5) % (sequence[4] - sequence[3] + 1)
	local frame = atlas.frames[sequence[2] * atlas.columns + column + 1]
	local size = SpriteImages.imageSizes[atlasId]
	local sx, sy = size[1] / atlas.imageSize[1], size[2] / atlas.imageSize[2]
	local rect = frame.rect
	local x, y = math.round(rect[1] * sx), math.round(rect[2] * sy)
	view.Image = SpriteImages[atlasId]
	view.ImageRectOffset = Vector2.new(x, y)
	view.ImageRectSize = Vector2.new(math.round((rect[1] + rect[3]) * sx) - x, math.round((rect[2] + rect[4]) * sy) - y)
	return frame
end

function Controller.new(player, assets, remotes)
	local self = setmetatable({
		player = player,
		remotes = remotes,
		state = nil,
		direction = 1,
		panel = nil,
		mounted = nil,
		time = 0,
		selectedTrail = 1,
		connections = {},
	}, Controller)
	self.ui = assets.LobbyUI:Clone()
	self.ui.Parent = player:WaitForChild("PlayerGui")
	self.ui.Background.Image = Images.background
	self.ui.Next.Art.Image = MapImages.garden
	self.ui.Panel.Content.Adventure.Map.Image = Images.background
	for index, name in ipairs(navNames) do
		icon(self.ui.Navigation[name].Icon, index)
		self:connect(self.ui.Navigation[name].Activated, function()
			self:open(name)
		end)
	end
	icon(self.ui.Header.Coins.Icon, 5)
	icon(self.ui.Header.Settings.Icon, 6)
	icon(self.ui.Header.Profile.Icon, 7)
	icon(self.ui.Footer.Daily.Icon, 8)
	icon(self.ui.Footer.Reward.Icon, 9)
	icon(self.ui.Panel.Content.Shop.Supply.Icon, 9)
	icon(self.ui.Panel.Content.Profile.Badge, 8)
	self:connect(self.ui.Header.Profile.Activated, function()
		self:open("Profile")
	end)
	self:connect(self.ui.Header.Settings.Activated, function()
		self:open("Settings")
	end)
	self:connect(self.ui.Header.Coins.Activated, function()
		self:open("Shop")
	end)
	self:connect(self.ui.Footer.Daily.Activated, function()
		self:open("Missions")
	end)
	self:connect(self.ui.Footer.Reward.Activated, function()
		self:open("Missions")
	end)
	self:connect(self.ui.Panel.Back.Activated, function()
		self:open(nil)
	end)
	self:connect(self.ui.Next.Continue.Activated, function()
		if self.primary.action == "select" then
			self:open("Adventure")
		else
			remotes.Input:FireServer("continue")
		end
	end)
	self:connect(self.ui.Stage.RotateLeft.Activated, function()
		self:turn(-1)
	end)
	self:connect(self.ui.Stage.RotateRight.Activated, function()
		self:turn(1)
	end)
	self:connect(self.ui.Stage.Inspect.Activated, function()
		self:turn(1)
	end)
	local content = self.ui.Panel.Content
	self:connect(content.Adventure.Play.Activated, function()
		if self.selectedTrail == 1 then
			remotes.Input:FireServer("playPhase", Tutorial.phaseId)
		end
	end)
	for index = 1, 4 do
		self:connect(content.Adventure["Trail_" .. index].Activated, function()
			self.selectedTrail = index
			self:refresh()
		end)
	end
	local function preview(mounted)
		self.mounted = mounted and self.state.frogUnlocked
		self:open("Character")
	end
	self:connect(content.Character.Preview.Activated, function()
		self.mounted = not self.mounted
	end)
	self:connect(content.Character.Equip.Activated, function()
		remotes.Input:FireServer("equipSkinPack", "base")
	end)
	self:connect(content.Frogs.Preview.Activated, function()
		self.mounted = self.state.frogUnlocked
	end)
	self:connect(content.Frogs.Equip.Activated, function()
		if self.state.frogUnlocked then
			remotes.Input:FireServer("equipSkinPack", "base")
		end
	end)
	self:connect(content.Shop.Preview.Activated, function()
		preview(true)
	end)
	self:connect(content.Shop.Supply.Claim.Activated, function()
		remotes.Input:FireServer("claimReward", "supply")
	end)
	for name, kind in pairs({ Energy = "energy", Clear = "clear", Supply = "supply" }) do
		self:connect(content.Missions[name].Claim.Activated, function()
			remotes.Input:FireServer("claimReward", kind)
		end)
	end
	self:connect(content.Profile.EquipBadge.Activated, function()
		remotes.Input:FireServer("campBadge", not self.state.campBadge)
	end)
	self:connect(self.ui.RewardToast.Equip.Activated, function()
		remotes.Input:FireServer("equipSkinPack", "base")
		remotes.Input:FireServer("rewardSeen")
		self.mounted = true
	end)
	self:connect(self.ui.RewardToast.Close.Activated, function()
		remotes.Input:FireServer("rewardSeen")
	end)
	local settingButtons = {
		Music = "music",
		Sfx = "sfx",
		Vibration = "vibration",
		Effects = "reducedEffects",
		Handed = "leftHanded",
		Opacity = "controlsOpacity",
		Text = "largeText",
	}
	for buttonName, setting in pairs(settingButtons) do
		self:connect(content.Settings[buttonName].Activated, function()
			local value = self.state.settings[setting]
			if type(value) == "boolean" then
				value = not value
			elseif setting == "controlsOpacity" then
				value = value >= 0.99 and 0.35 or math.min(1, value + 0.15)
			else
				value = value >= 0.99 and 0 or math.min(1, value + 0.25)
			end
			remotes.Input:FireServer("setting", { name = setting, value = value })
		end)
	end
	self:connect(UserInputService.InputBegan, function(input, processed)
		if processed or not self.ui.Enabled then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			self:open(nil)
		elseif input.KeyCode == Enum.KeyCode.Left then
			self:turn(-1)
		elseif input.KeyCode == Enum.KeyCode.Right then
			self:turn(1)
		end
	end)
	self:connect(self.ui:GetPropertyChangedSignal("AbsoluteSize"), function()
		self:layout()
	end)
	self:connect(RunService.RenderStepped, function(dt)
		if self.ui.Enabled then
			self.time += dt
			self:render()
		end
	end)
	self:layout()
	task.spawn(function()
		game:GetService("ContentProvider"):PreloadAsync({ Images.background, Images.icons })
	end)
	return self
end

function Controller:connect(signal, callback)
	table.insert(self.connections, signal:Connect(callback))
end

function Controller:turn(offset)
	self.direction = (self.direction - 1 + offset) % 4 + 1
end

function Controller:open(name)
	if self.state and self.state.location == "settings" then
		if name == nil then
			self.remotes.Input:FireServer("closeSettings")
			return
		end
		name = "Settings"
	end
	if name == "Shop" and not self.state.completed then
		self:open("Adventure")
		self.ui.Panel.Content.Adventure.TrailHint.Text = "Win First Spark to open the camp store."
		return
	end
	self.panel = name
	for _, panel in ipairs(self.ui.Panel.Content:GetChildren()) do
		if panel:IsA("GuiObject") then
			panel.Visible = panel.Name == name
		end
	end
	self.ui.Panel.Visible = name ~= nil
	self.ui.Next.Visible = name == nil
	if name then
		self.ui.Panel.Content.CanvasSize = UDim2.fromOffset(0, canvasHeights[name])
		self.ui.Panel.Content.CanvasPosition = Vector2.zero
	end
	self.ui:SetAttribute("OpenPanel", name or "")
	self:refresh()
end

function Controller:layout()
	local ui = self.ui
	local width, height = ui.AbsoluteSize.X, ui.AbsoluteSize.Y
	if width < 1 or height < 1 then
		return
	end
	local geometry = Layout.compute(width, height)
	place(ui.Header, geometry.header)
	place(ui.Navigation, geometry.navigation)
	place(ui.Stage, geometry.stage)
	place(ui.Next, geometry.card)
	place(ui.Panel, geometry.panel)
	place(ui.Footer, geometry.footer)
	-- Keep new-item feedback beside the hero, or in the footer on compact screens.
	local toast = ui.RewardToast
	toast.AnchorPoint = Vector2.zero
	if geometry.card[4] > 220 then
		place(toast, { geometry.card[1], geometry.card[2], geometry.card[3], 132 })
		place(toast.Title, { 8, 4, geometry.card[3] - 16, 28 })
		place(toast.Detail, { 8, 34, geometry.card[3] - 16, 44 })
		place(toast.Equip, { 8, 84, geometry.card[3] * 0.68 - 12, 44 })
		place(toast.Close, { geometry.card[3] * 0.68, 84, geometry.card[3] * 0.32 - 8, 44 })
	else
		local fw = geometry.footer[3]
		place(toast, geometry.footer)
		place(toast.Title, { 8, 2, fw * 0.5 - 16, 26 })
		place(toast.Detail, { 8, 28, fw * 0.5 - 16, geometry.footer[4] - 30 })
		place(toast.Equip, { fw * 0.5, 4, fw * 0.3 - 6, math.max(44, geometry.footer[4] - 8) })
		place(toast.Close, { fw * 0.8, 4, fw * 0.2 - 8, math.max(44, geometry.footer[4] - 8) })
	end
	local headerWidth = geometry.header[3]
	place(ui.Header.Settings, { headerWidth - 44, 0, 44, 42 })
	place(ui.Header.Profile, { headerWidth - 94, 0, 44, 42 })
	place(ui.Header.Coins, { headerWidth - 210, 0, 110, 42 })
	place(ui.Header.Title, { 0, 0, math.max(70, headerWidth - 220), 42 })
	ui.Header.Title.Text = width < 600 and "YOUR CAMP" or "BOMB YOUR WAY!"
	ui.Header.Title:SetAttribute("BaseTextSize", width < 600 and 15 or 23)
	ui.Header.Title.TextSize = width < 600 and 15 or 23
	local columns = geometry.navColumns
	local buttonWidth = (geometry.navigation[3] - (columns - 1) * 6) / columns
	local buttonHeight = (geometry.navigation[4] - (4 / columns - 1) * 6) / (4 / columns)
	for index, name in ipairs(navNames) do
		local button = ui.Navigation[name]
		place(button, {
			(index - 1) % columns * (buttonWidth + 6),
			math.floor((index - 1) / columns) * (buttonHeight + 6),
			buttonWidth,
			buttonHeight,
		})
		local narrow = buttonWidth < 90
		place(button.Icon, narrow and { (buttonWidth - 30) / 2, 3, 30, 30 } or { 8, (buttonHeight - 36) / 2, 36, 36 })
		place(
			button.Caption,
			narrow and { 0, buttonHeight - 20, buttonWidth, 18 } or { 50, 0, buttonWidth - 56, buttonHeight }
		)
		button.Caption:SetAttribute("BaseTextSize", narrow and 10 or 13)
		button.Caption.TextSize = narrow and 10 or 13
		button.Caption.TextXAlignment = narrow and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
	end
	local sw, sh = geometry.stage[3], geometry.stage[4]
	place(ui.Stage.RotateLeft, { 0, sh - 46, 40, 40 })
	place(ui.Stage.RotateRight, { sw - 40, sh - 46, 40, 40 })
	place(ui.Stage.PackName, { 44, sh - 48, sw - 88, 24 })
	place(ui.Stage.InspectHint, { 0, sh - 22, sw, 20 })
	ui.Stage.PackName:SetAttribute("BaseTextSize", sw < 220 and 12 or 16)
	ui.Stage.PackName.TextSize = sw < 220 and 12 or 16
	ui.Stage.Shadow.Position = UDim2.fromScale(0.5, 0.72)
	local contentWidth = geometry.panel[3] - 24
	local nodeGap = math.max(0, (contentWidth - 4 * 44) / 3)
	for index = 1, 4 do
		place(ui.Panel.Content.Adventure["Trail_" .. index], { (index - 1) * (44 + nodeGap), 116, 44, 44 })
	end
	local cardHeight = geometry.card[4]
	local artHeight = cardHeight > 220 and 74 or cardHeight > 160 and 30 or 0
	ui.Next.Art.Visible = artHeight > 0
	ui.Next.Art.Size = UDim2.new(1, 0, 0, artHeight)
	ui.Next.Eyebrow.Visible = cardHeight > 160
	place(ui.Next.Eyebrow, { 12, artHeight + 8, geometry.card[3] - 24, 20 })
	local titleY = cardHeight > 160 and artHeight + 30 or 6
	place(ui.Next.Title, { 12, titleY, geometry.card[3] - 24, 26 })
	place(ui.Next.Detail, { 12, titleY + 30, geometry.card[3] - 24, math.max(22, cardHeight - titleY - 92) })
	ui.Next.Detail:SetAttribute("BaseTextSize", cardHeight < 150 and 13 or 15)
	ui.Next.Detail.TextSize = cardHeight < 150 and 13 or 15
	self:refresh()
end

function Controller:update(state)
	local previousLocation = self.state and self.state.location
	if self.state and not self.state.frogUnlocked and state.frogUnlocked then
		self.mounted = true
	end
	self.state = state
	self.ui.Enabled = state.location == "lobby" or state.location == "settings"
	local settingsOnly = state.location == "settings"
	self.ui.Navigation.Visible = not settingsOnly
	self.ui.Footer.Visible = not settingsOnly
	self.ui.Header.Coins.Visible = not settingsOnly
	self.ui.Header.Profile.Visible = not settingsOnly
	self.ui.Header.Title.Text = settingsOnly and "SETTINGS"
		or self.ui.AbsoluteSize.X < 600 and "YOUR CAMP"
		or "BOMB YOUR WAY!"
	if previousLocation ~= state.location then
		self:open(settingsOnly and "Settings" or nil)
	end
	if self.mounted == nil then
		self.mounted = state.frogUnlocked
	end
	self:refresh()
end

function Controller:refresh()
	local state = self.state
	if not state then
		return
	end
	local ui, content = self.ui, self.ui.Panel.Content
	self.primary = Progress.primary(state, Tutorial)
	ui.Next.Continue.Text = self.primary.text
	ui.Next.Detail.Text = self.primary.detail
	ui.Header.Coins.Text = tostring(state.coins) .. "  "
	ui.Stage.PackName.Text = "ORIGINAL PACK"
	ui.Navigation.Shop.Caption.Text = state.completed and "SHOP" or "SHOP LOCKED"
	ui.Footer.Daily.Caption.Text = "DAILY CHALLENGE\nClean run • 10 coins"
	ui.Footer.Reward.Caption.Text = string.format("NEXT REWARD\nCampfire badge • %d/7 visits", state.supplies.count)
	ui.RewardToast.Visible = state.location == "lobby"
		and state.frogUnlocked
		and not state.rewardSeen
		and state.completed
	local medals = string.format(
		"Completion: %s\nSecret: %s • No deaths: %s",
		state.completed and "earned" or "in progress",
		state.secret and "found" or "hidden",
		state.noDeathsMedal and "earned" or "pending"
	)
	content.Adventure.Medals.Text = medals
	content.Adventure.Play.Text = self.selectedTrail ~= 1 and "TRAIL CLOSED"
		or state.finished and "REPLAY FIRST SPARK"
		or "CONTINUE FIRST SPARK"
	content.Adventure.Play.Active = self.selectedTrail == 1
	content.Adventure.Play.AutoButtonColor = self.selectedTrail == 1
	content.Adventure.TrailHint.Text = self.selectedTrail == 1
			and string.format("Stage %d/%d • %s", state.stage, #Tutorial.stages, Tutorial.stages[state.stage].name)
		or "This trail is not open yet. Explore First Spark and its secrets."
	content.Character.Equip.Text = state.skinPack == "base" and "EQUIPPED" or "EQUIP COMPLETE PACK"
	content.Frogs.Origin.Text = state.frogUnlocked
			and "Rescued in Rescue Courtyard.\nCosmetic companion from the Original Pack."
		or "Locked • Rescue the frog in Rescue Courtyard."
	content.Frogs.Equip.Text = state.frogUnlocked and "EQUIP MATCHING PACK" or "RESCUE TO UNLOCK"
	content.Frogs.Portrait.ImageColor3 = state.frogUnlocked and Color3.new(1, 1, 1) or Color3.new(0.08, 0.12, 0.14)
	content.Profile:FindFirstChild("Name").Text = self.player.DisplayName .. (state.campBadge and " • CAMPFIRE" or "")
	content.Profile.Stats.Text = medals
		.. string.format(
			"\nCoins: %d\nCompanions rescued: %d\nCheckpoint: %s",
			state.coins,
			state.frogUnlocked and 1 or 0,
			Tutorial.stages[state.stage].name
		)
	content.Profile.EquipBadge.Text = state.supplies.count < 7 and "CLAIM SUPPLIES ON 7 DAYS"
		or state.campBadge and "BADGE EQUIPPED"
		or "EQUIP CAMPFIRE BADGE"
	content.Profile.Badge.ImageColor3 = state.supplies.count == 7 and Color3.new(1, 1, 1) or Color3.new(0.15, 0.2, 0.2)
	local daily = state.daily
	content.Missions.Energy.Progress.Text =
		string.format("Break 3 energy crates • %d/3\nReward: 5 coins", daily.crates)
	content.Missions.Clear.Progress.Text = "Complete First Spark without dying.\nReward: 10 coins"
	content.Missions.Supply.Progress.Text = string.format(
		"%d/7 visits • Any days count.\nReward: 3 coins per claim + Campfire badge.",
		state.supplies.count
	)
	content.Missions.Energy.Claim.Text = daily.energyClaimed and "CLAIMED"
		or daily.crates == 3 and state.completed and "CLAIM 5 COINS"
		or "IN PROGRESS"
	content.Missions.Clear.Claim.Text = daily.clearClaimed and "CLAIMED"
		or daily.clear and state.completed and "CLAIM 10 COINS"
		or "IN PROGRESS"
	local supplyText = state.supplies.lastDay == daily.day and "CLAIMED TODAY"
		or state.completed and "CLAIM 3 COINS"
		or "WIN FIRST SPARK TO UNLOCK"
	content.Missions.Supply.Claim.Text = supplyText
	content.Shop.Supply.Claim.Text = supplyText
	local settings = state.settings
	content.Settings.Music.Text = string.format("MUSIC: %d%%", math.round(settings.music * 100))
	content.Settings.Sfx.Text = string.format("SOUND EFFECTS: %d%%", math.round(settings.sfx * 100))
	content.Settings.Vibration.Text = "VIBRATION: " .. (settings.vibration and "ON" or "OFF")
	content.Settings.Effects.Text = "REDUCED EFFECTS: " .. (settings.reducedEffects and "ON" or "OFF")
	content.Settings.Handed.Text = "CONTROLS: " .. (settings.leftHanded and "LEFT-HANDED" or "RIGHT-HANDED")
	content.Settings.Opacity.Text = string.format("CONTROLS OPACITY: %d%%", math.round(settings.controlsOpacity * 100))
	content.Settings.Text.Text = "LARGE TEXT: " .. (settings.largeText and "ON" or "OFF")
	content.Settings.Language.Text = "LANGUAGE: ENGLISH"
	Preferences.text(ui, settings.largeText)
end

function Controller:render()
	local state, ui = self.state, self.ui
	if not state then
		return
	end
	local direction = directions[self.direction]
	ui.Ambient.Visible = not state.settings.reducedEffects
	if ui.Ambient.Visible then
		for index = 1, 6 do
			local leaf = ui.Ambient["Leaf_" .. index]
			leaf.Position = UDim2.fromScale(
				0.08 + (index - 1) * 0.16 + math.sin(self.time * 0.3 + index) * 0.012,
				0.2 + ((index - 1) % 3) * 0.12 + math.sin(self.time * 0.18 + index) * 0.035
			)
			leaf.Rotation = 35 + math.sin(self.time * 0.5 + index) * 18
			leaf.BackgroundTransparency = 0.5 + math.sin(self.time * 0.25 + index) * 0.12
		end
	end
	local sw, sh = ui.Stage.AbsoluteSize.X, ui.Stage.AbsoluteSize.Y
	local mounted = self.mounted and state.frogUnlocked
	local frame = sprite(ui.Stage.Hero, state.skinPack, mounted and "mounted" or "hero", "idle", direction, self.time)
	local scale = math.min(sh * 0.6 / frame.opaqueBounds[4], sw * 0.68 / frame.opaqueBounds[3])
	local w, h = frame.rect[3] * scale, frame.rect[4] * scale
	local bounce = state.settings.reducedEffects and 0 or math.sin(self.time * 1.4) * 1.5
	place(ui.Stage.Hero, { sw * 0.5 - frame.groundPivot[1] * w, sh * 0.72 - frame.groundPivot[2] * h + bounce, w, h })
	ui.Stage.Frog.Visible = not mounted and state.frogUnlocked
	if ui.Stage.Frog.Visible then
		local frog = sprite(ui.Stage.Frog, state.skinPack, "frog", "idle", direction, self.time)
		local fs = math.min(sh * 0.25 / frog.opaqueBounds[4], sw * 0.25 / frog.opaqueBounds[3])
		local fw, fh = frog.rect[3] * fs, frog.rect[4] * fs
		place(ui.Stage.Frog, { sw * 0.82 - frog.groundPivot[1] * fw, sh * 0.72 - frog.groundPivot[2] * fh, fw, fh })
	end
	local content = ui.Panel.Content
	for kind, view in pairs({
		hero = content.Character.PackArt.Hero,
		frog = content.Character.PackArt.Frog,
		mounted = content.Character.PackArt.Mounted,
	}) do
		sprite(view, state.skinPack, kind, "idle", "down", 0)
	end
	sprite(content.Frogs.Portrait, state.skinPack, "frog", "idle", "down", self.time)
	sprite(content.Shop.Pack, state.skinPack, "mounted", "idle", "down", 0)
	ui.Background.ImageColor3 = state.completed and Color3.new(1, 1, 1) or Color3.new(0.9, 0.94, 1)
end

function Controller:destroy()
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	self.ui:Destroy()
end

return Controller
