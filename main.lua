SafetyBombsMod = RegisterMod("Safety Bombs", 1)
local mod = SafetyBombsMod

CollectibleType.COLLECTIBLE_SAFETY_BOMBS = Isaac.GetItemIdByName("Safety Bombs")

if EID then
end

local function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

function mod:BombRender(bomb)
	if bomb.FrameCount == 1 then
		local player = mod:GetPlayerFromTear(bomb)
		if player then
			if bomb.Type == EntityType.ENTITY_BOMBDROP then
				if bomb.Variant == BombVariant.BOMB_NORMAL then
					if player:HasCollectible(CollectibleType.COLLECTIBLE_SAFETY_BOMBS) and not player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE_BOMBS) then
						local sprite = bomb:GetSprite()
						
						if bomb:HasTearFlags(TearFlags.TEAR_GOLDEN_BOMB) then
							sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/bombs/costumes/safety_bombs_gold.png")
							sprite:LoadGraphics()
						else
							sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/bombs/costumes/safety_bombs.png")
							sprite:LoadGraphics()
						end
					end
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_RENDER, mod.BombRender)

function mod:BombUpdate(bomb)
	local player = mod:GetPlayerFromTear(bomb)
	if player then
		if bomb.Type == EntityType.ENTITY_BOMBDROP then
			if bomb.Variant ~= BombVariant.BOMB_THROWABLE then
				if player:HasCollectible(CollectibleType.COLLECTIBLE_SAFETY_BOMBS) then
					local sprite = bomb:GetSprite()
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
	for i=1, 3 do
		local check = nil
		if i == 1 then
			check = tear.Parent
		elseif i == 2 then
			check = mod:GetSpawner(tear)
		elseif i == 3 then
			check = tear.SpawnerEntity
		end
		if check then
			if check.Type == EntityType.ENTITY_PLAYER then
				return mod:GetPtrHashEntity(check):ToPlayer()
			elseif check.Type == EntityType.ENTITY_FAMILIAR and check.Variant == FamiliarVariant.INCUBUS then
				local data = tear:GetData()
				data.IsIncubusTear = true
				return check:ToFamiliar().Player:ToPlayer()
			end
		end
	end
	return nil
end

function mod:GetSpawner(entity)
	if entity and entity.GetData then
		local spawnData = mod:GetSpawnData(entity)
		if spawnData and spawnData.SpawnerEntity then
			local spawner = mod:GetPtrHashEntity(spawnData.SpawnerEntity)
			return spawner
		end
	end
	return nil
end

function mod:GetSpawnData(entity)
	if entity and entity.GetData then
		local data = entity:GetData()
		return data.SpawnData
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