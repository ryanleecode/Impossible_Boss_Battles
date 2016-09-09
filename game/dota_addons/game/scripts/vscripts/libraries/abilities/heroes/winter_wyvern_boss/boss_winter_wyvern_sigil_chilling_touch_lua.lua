boss_winter_wyvern_sigil_chilling_touch_lua = class({})

--[[Author: drdgvhbh
	Last Updated: August 16, 2016]]

DEBUG = true 				-- Debug Flag to print messages to Console

LAUNCH_INTERVAL = 0.25		-- Rate at which projectiles are launched
ONE_FRAME = 1 / 30			-- One frame, assuming 30 fps

function boss_winter_wyvern_sigil_chilling_touch_lua:OnSpellStart()
	-- simple counter used to repeat the spell
	local flTimer = 0
	
	if IsServer() then 
		Timers:CreateTimer(function()
			-- Find units to hit in a given radius
			local tUnits = FindUnitsInRadius( 
				self:GetCaster():GetTeamNumber(), 
				self:GetCaster():GetAbsOrigin(), 
				nil, 
				self:GetLevelSpecialValueFor( "iRadius", self:GetLevel() - 1 ), 
				self:GetAbilityTargetTeam(), 
				self:GetAbilityTargetType(), 
				self:GetAbilityTargetFlags(), 
				FIND_ANY_ORDER, 
				false
			) 


			if table.getn( tUnits ) > 0 and self:GetCaster():IsAlive() then 
				-- Launch the projectile at a random unit within range
				boss_winter_wyvern_sigil_chilling_touch_lua:LaunchProjectile( self, tUnits[ RandomInt( 1, table.getn( tUnits ) ) ] )
				if flTimer == 0 then 
					-- Emit an attack sound for the first projectile
					EmitSoundOn( "Hero_Lich.Attack", self:GetCaster() )
				end
			end

			flTimer = flTimer + LAUNCH_INTERVAL
			-- Keeps launching projectiles until a set number has been reached
			if flTimer < self:GetLevelSpecialValueFor( "iNumber", self:GetLevel() - 1 ) * LAUNCH_INTERVAL then 
		    	return LAUNCH_INTERVAL
		    else
		    	return nil
		    end

    	end
  		)	
	end
end

function boss_winter_wyvern_sigil_chilling_touch_lua:LaunchProjectile( ability, hTarget )
	-- Speed of the projectile
	ability.iSpeed = ability:GetLevelSpecialValueFor( "iSpeed", ability:GetLevel() - 1 )
	-- used to destroy the particle a couple of frames earlier to sync with the projectle impact on the ground
	ability.iFrames = ability:GetLevelSpecialValueFor( "iFrames", ability:GetLevel() - 1 )
	-- width of the projectile
	ability.iWidth = ability:GetLevelSpecialValueFor( "iWidth", ability:GetLevel() - 1 )

	-- the index used for each individual particle
	local iIndex

	if not ability.nFXIndex then
		ability.nFXIndex = {}
		iIndex = 0
	else 
		-- overwrite indices that do not have a particle
		for k, v in pairs( ability.nFXIndex ) do
			if not v then 
				iIndex = k
			end
		end
	end

	-- define iIndex in a new index slot if there is nothing to overwrite
	if not iIndex then 
		iIndex = table.getn( ability.nFXIndex ) + 1
	end

	-- location of the caster
	local vOrigin = ability:GetCaster():GetAbsOrigin()

	if ability:GetCaster():FindModifierByName("modifier_flying_control") then
		-- GetAbsOrigin only gives the ground height and therefore, we need to adjust the z position to match the height 
		vOrigin.z = vOrigin.z + ability:GetCaster():FindModifierByName("modifier_flying_control"):GetVisualZDelta()
	end

	-- where the projectile is headed
	local vEndPosition = hTarget:GetAbsOrigin()

	-- Time it takes for the projectile to reach the ground, assuming it hits nothing
	local duration = ( vEndPosition - vOrigin ):Length() / ability.iSpeed - ability.iFrames * ONE_FRAME

	if not hTarget:IsIdle() and not hTarget:IsChanneling() then		
		-- Projects the target's movement and sets the target to that location. 
		vEndPosition = vEndPosition + hTarget:GetForwardVector() * hTarget:GetIdealSpeed() * duration
	end

	local tInfo = {
		Ability = ability,
        vSpawnOrigin = vOrigin,
        fDistance = ( vEndPosition - vOrigin ):Length(),
    	fStartRadius = ability.iWidth,
    	fEndRadius = ability.iWidth,
    	Source = ability:GetCaster(),
    	bHasFrontalCone = false,
    	bReplaceExisting = false,
    	iUnitTargetTeam = ability:GetAbilityTargetTeam(),
    	iUnitTargetType = ability:GetAbilityTargetType(),
    	iUnitTargetFlags = ability:GetAbilityTargetFlags(),
    	fExpireTime = GameRules:GetGameTime() + 10.0,
		bDeleteOnHit = true,
		vVelocity = ( vEndPosition - vOrigin ):Normalized() * ability.iSpeed,
		bProvidesVision = false,
		iVisionRadius = 0,
		iVisionTeamNumber = ability:GetCaster():GetTeamNumber(),
		ExtraData = {iIndex}
	}

	hProjectile = ProjectileManager:CreateLinearProjectile( tInfo )
	
	-- The vector that is to be added on the caster's location vector
	local vVelocity = ( vEndPosition - vOrigin ):Normalized() * ( vEndPosition - vOrigin ):Length()
	-- no idea ... probably useless
	local vKillswitch = Vector( ( ( ( vEndPosition - vOrigin ):Length() / ability:GetLevelSpecialValueFor( "iSpeed", 
ability:GetLevel() - 1 ) ) * 2 ), 0, 0 )

	-- projectile particle
	ability.nFXIndex[iIndex] = ParticleManager:CreateParticle( "particles/units/heroes/hero_lich/lich_base_attack.vpcf", PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleAlwaysSimulate( ability.nFXIndex[iIndex] )
	--[[Particle Control Description
		
		0			Starting Position
		1			End Position
		2 			Vector( Speed, Distance, Width )
		3			Vector ( Distance / 2 * Speed, 0, 0) -- probably useless
	]]
	ParticleManager:SetParticleControlEnt( ability.nFXIndex[iIndex], 0, ability:GetCaster(), PATTACH_POINT_FOLLOW, nil, vOrigin, true ) 
	ParticleManager:SetParticleControl( ability.nFXIndex[iIndex], 1, vOrigin + vVelocity )
	ParticleManager:SetParticleControl( ability.nFXIndex[iIndex], 2, Vector( ability.iSpeed, 
( vEndPosition - vOrigin ):Length(), ability.iWidth ) )
	ParticleManager:SetParticleControl( ability.nFXIndex[iIndex], 3, vKillswitch )

	-- recalculate the projectile duration if the target was not idle or channeling
	duration = ( vEndPosition - vOrigin ):Length() / ability.iSpeed - ability.iFrames * ONE_FRAME

	Timers:CreateTimer({
	    endTime = duration,
	    callback = function()
	   		if ability.nFXIndex[iIndex] then
	   			-- assuming the particle did not hit a unit, it is immediately destroyed when it hits the ground
				ParticleManager:DestroyParticle( ability.nFXIndex[iIndex], true )
				ability.nFXIndex[iIndex] = nil
			end
	    end
	})
end

function boss_winter_wyvern_sigil_chilling_touch_lua:OnProjectileHit_ExtraData( hTarget, vLocation, table ) 
	if hTarget and IsServer() then 
		local tDamageTable = {
			victim = hTarget,
			attacker = self:GetCaster(),
			damage = self:GetLevelSpecialValueFor( "iDamage", self:GetLevel() - 1 ),
			damage_type = self:GetAbilityDamageType(),
		}

		ApplyDamage(tDamageTable)

		-- projectile impact sounds
		EmitAnnouncerSoundForPlayer( "Damage_Projectile.Player", hTarget:GetOwner():GetPlayerID() )
		EmitSoundOn( "Hero_Lich.ProjectileImpact", hTarget )

		-- setting the location for the impact particle
		local vTarget = vLocation
		vTarget.z = hTarget:GetAbsOrigin().z + 128

		-- create the impact particle
		local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_lich/lich_base_attack_explosion.vpcf", PATTACH_POINT, hTarget )
		ParticleManager:SetParticleControl( nFXIndex, 3, vTarget )

		-- data used to destroy the projectile particle when it hits a unit
		local iIndex
		for k, v in pairs(table) do
			iIndex = v
		end
		
		if self.nFXIndex[iIndex] then
			ParticleManager:DestroyParticle( self.nFXIndex[iIndex], true )
			self.nFXIndex[iIndex] = nil
		end
	end
end
