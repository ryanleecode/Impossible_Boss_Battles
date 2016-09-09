earth_spirit_boss_stone_caller = class({})

--------------------------------------------------------------------------------
function spawn_stone_remnants( event )
	local ability = event.ability
	local numberOfStones = ability:GetLevelSpecialValueFor("quantity", (ability:GetLevel() - 1))
	--local expireDuration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

	local caster = ability:GetCaster()
	local position = caster:GetAbsOrigin()

	--spawn stones
	for i=1, numberOfStones , 1 do
	local randomNumber = RandomInt(0, 600)
	local randomVector = RandomVector(randomNumber)
	position = position + randomVector
	local stoneRemnant = CreateUnitByName("earth_spirit_boss_stone_remnant", position, true, nil, nil, DOTA_TEAM_BADGUYS)
  	stoneRemnant:SetAbsOrigin(position)
  	--stoneRemnant:AddNewModifier(caster, nil, "modifier_kill", {duration = expireDuration})
  	end	
end