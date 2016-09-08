earth_spirit_boss_raise_remnants = class ({})

--------------------------------------------------------------------------------
function check_remnants( event )
	local caster = event.caster
	local ability = event.ability
	local point = event.target_points[1]
	local area_of_effect = ability:GetLevelSpecialValueFor("area_of_effect", ability:GetLevel() - 1 ) 
	local max_raised = ability:GetLevelSpecialValueFor("max_raised", ability:GetLevel() - 1 ) 
	local min_raised = ability:GetLevelSpecialValueFor("max_raised", 0) 
	local counter = 0
	tRemnants = {} --Holds the applicable remnants
				  
	local units = FindUnitsInRadius(caster:GetTeamNumber(), 
								point, 
								nil, 
								area_of_effect, 
								DOTA_UNIT_TARGET_TEAM_FRIENDLY,
								DOTA_UNIT_TARGET_ALL,
								DOTA_UNIT_TARGET_FLAG_NONE,
								FIND_CLOSEST, 
								false)

	for k, unit in pairs(units) do 
		if (unit:HasAbility("remnant_dummy_ability_datadriven") == true) then
			table.insert(tRemnants, unit)
			counter = counter + 1
		end
	end 

	if (counter < min_raised) then
		caster:Interrupt()
		print("Caster Interrupted")
		tRemnants = nil
	end	 	
end

function raise_remnants( event )
	local caster = event.caster
	local ability = event.ability
	local point = event.target_points[1]
	local area_of_effect = ability:GetLevelSpecialValueFor("area_of_effect", ability:GetLevel() - 1 ) 
	local max_raised = ability:GetLevelSpecialValueFor("max_raised", ability:GetLevel() - 1 ) 
	print("Raised")
	local pebbles = {}

	local size = table.getn(tRemnants) - (table.getn(tRemnants) % 3)
	local counter = 0
	local position = ability

	for k, unit in pairs(tRemnants) do
		print("Size " .. size)
		counter = counter + 1
		if (counter <= size) then
			print("counter: " .. counter)
			local stonePebble = CreateUnitByName("earth_spirit_boss_stone_pebble", unit:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
			table.insert(pebbles, k, stonePebble) 
			unit:AddNewModifier(caster, nil, "modifier_kill", {duration = 0.01})
		end
	end	
	tRemnants = nil
end