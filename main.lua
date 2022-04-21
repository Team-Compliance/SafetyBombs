SafetyBombsMod = RegisterMod("Safety Bombs", 1)
local mod = SafetyBombsMod

CollectibleType.COLLECTIBLE_SAFETY_BOMBS = Isaac.GetItemIdByName("Safety Bombs")

if EID then
    EID:addCollectible(CollectibleType.COLLECTIBLE_SAFETY_BOMBS, "{{Bomb}} +5 Bombs#Placed bombs will not explode until the player leaves its explosion radius", "Safety Bombs")
end

local function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

function mod:BombUpdate(bomb)
	local player = mod:GetPlayerFromTear(bomb)
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
					
					local bombRadius = 75
					if ends_with(sprite:GetFilename(), "3.anm2") or bomb.Variant == BombVariant.BOMB_DECOY or bomb.Variant == BombVariant.BOMB_MR_MEGA then
						bombRadius = 105
					end
					for i, player in ipairs(Isaac.FindInRadius(bomb.Position, bombRadius * bomb.RadiusMultiplier, EntityPartition.PLAYER)) do
						bomb:SetExplosionCountdown(45)
						break
					end
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, mod.BombUpdate)

-------

function mod:GetPlayerFromTear(tear)
	local check = tear.Parent or tear.SpawnerEntity
	if check then
		if check.Type == EntityType.ENTITY_PLAYER then
			return mod:GetPtrHashEntity(check):ToPlayer()
		elseif check.Type == EntityType.ENTITY_FAMILIAR and check.Variant == FamiliarVariant.INCUBUS then
			local data = tear:GetData()
			data.IsIncubusTear = true
			return check:ToFamiliar().Player:ToPlayer()
		end
	end
	return nil
end

function mod:GetPtrHashEntity(entity)
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
