pudge_boss_meat_hook_lua = class({})
LinkLuaModifier( "modifier_pudge_boss_meat_hook_followthrough_lua", "libraries/modifiers/pudge_boss/modifier_pudge_boss_meat_hook_followthrough_lua.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_pudge_boss_meat_hook_lua", "libraries/modifiers/pudge_boss/modifier_pudge_boss_meat_hook_lua.lua", LUA_MODIFIER_MOTION_HORIZONTAL )

--[[Author: drdgvhbh
	Last Updated: July 30, 2016]]
--------------------------------------------------------------------------------
TARGET_TEAM = DOTA_UNIT_TARGET_TEAM_ENEMY
TARGET_TYPE = DOTA_UNIT_TARGET_HERO
TARGET_FLAGS = DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES

function pudge_boss_meat_hook_lua:OnAbilityPhaseStart()
	local tHeroesTargetChance = {}
	local flTotalDistance = 0.0
	local flChanceKey = math.random()
	local flChanceCalculator = 0.0
	self.hTarget = nil

	local tHeroes = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), 
		self:GetCaster():GetOrigin(), 
		nil, 
		self:GetLevelSpecialValueFor("hookDistance", self:GetLevel() - 1), 
		TARGET_TEAM, 
		TARGET_TYPE,
		TARGET_FLAGS,
		FIND_ANY_ORDER, 
		false
	)
	
	for k, v in pairs (tHeroes) do
		if not ( v:HasModifier( "modifier_pudge_boss_meat_hook_lua" ) or v:HasModifier( "modifier_pudge_boss_meat_hook_splinter_lua" ) )then
			local flDistance = ( self:GetCaster():GetOrigin() - v:GetOrigin() ):Length2D()
			flTotalDistance = flTotalDistance + flDistance
			table.insert( tHeroesTargetChance, k, flDistance )
		end
	end

	for k, v in pairs ( tHeroesTargetChance ) do
		tHeroesTargetChance[k] = v / flTotalDistance
	end

	for k, v in pairs ( tHeroesTargetChance ) do
		if flChanceKey >= flChanceCalculator and flChanceKey < flChanceCalculator + v then
			self.hTarget = tHeroes[k]
		else
			flChanceCalculator = flChanceCalculator + v
		end
	end

	if self.hTarget then
		self:GetCaster():StartGesture( ACT_DOTA_OVERRIDE_ABILITY_1 )
		return true
	else
		return false
	end
end

--------------------------------------------------------------------------------

function pudge_boss_meat_hook_lua:OnAbilityPhaseInterrupted()
	self:GetCaster():RemoveGesture( ACT_DOTA_OVERRIDE_ABILITY_1 )
end

function pudge_boss_meat_hook_lua:OnSpellStart()
	self:StartCooldown( self:GetCooldown( self:GetLevel() - 1 ) )
	
	self.bChainAttached = false
	if self.hVictim ~= nil then
		self.hVictim:InterruptMotionControllers( true )
	end

	self.flHookDamage = self:GetLevelSpecialValueFor( "hookDamage", self:GetLevel() - 1 )
	self.flHookSpeed = self:GetLevelSpecialValueFor( "hookSpeed", self:GetLevel() - 1 ) 
	self.iHookDistance = self:GetLevelSpecialValueFor( "hookDistance", self:GetLevel() - 1 )  
	self.iHookWidth = self:GetLevelSpecialValueFor( "hookWidth", self:GetLevel() - 1 )  
	self.flHookFollowthroughConstant = self:GetLevelSpecialValueFor( "hookFollowThroughConstant", self:GetLevel() - 1 ) 

	self.iVisionRadius = self:GetLevelSpecialValueFor( "visionRadius", self:GetLevel() - 1 )
	self.flVisionDuration = self:GetLevelSpecialValueFor( "visionDuration", self:GetLevel() - 1 )
	
	--[[if self:GetCaster() and self:GetCaster():IsHero() then
		local hHook = self:GetCaster():GetTogglableWearable( DOTA_LOADOUT_TYPE_WEAPON )
		if hHook ~= nil then
			hHook:AddEffects( EF_NODRAW )
		end
	end]]

	self.vStartPosition = self:GetCaster():GetOrigin()
	self.vProjectileLocation = self.vStartPosition

	local vDirection = self.hTarget:GetOrigin() - self.vStartPosition
	vDirection.z = 0.0
	self:GetCaster():SetForwardVector(vDirection)

	local vDirection = ( vDirection:Normalized() ) * self.iHookDistance
	self.vTargetPosition = self.vStartPosition + vDirection

	local flFollowthroughDuration = ( self.iHookDistance / self.flHookSpeed * self.flHookFollowthroughConstant )
	self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_pudge_boss_meat_hook_followthrough_lua", { duration = flFollowthroughDuration } )

	self.vHookOffset = Vector( 0, 0, 96 )
	local vHookTarget = self.vTargetPosition + self.vHookOffset
	local vKillswitch = Vector( ( ( self.iHookDistance / self.flHookSpeed ) * 2 ), 0, 0 )

	self.nChainParticleFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_pudge/pudge_meathook.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster() )
	ParticleManager:SetParticleAlwaysSimulate( self.nChainParticleFXIndex )
	ParticleManager:SetParticleControlEnt( self.nChainParticleFXIndex, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_weapon_chain_rt", self:GetCaster():GetOrigin() + self.vHookOffset, true )
	ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 1, vHookTarget )
	ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 2, Vector( self.flHookSpeed, self.iHookDistance, self.iHookWidth ) )
	ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 3, vKillswitch )
	ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 4, Vector( 1, 0, 0 ) )
	ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 5, Vector( 0, 0, 0 ) )
	ParticleManager:SetParticleControlEnt( self.nChainParticleFXIndex, 7, self:GetCaster(), PATTACH_CUSTOMORIGIN, nil, self:GetCaster():GetOrigin(), true )

	EmitSoundOn( "Hero_Pudge.AttackHookExtend", self:GetCaster() )

	local info = {
		Ability = self,
		vSpawnOrigin = self:GetCaster():GetOrigin(),
		vVelocity = vDirection:Normalized() * self.flHookSpeed,
		fDistance = self.iHookDistance,
		fStartRadius = self.iHookWidth,
		fEndRadius = self.iHookWidth,
		Source = self:GetCaster(),
		iUnitTargetTeam = TARGET_TEAM,
		iUnitTargetType = TARGET_TYPE,
		iUnitTargetFlags = TARGET_FLAGS,
	}

	ProjectileManager:CreateLinearProjectile( info )

	self.bRetracting = false
	self.hVictim = nil
	self.bDiedInHook = false
end

--------------------------------------------------------------------------------

function pudge_boss_meat_hook_lua:OnProjectileHit( hTarget, vLocation )
	if hTarget == self:GetCaster() then -- If the target is the caster then do nothing
		return false
	end

	if self.bRetracting == false then 								-- if the hook is not retracting then ...
		if hTarget ~= nil and not hTarget:IsRealHero() then -- if there exists a target and the target is a unit ( not a hero ) then, do nothing
			Msg( "Target was invalid")
			return false
		end

		local bTargetPulled = false -- 
		if hTarget ~= nil then
			EmitSoundOn( "Hero_Pudge.AttackHookImpact", hTarget )

			hTarget:AddNewModifier( self:GetCaster(), self, "modifier_pudge_boss_meat_hook_lua", nil )
			
			if hTarget:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
				local damage = {
						victim = hTarget,
						attacker = self:GetCaster(),
						damage = self.flHookDamage,
						damage_type = DAMAGE_TYPE_MAGICAL,		
						ability = self
					}

				ApplyDamage( damage )

				if not hTarget:IsAlive() then
					self.bDiedInHook = true
				end

				if not hTarget:IsMagicImmune() then
					hTarget:Interrupt()
				end
		
				local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_pudge/pudge_meathook_impact.vpcf", PATTACH_CUSTOMORIGIN, hTarget )
				ParticleManager:SetParticleControlEnt( nFXIndex, 0, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetOrigin(), true )
				ParticleManager:ReleaseParticleIndex( nFXIndex )
			end

			

			AddFOWViewer( self:GetCaster():GetTeamNumber(), hTarget:GetOrigin(), self.iVisionRadius, self.flVisionDuration, false )
			self.hVictim = hTarget
			bTargetPulled = true
		end

		local vHookPos = self.vTargetPosition
		local flPad = self:GetCaster():GetPaddedCollisionRadius()
		if hTarget ~= nil then
			vHookPos = hTarget:GetOrigin()
			flPad = flPad + hTarget:GetPaddedCollisionRadius()
		end

		--Missing: Setting target facing angle
		local vVelocity = self.vStartPosition - vHookPos
		vVelocity.z = 0.0

		local flDistance = vVelocity:Length2D() - flPad
		vVelocity = vVelocity:Normalized() * self.flHookSpeed

		local info = {
			Ability = self,
			vSpawnOrigin = vHookPos,
			vVelocity = vVelocity,
			fDistance = flDistance,
			Source = self:GetCaster(),
		}

		ProjectileManager:CreateLinearProjectile( info )

			-- Create the projectile
		--[[local info = {
		    Target = hTarget,
		    Source = self:GetCaster(),
		    Ability = self,		    
		    bDodgeable = false,
		   	EffectName = "particles/units/heroes/hero_abaddon/abaddon_death_coil.vpcf",
		    bProvidesVision = true,
		    iMoveSpeed = self.flHookSpeed,
		    iVisionRadius = 0,
		    iVisionTeamNumber = self:GetCaster():GetTeamNumber()
		}
		ProjectileManager:CreateTrackingProjectile( info )]]--
		self.vProjectileLocation = vHookPos

		if hTarget ~= nil and ( not hTarget:IsInvisible() ) and bTargetPulled then
			ParticleManager:SetParticleControlEnt( self.nChainParticleFXIndex, 1, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetOrigin() + self.vHookOffset, true )
			ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 4, Vector( 0, 0, 0 ) )
			ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 5, Vector( 1, 0, 0 ) )
		else
			ParticleManager:SetParticleControlEnt( self.nChainParticleFXIndex, 1, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_weapon_chain_rt", self:GetCaster():GetOrigin() + self.vHookOffset, true);
		end

		EmitSoundOn( "Hero_Pudge.AttackHookRetract", hTarget )

		if self:GetCaster():IsAlive() then
			self:GetCaster():RemoveGesture( ACT_DOTA_OVERRIDE_ABILITY_1 );
			self:GetCaster():StartGesture( ACT_DOTA_CHANNEL_ABILITY_1 );
		end

		self.bRetracting = true
	else
		--[[if self:GetCaster() and self:GetCaster():IsHero() then
			local hHook = self:GetCaster():GetTogglableWearable( DOTA_LOADOUT_TYPE_WEAPON )
			if hHook ~= nil then
				hHook:RemoveEffects( EF_NODRAW )
			end
		end]]

		if self.hVictim ~= nil then
			local vFinalHookPos = vLocation
			self.hVictim:InterruptMotionControllers( true )
			self.hVictim:RemoveModifierByName( "modifier_pudge_boss_meat_hook_lua" )

			local vVictimPosCheck = self.hVictim:GetOrigin() - vFinalHookPos 
			local flPad = self:GetCaster():GetPaddedCollisionRadius() + self.hVictim:GetPaddedCollisionRadius()
			if vVictimPosCheck:Length2D() > flPad then
				FindClearSpaceForUnit( self.hVictim, self.vStartPosition, false )
			end
		end

		self.hVictim = nil
		ParticleManager:DestroyParticle( self.nChainParticleFXIndex, true )
		EmitSoundOn( "Hero_Pudge.AttackHookRetractStop", self:GetCaster() )
	end

	return true
end

--------------------------------------------------------------------------------

function pudge_boss_meat_hook_lua:OnProjectileThink( vLocation )
	self.vProjectileLocation = vLocation
end

--------------------------------------------------------------------------------

function pudge_boss_meat_hook_lua:OnOwnerDied()
	self:GetCaster():RemoveGesture( ACT_DOTA_OVERRIDE_ABILITY_1 );
	self:GetCaster():RemoveGesture( ACT_DOTA_CHANNEL_ABILITY_1 );
end

--------------------------------------------------------------------------------
