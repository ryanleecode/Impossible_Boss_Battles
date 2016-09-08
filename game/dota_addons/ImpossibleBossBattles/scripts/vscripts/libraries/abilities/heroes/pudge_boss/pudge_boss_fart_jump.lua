DEBUG = true-- Debug Flag to print messages to Console

function pudge_boss_fart_jump(keys)
	local caster = keys.caster
	local ability = keys.ability
	ability.origin = caster:GetAbsOrigin()
	local rotDuration = ability:GetLevelSpecialValueFor("rotDuration", ability:GetLevel() - 1) 
	local randomSound = math.random(7)
	local soundString = "pudge_pud_pain_0"..randomSound 
	-- Get the ability Target Types
	local targetTeams = ability:GetAbilityTargetTeam()
	local targetTypes = ability:GetAbilityTargetType()
	local targetFlags = ability:GetAbilityTargetFlags()
	-- Find the furthest hero
	local heroes = HeroList:GetAllHeroes()
	local distance = 0
	ability.target = {
		[1] = nil
	}
	local counter = 1
	for k, v in pairs (heroes) do
		local pass = UnitFilter(v, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED, DOTA_TEAM_GOODGUYS)
		if pass == 1 and (ability.origin - v:GetAbsOrigin()):Length2D() > distance and v:IsAlive() == true then
			distance = (ability.origin - v:GetAbsOrigin()):Length2D()
			ability.target[1] = v
		end		
	end
	if ability.target[1] ~= nil then 
		local order = 
			{
				UnitIndex = caster:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
				TargetIndex = ability.target[1]:entindex()
			}
		ExecuteOrderFromTable(order)
		Timers:CreateTimer({
		    endTime = 0.001, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
		    callback = function()
		    	caster:Stop()
		  	end
		})
		EmitSoundOn(soundString, caster)
		EmitSoundOn("Hero_Pudge.Rot", caster)
		Timers:CreateTimer({
		    endTime = rotDuration, 
		    callback = function()  
		      caster:StopSound( "Hero_Pudge.Rot" )
		    end
	  	})
		ability:ApplyDataDrivenThinker(caster, ability.origin, "fart_thinker", {duration = rotDuration})
		ProjectileManager:ProjectileDodge(caster)
		ability.targetVector = ability.target[1]:GetAbsOrigin()
		ability.fartDirection = (ability.targetVector - ability.origin):Normalized()
		ability.fartDistance = CalcDistanceBetweenEntityOBB(ability.target[1], caster)
		--ability.fartSpeed = 600 * 1/30
		ability.fartSpeed = ability:GetLevelSpecialValueFor("fartSpeed", ability:GetLevel() - 1) * 1/30
		ability.fartTraveled = 0
		ability.fartZ = 0
		caster:SetForwardVector(ability.fartDirection)
		caster:StartGestureWithPlaybackRate( ACT_DOTA_FLAIL , 2)
		debugPrint("Distance "..ability.fartDistance, DEBUG)
		debugPrint("Speed "..ability.fartSpeed * 30, DEBUG)
		debugPrint("duration "..ability.fartDistance/(ability.fartSpeed * 30), DEBUG)
		ability.duration = (ability.fartDistance/(ability.fartSpeed * 30))
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_fart_jumping", {duration = ability.duration}) 
	end
end

--[[Moves the caster on the horizontal axis until it has traveled the distance]]
function fartHorizonal( keys )
	local caster = keys.target
	local ability = keys.ability

	if ability.fartTraveled < ability.fartDistance and ability.target[1] ~= nil then
		caster:SetAbsOrigin(caster:GetAbsOrigin() + ability.fartDirection * ability.fartSpeed)
		ability.fartTraveled = ability.fartTraveled + ability.fartSpeed
	else
		caster:InterruptMotionControllers(true)
		OnImpact(keys)
	end
end

--[[Moves the caster on the vertical axis until movement is interrupted]]
function fartVertical( keys )
	local caster = keys.target
	local ability = keys.ability

	if ability.target[1] ~= nil then 

		-- For the first half of the distance the unit goes up and for the second half it goes down
		if ability.fartTraveled < ability.fartDistance/2 then
			-- Go up
			-- This is to memorize the z point when it comes to cliffs and such although the division of speed by 2 isnt necessary, its more of a cosmetic thing
			ability.fartZ = ability.fartZ + ability.fartSpeed/2
			-- Set the new location to the current ground location + the memorized z point
			caster:SetAbsOrigin(GetGroundPosition(caster:GetAbsOrigin(), caster) + Vector(0,0,ability.fartZ))
		else
			-- Go down
			ability.fartZ = ability.fartZ - ability.fartSpeed/2
			caster:SetAbsOrigin(GetGroundPosition(caster:GetAbsOrigin(), caster) + Vector(0,0,ability.fartZ))
		end
	end
end

function OnImpact(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = caster:GetAbsOrigin()
	local targetTeams = ability:GetAbilityTargetTeam()
	local radius = ability:GetLevelSpecialValueFor("landRadius", ability:GetLevel() - 1) 
	local maximumDamage = ability:GetLevelSpecialValueFor("maximumLandDamage", ability:GetLevel() - 1) 
	if ability.target[1] ~= nil then
		local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_elder_titan/elder_titan_echo_stomp_physical.vpcf", PATTACH_ABSORIGIN, caster )
		local nFXIndex2 = ParticleManager:CreateParticle( "particles/units/heroes/hero_undying/undying_decay.vpcf", PATTACH_ABSORIGIN, caster )
		ParticleManager:SetParticleControl(nFXIndex, 0,  target )
		caster:RemoveGesture(ACT_DOTA_FLAIL)
		EmitSoundOnLocationWithCaster(target, "Hero_ElderTitan.EchoStomp", caster)
		local units = FindUnitsInRadius(caster:GetTeamNumber(), target, nil, radius, targetTeams, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for k, v in pairs(units) do
			local enemyPosition = v:GetAbsOrigin()
			local distance = CalcDistanceBetweenEntityOBB(v, caster)
			local damageTable = {
				victim = v,
				attacker = caster,
				damage = (1 - distance/radius) * maximumDamage,
				damage_type = DAMAGE_TYPE_MAGICAL,
				ability = ability
			} 
			ApplyDamage(damageTable)
		end
	end
end

