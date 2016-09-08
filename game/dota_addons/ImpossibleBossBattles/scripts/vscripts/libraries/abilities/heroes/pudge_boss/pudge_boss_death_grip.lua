--[[
	Author: drdgvhbh
	Last Updated: July 26 2016
	Description: Death Grip ability for 'Pudge the Butcher' (Boss)
]]--

DEBUG = false -- Debug Flag to print messages to Console
--===============================--
--[[Ability Parameter Constants]]--
--===============================--
INNER_SEARCH_RANGE = 680
DEATH_CIRCLE_DURATION = 1.6

--====================--
--[[Helper Functions]]--
--====================--	

function destroyParticle( particle, time, name)
	Timers:CreateTimer({
		endTime = time,
		callback = function()
		ParticleManager:DestroyParticle(particle, true)
		--debugPrint(name.." has been destroyed!")
	end
	})
end

--=====================--
--[[Ability Functions]]--
--=====================--
function pudge_boss_death_grip (keys)
	local ability = keys.ability
 	local caster = keys.caster
	local circleNumber = ability:GetLevelSpecialValueFor("numberOfCircles", ability:GetLevel() - 1)
	local outerRadius = ability:GetLevelSpecialValueFor("outerRadius", ability:GetLevel() - 1)  
	local heroes = HeroList:GetAllHeroes()
	local origin = caster:GetAbsOrigin()


	local selectedHeroes = {}
	local counter = 1
	for k, v in pairs (heroes) do
		local pass = UnitFilter(v, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED, DOTA_TEAM_GOODGUYS)
		if pass == 1 and v:IsAlive() == true then
			table.insert(selectedHeroes, counter, v)
			counter = counter + 1
		end		
	end
	circleNumber = circleNumber - table.getn(selectedHeroes)
	for k, v in pairs (selectedHeroes) do
		particleDamageGrip(caster, v:GetAbsOrigin(), ability)
	end	
	for i=1,math.ceil(circleNumber*(3/5)),1 do 
		local coordinates = {
			["x"]	= math.random(-INNER_SEARCH_RANGE,INNER_SEARCH_RANGE),
			["y"] 	= math.random(-INNER_SEARCH_RANGE,INNER_SEARCH_RANGE),
			["z"] 	= math.random(-INNER_SEARCH_RANGE,INNER_SEARCH_RANGE)
		}
		local vector = origin + Vector(coordinates["x"],coordinates["y"], 0)
		particleDamageGrip(caster, vector, ability)
	end	
	for i=1,math.floor(circleNumber*(2/5)),1 do 
		local coordinates = {
			["x"]	= math.random(-outerRadius,outerRadius),
			["y"] 	= math.random(-outerRadius,outerRadius),
		}

		local vector = origin + Vector(coordinates["x"],coordinates["y"], 0)
		particleDamageGrip(caster, vector, ability)
	end	
	Timers:CreateTimer({
		endTime = DEATH_CIRCLE_DURATION,
		callback = function()	
		EmitSoundOn("Hero_Nevermore.Shadowraze", caster)		
		end
	})
end

function particleDamageGrip(owner, control, ability)
	local teamNumber = owner:GetTeamNumber() 
	local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1)  
	local dmg = ability:GetLevelSpecialValueFor("damage", ability:GetLevel() - 1)

	local nFXIndex = ParticleManager:CreateParticle( "particles/pudge_boss/pudge_boss_death_grip_circle.vpcf", PATTACH_ABSORIGIN, owner)
	ParticleManager:SetParticleControl(nFXIndex, 0, control )	
	destroyParticle( nFXIndex, DEATH_CIRCLE_DURATION, "death_grip_cirlce")	
	Timers:CreateTimer({
		endTime = DEATH_CIRCLE_DURATION,
		callback = function()	
		local nFXIndex3 = ParticleManager:CreateParticle( "particles/pudge_boss/pudge_boss_death_grip_raze.vpcf", PATTACH_ABSORIGIN, owner)
		ParticleManager:SetParticleControl(nFXIndex3, 0, control )
		local units = FindUnitsInRadius(teamNumber, control, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_ANY_ORDER, false)
		for k, v in pairs(units) do
			if v:IsAlive() then 
				local damageTable = {
					victim = v,
					attacker = owner,
					damage = dmg,
					damage_type = DAMAGE_TYPE_MAGICAL
				} 
				ApplyDamage(damageTable)

				local gripper = CreateUnitByName("pudge_boss_necrolyte_gripper", control, true, owner, owner, teamNumber)
				local grip = gripper:FindAbilityByName("pudge_boss_necro_death_grip_datadriven")
				gripper:SetControllableByPlayer(v:GetPlayerID(),true)
				Timers:CreateTimer({
					endTime = 0.0666666,
					callback = function()	
					gripper:CastAbilityOnTarget(v, grip, gripper:GetPlayerOwnerID()) 
					end
				})
				Timers:CreateTimer({
					endTime =5.0 + 0.0666666,
					callback = function()
					if gripper:IsAlive() then
						gripper:ForceKill(true)
					end
				end
				})
			end
		end
	end
	})
end
