function dragon_circle_int(keys)
	--Local Variables
	local ability = keys.ability
	local caster = keys.caster

	local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1 )
	local duration = ability:GetLevelSpecialValueFor("delay", ability:GetLevel() - 1 )
	local startModifier = "modifier_dragon_circle_summon_datadriven" 
	local reincarnationModifier = "modifier_dragon_circle_reincarnation"
	local visionDuration = ability:GetLevelSpecialValueFor("visionDuration", ability:GetLevel() - 1 )

	local team = caster:GetTeamNumber()
	local casterHpOld = caster:GetHealth()
	local casterManaOld = caster:GetMana()
	local target = caster:GetAbsOrigin()

	local checkInterval = 0.1

	ability.timer = 0.0 
	ability.reincarnated = false

	-- Provide vision of the area
	ability:CreateVisibilityNode(target, radius, visionDuration)
	-- Create bloodrite effect for dragon circle
	StartSoundEventFromPosition(keys.sound,target)
	local particle = ParticleManager:CreateParticle(keys.particle, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, target)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
	ParticleManager:SetParticleControl(particle, 3, target)
	Timers:CreateTimer({
		endTime = duration,
		callback = function()
			ParticleManager:DestroyParticle(particle, false) 
		end
	})
	-- Applys a modifier, where upon taking damage, reincarnation function fires
	ability:ApplyDataDrivenModifier(caster, caster, reincarnationModifier, {} )
	-- Finds units within the dragon circle
	Timers:CreateTimer(function()
  		units = FindUnitsInRadius(team, target, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_DEAD, FIND_ANY_ORDER, false)
  		ability.timer = ability.timer + checkInterval
  		if ability.timer >= duration then
  			ability.timer = 0
  			units = nil
  			return nil
  		else  			
    		return checkInterval
    	end
    end
  	)

end

function reincarnation(keys)
	--Local Variables
	local ability = keys.ability
	local caster = keys.caster
	local attacker = keys.attacker

	local target = caster:GetAbsOrigin()
	local casterHp = caster:GetHealth()
	local casterMana = caster:GetMana()
	local casterGold = caster:GetGold()

	local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1 )

	local endModifier = "modifier_dragon_circle_end_datadriven"
	local LSADelay = (ability:GetLevelSpecialValueFor("LSADelay", ability:GetLevel() - 1 ))
	local reincarnate_time = (ability:GetLevelSpecialValueFor("delay", ability:GetLevel() - 1 )) - ability.timer

	local reducedRadius = radius/2

	-- Looks for the caster and checks if he has died
	if units ~= nil then
		for k, v  in pairs(units) do
	  		if v == caster and casterHp == 0 and ability.reincarnated == false then --reincarnate set to false to prevent infinite looping
	  			--Respawn
	  			caster:SetHealth(1)
	  			ability.reincarnated = true
	  			caster:SetRespawnsDisabled(false)
				caster:ForceKill(true)
				caster:SetTimeUntilRespawn(reincarnate_time) 
				caster:SetRespawnPosition(target) 
				-- Aegis Death Effect
				local aegisRing = ParticleManager:CreateParticle("particles/items_fx/aegis_timer.vpcf", PATTACH_ABSORIGIN, caster)
				ParticleManager:SetParticleControl(aegisRing, 0, target)
				ParticleManager:SetParticleControl(aegisRing, 1, Vector(radius, 0, 0))
				ParticleManager:SetParticleControl(aegisRing, 2, target)
				ParticleManager:SetParticleControl(aegisRing, 3, target)		
				-- Delete Effects
				Timers:CreateTimer({
			    	endTime = 5, 
					callback = function()
						ParticleManager:DestroyParticle(aegisRing, true)
					end
				})

				Timers:CreateTimer({
					endTime = reincarnate_time,
					callback = function()
						-- Pre LSA Particle Effect
						StartSoundEventFromPosition("Ability.PreLightStrikeArray", target)
						local preLSA = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_ABSORIGIN, caster)
						ParticleManager:SetParticleControl(preLSA, 0, target)
						ParticleManager:SetParticleControl(preLSA, 1, Vector(reducedRadius, 0, 0))
						ParticleManager:SetParticleControl(preLSA, 3, target)
						-- Aegis Respawn Effect
						local aegisRespawnTimer = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn_timer.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
						ParticleManager:SetParticleControl(aegisRespawnTimer, 0, target)
						ParticleManager:SetParticleControl(aegisRespawnTimer, 1, Vector(1, 0, 0))
						ParticleManager:SetParticleControl(aegisRespawnTimer, 2, target)
						ParticleManager:SetParticleControl(aegisRespawnTimer, 3, target)	
						local spiralPara = ParticleManager:CreateParticle("particles/items_fx/aegis_resspawn_spiralpara.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
						local spiral = ParticleManager:CreateParticle("particles/items_fx/aegis_resspawn_spiral_a.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
						-- Delete Effects
						Timers:CreateTimer({
					    	endTime = 5, 
							callback = function()
							ParticleManager:DestroyParticle(preLSA, false)
							ParticleManager:DestroyParticle(aegisRespawnTimer, false)
							ParticleManager:DestroyParticle(spiralPara, false)
							ParticleManager:DestroyParticle(spiral, false)
    						end
						})
						-- Reset ability cooldowns except for Dragon Circle
						for i = 0, 15, 1 do
							local current_ability = caster:GetAbilityByIndex(i)
							if current_ability ~= nil and current_ability:GetAbilityName() ~= "dragon_knight_dragon_circle_datadriven" then
								current_ability:EndCooldown()
							end
						end	
					end
				})
				-- Post LSA Particle Effect 
			 	Timers:CreateTimer({
				    endTime = reincarnate_time + LSADelay, 
				    callback = function()
						StartSoundEventFromPosition("Ability.LightStrikeArray", target)
						local LSA = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array_ray_team.vpcf", PATTACH_ABSORIGIN, caster)
						ParticleManager:SetParticleControl(LSA, 0, target)
						ParticleManager:SetParticleControl(LSA, 1, Vector(reducedRadius2, 0, 0))
						ParticleManager:SetParticleControl(LSA, 3, target)
						Timers:CreateTimer({
					    	endTime = 5, 
							callback = function()
							ParticleManager:DestroyParticle(LSA, false)
    						end
						})
					end
				})
	  		end
	  	end
	end
end

function respawnTimer(keys) 	-- Disables respawn when dragon circle is not active
	local caster = keys.caster
	caster:SetRespawnsDisabled(true)
end

