-- One equipped ID always selects the hero, frog and unified mounted artwork.
-- Future packs must supply all three forms; cosmetics never configure gameplay.
local SkinPacks = {}
SkinPacks.default = "base"
SkinPacks.packs = {
	base = { hero = "hero", heroMovement = "heroMovement", frog = "frog", mounted = "mounted" },
}

function SkinPacks.resolve(id)
	return SkinPacks.packs[id] or SkinPacks.packs[SkinPacks.default]
end

function SkinPacks.normalize(id)
	return SkinPacks.packs[id] and id or SkinPacks.default
end

function SkinPacks.atlas(id, form, source)
	local pack = SkinPacks.resolve(id)
	if form == "hero" then
		return source == "heroMovement" and pack.heroMovement or pack.hero
	end
	return pack[form]
end

return SkinPacks
