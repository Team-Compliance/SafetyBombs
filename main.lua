SafetyBombsMod = RegisterMod("Safety Bombs", 1)
local mod = SafetyBombsMod

CollectibleType.COLLECTIBLE_SAFETY_BOMBS = Isaac.GetItemIdByName("Safety Bombs")

local SafetyBombIcon = Sprite()
SafetyBombIcon:Load("gfx/ui/minimapitems/safetybomb_icon.anm2", true)

if EID then
    EID:addCollectible(CollectibleType.COLLECTIBLE_SAFETY_BOMBS, "{{Bomb}} +5 Bombs#Placed bombs will not explode until the player leaves its explosion radius", "Safety Bombs")
	EID:addCollectible(CollectibleType.COLLECTIBLE_SAFETY_BOMBS, "{{Bomb}} +5 Bombas#Las bombas que coloques no explotarán hasta que te alejes de su radio de explosión", "Bombas de Seguridad", "spa")
	EID:addCollectible(CollectibleType.COLLECTIBLE_SAFETY_BOMBS, "{{Bomb}} +5 бомб#Размещенные бомбы не взорвутся, пока игрок не покинет радиус взрыва", "Безопасные бомбы", "ru")
end

if MinimapAPI and MiniMapiItemsAPI then
	MiniMapiItemsAPI:AddCollectible(CollectibleType.COLLECTIBLE_SAFETY_BOMBS, SafetyBombIcon, "CustomIcons", 0)
end

local Wiki = {
  SafetyBombs = {
    { -- Effect
      {str = "Effect", fsize = 2, clr = 3, halign = 0},
      {str = "+5 bombs."},
      {str = "Placed bombs will not explode until the player leaves its explosion radius."},
    },
    { -- Trivia
      {str = "Trivia", fsize = 2, clr = 3, halign = 0},
      {str = "This mod was coded by kittenchilly!"},
      {str = "Safety Bombs was an unused concept from Antibirth."},
    },
  }
}

if Encyclopedia then
	Encyclopedia.AddItem({
	  ID = CollectibleType.COLLECTIBLE_SAFETY_BOMBS,
	  WikiDesc = Wiki.SafetyBombs,
	  Pools = {
		Encyclopedia.ItemPools.POOL_TREASURE,
		Encyclopedia.ItemPools.POOL_GREED_TREASURE,
		Encyclopedia.ItemPools.POOL_BOMB_BUM,
	  },
	})
end

local function GetPtrHashEntity(entity)
	if entity then
		if entity.Entity then
			entity = entity.Entity
		end
		for _, matchEntity in pairs(Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, false)) do
			if GetPtrHash(entity) == GetPtrHash(matchEntity) then
				return matchEntity
			end
		end
	end
	return nil
end

local function GetPlayerFromTear(tear)
	local check = tear.Parent or tear.SpawnerEntity
	if check then
		if check.Type == EntityType.ENTITY_PLAYER then
			return GetPtrHashEntity(check):ToPlayer()
		elseif check.Type == EntityType.ENTITY_FAMILIAR and check.Variant == FamiliarVariant.INCUBUS then
			local data = tear:GetData()
			data.IsIncubusTear = true
			return GetPtrHashEntity(check:ToFamiliar().Player):ToPlayer()
		end
	end
	return nil
end

local function getBombRadiusFromDamage(damage,isBomber)
	if 300 <= damage then
		return 300.0
	elseif isBomber then
		return 155.0
	elseif 175.0 <= damage then
		return 105.0
	else
		if damage <= 140.0 then
			return 75.0
		else
			return 90.0
		end
	end
end

function mod:BombUpdate(bomb)
	local player = GetPlayerFromTear(bomb)
	local data = bomb:GetData()
	local fuseCD = 30
	local isBomber
	if player then
		if bomb.FrameCount == 1 then
			if bomb.Type == EntityType.ENTITY_BOMB then
				if bomb.Variant ~= BombVariant.BOMB_THROWABLE then
					if player:HasCollectible(CollectibleType.COLLECTIBLE_SAFETY_BOMBS) then
						if data.isSafetyBomb == nil then
							data.isSafetyBomb = true
						end
					end
				end
			end
		end
		if player:HasTrinket(TrinketType.TRINKET_SHORT_FUSE) then
			fuseCD = 2
		end
		isBomber = player:HasCollectible(CollectibleType.COLLECTIBLE_BOMBER_BOY)
	end
	
	if data.isSafetyBomb then
		if bomb.FrameCount == 1 then
			if bomb.Variant == BombVariant.BOMB_NORMAL then
				if not bomb:HasTearFlags(TearFlags.TEAR_BRIMSTONE_BOMB) then
					local sprite = bomb:GetSprite()
					if bomb:HasTearFlags(TearFlags.TEAR_GOLDEN_BOMB) then
						sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/bombs/costumes/safety_bombs_gold.png")
					else
						sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/bombs/costumes/safety_bombs.png")
					end
					sprite:LoadGraphics()
				end
			end
		end
		
		for i, p in ipairs(Isaac.FindInRadius(bomb.Position, getBombRadiusFromDamage(bomb.ExplosionDamage,isBomber) * bomb.RadiusMultiplier, EntityPartition.PLAYER)) do
			bomb:SetExplosionCountdown(fuseCD) -- temporary until we can get explosion countdown directly
			--bomb:SetExplosionCountdown(bomb.ExplosionCountdown)
			break
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, mod.BombUpdate)

local function DoRenderRadar(bomb)
	local data = bomb:GetData()
	local player = GetPlayerFromTear(bomb)
	local isBomber = player and player:HasCollectible(CollectibleType.COLLECTIBLE_BOMBER_BOY)
	data.BombRadar.SafetyBombTrigger = false
	for i, p in ipairs(Isaac.FindInRadius(bomb.Position, getBombRadiusFromDamage(bomb.ExplosionDamage,isBomber) * bomb.RadiusMultiplier, EntityPartition.PLAYER)) do
		data.BombRadar.SafetyBombTrigger = true
	end
	if not Game():IsPaused() then
		if data.BombRadar.SafetyBombTrigger then
			if data.BombRadar.SafetyBombTransperancy < 1 then
				data.BombRadar.SafetyBombTransperancy = data.BombRadar.SafetyBombTransperancy + 0.05
			end
		elseif data.BombRadar.SafetyBombTransperancy > 0 then
			data.BombRadar.SafetyBombTransperancy = data.BombRadar.SafetyBombTransperancy - 0.05
		end
	end
	if data.BombRadar.SafetyBombTransperancy > 0 then
		if not Game():IsPaused() then
			data.BombRadar.Sprite:Update()
		end
		data.BombRadar.Sprite.Color = Color(1,1,1,data.BombRadar.SafetyBombTransperancy)
		data.BombRadar.Sprite:Render(Game():GetRoom():WorldToScreenPosition(bomb.Position))
	elseif data.BombRadar.SafetyBombTransperancy <= 0 then
		data.BombRadar = nil
	end
end
function mod:BombRadar(bomb)
	local data = bomb:GetData()
	
	if data.isSafetyBomb then
		if not data.BombRadar then
			local player = GetPlayerFromTear(bomb)
			local isBomber = player and player:HasCollectible(CollectibleType.COLLECTIBLE_BOMBER_BOY)
			local mul = getBombRadiusFromDamage(bomb.ExplosionDamage,isBomber) / 75 * bomb.RadiusMultiplier
			data.BombRadar = {}
			data.BombRadar.Sprite = Sprite()
			data.BombRadar.Sprite:Load("gfx/safetybombsradar.anm2",true)
			data.BombRadar.Sprite:Play("Idle")
			data.BombRadar.Sprite.Scale = Vector(1.4*mul,1.4*mul)
			data.BombRadar.Sprite.PlaybackSpeed = 0.4
			data.BombRadar.SafetyBombTransperancy = 0
			data.BombRadar.SafetyBombTrigger = false
		else
			DoRenderRadar(bomb)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_RENDER, mod.BombRadar)