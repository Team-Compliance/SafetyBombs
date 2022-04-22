SafetyBombsMod = RegisterMod("Safety Bombs", 1)
local mod = SafetyBombsMod

CollectibleType.COLLECTIBLE_SAFETY_BOMBS = Isaac.GetItemIdByName("Safety Bombs")

if EID then
    EID:addCollectible(CollectibleType.COLLECTIBLE_SAFETY_BOMBS, "{{Bomb}} +5 Bombs#Placed bombs will not explode until the player leaves its explosion radius", "Safety Bombs")
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
      {str = "Book of Illusions was an unused concept from Antibirth."},
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

local function getBombRadiusFromDamage(damage)
	if 175.0 <= damage then
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
	if player then
		if bomb.Type == EntityType.ENTITY_BOMB then
			if bomb.Variant ~= BombVariant.BOMB_THROWABLE then
				if player:HasCollectible(CollectibleType.COLLECTIBLE_SAFETY_BOMBS) then
					local sprite = bomb:GetSprite()
					
					if bomb.FrameCount == 1 then
						if bomb.Variant == BombVariant.BOMB_NORMAL then
							if not bomb:HasTearFlags(TearFlags.TEAR_BRIMSTONE_BOMB) then
								if bomb:HasTearFlags(TearFlags.TEAR_GOLDEN_BOMB) then
									sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/bombs/costumes/safety_bombs_gold.png")
								else
									sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/bombs/costumes/safety_bombs.png")
								end
								sprite:LoadGraphics()
							end
						end
					end
					
					for i, p in ipairs(Isaac.FindInRadius(bomb.Position, getBombRadiusFromDamage(bomb.ExplosionDamage) * bomb.RadiusMultiplier, EntityPartition.PLAYER)) do
						bomb:SetExplosionCountdown(45)
						break
					end
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, mod.BombUpdate)