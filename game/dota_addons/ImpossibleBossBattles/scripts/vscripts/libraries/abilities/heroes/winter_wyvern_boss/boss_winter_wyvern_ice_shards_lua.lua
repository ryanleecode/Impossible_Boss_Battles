boss_winter_wyvern_ice_shards_lua = class({})	

function boss_winter_wyvern_ice_shards_lua:OnAbilityPhaseStart()
	if not IsServer() then return false end
	self:GetCaster():StartGestureWithPlaybackRate( ACT_DOTA_CAST_ABILITY_3, 1.0 )
	return true
end

function boss_winter_wyvern_ice_shards_lua:OnAbilityPhaseInterrupted()
	if not IsServer() then return end
	self:GetCaster():RemoveGesture( ACT_DOTA_CAST_ABILITY_3 )
end

function boss_winter_wyvern_ice_shards_lua:OnChannelFinish( bInterrupted )
	if not IsServer() or bInterrupted then 
		self:GetCaster():RemoveGesture( ACT_DOTA_CAST_ABILITY_3 )
		return
	end

	self.iSpeed = self:GetLevelSpecialValueFor( "shardSpeed", self:GetLevel() - 1 )
	self.iDistance = self:GetLevelSpecialValueFor( "maximumDistance", self:GetLevel() - 1 )
	self.iProjectileRadius = self:GetLevelSpecialValueFor( "projectileRadius", self:GetLevel() - 1 )
	self.iVisionRadius = self:GetLevelSpecialValueFor( "visionRadius", self:GetLevel() - 1 )
	self.iShardRadius = self:GetLevelSpecialValueFor( "shardRadius", self:GetLevel() - 1 )
	self.flShardAngleStep = self:GetLevelSpecialValueFor( "shardAngleStep", self:GetLevel() - 1 ) * math.pi / 180 
	self.iShardCount = self:GetLevelSpecialValueFor( "shardCount", self:GetLevel() - 1 )
	self.flShardDuration = self:GetLevelSpecialValueFor( "shardDuration", self:GetLevel() - 1 )
	self.iShardDamage = self:GetLevelSpecialValueFor( "shardDamage", self:GetLevel() - 1 )
	self.inumOfProjectiles = self:GetLevelSpecialValueFor( "numOfProjectiles", self:GetLevel() - 1 )


	local vFirstShard = self:GetCaster():GetForwardVector()

	for i = 0, self.inumOfProjectiles - 1, 1 do
		boss_winter_wyvern_ice_shards_lua:CreateShards( self, boss_winter_wyvern_ice_shards_lua:SetProjectileDirection( self, QAngle( 0, i * 360 / self.inumOfProjectiles, 
														0 ), vFirstShard ) ) 
	end

	EmitSoundOnLocationWithCaster( self:GetCaster():GetAbsOrigin(), "Hero_Tusk.IceShards.Cast.Penguin", self:GetCaster() )
	EmitSoundOnLocationWithCaster( self:GetCaster():GetAbsOrigin(), "Hero_Tusk.IceShards.Projectile", self:GetCaster() )
end

function boss_winter_wyvern_ice_shards_lua:SetProjectileDirection( self, QAngle, vOrigin )
	return RotatePosition( Vector( 0,0,0 ), QAngle, vOrigin )
end

function boss_winter_wyvern_ice_shards_lua:CreateShards( self, vDirection ) 
	local prShard = ParticleManager:CreateParticle( "particles/econ/items/tuskarr/tusk_ti5_immortal/tusk_ice_shards_projectile_stout.vpcf", PATTACH_CUSTOMORIGIN, 
					nil )
	ParticleManager:SetParticleControl( prShard, 0, self:GetCaster():GetAbsOrigin() )
	local vSpeedVector = vDirection * self.iSpeed
	ParticleManager:SetParticleControl( prShard, 1, vSpeedVector )

	-- Time it takes for projectile/particle to reach destination (assuming it hits nothing)
	local flTime = self.iDistance / self.iSpeed

	local tInfo = 
	{
		Ability = self,
		--EffectName = "particles/econ/items/mirana/mirana_crescent_arrow/mirana_spell_crescent_arrow.vpcf",
    	vSpawnOrigin = self:GetCaster():GetAbsOrigin(),
    	fDistance = self.iDistance,
    	fStartRadius = self.iProjectileRadius,
    	fEndRadius = self.iProjectileRadius,
    	Source = self:GetCaster(),
    	bHasFrontalCone = false,
    	bReplaceExisting = false,
    	iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
    	iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NO_INVIS,
    	iUnitTargetType = DOTA_UNIT_TARGET_HERO,
    	fExpireTime = GameRules:GetGameTime() + flTime,
		bDeleteOnHit = true,
		vVelocity = vDirection * self.iSpeed,
		bProvidesVision = true,
		iVisionRadius = 300,
		iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
		ExtraData = { prShard, vDirection.x, vDirection.y }
	}

	local projectile = ProjectileManager:CreateLinearProjectile( tInfo )

end


function boss_winter_wyvern_ice_shards_lua:OnProjectileHit_ExtraData( hTarget, vLocation, table ) 
	local prParticle 
	local vFwdVector = Vector(0, 0, 0)
	--DeepPrintTable( table )

	-- Assign particle number and create the forward vector since we cant pass the vector directly through extra data
	for k,v in pairs( table ) do
		if k == "1" then
			prParticle = v
		elseif k == "2" then
			vFwdVector = Vector(v, vFwdVector.y, 0)
		elseif k == "3" then
			vFwdVector = Vector(vFwdVector.x, v, 0)
		end
	end

	if not hTarget then 
		ParticleManager:DestroyParticle( prParticle, false )
		return 
	end

	EmitSoundOnLocationWithCaster( hTarget:GetAbsOrigin(), "Hero_Tusk.IceShards", hTarget )

	-- Delay to destroy the particle, since the projectile will end before it reaches the target
	local timeOffset = self.iProjectileRadius / self.iSpeed 
	Timers:CreateTimer( timeOffset, function()
		ParticleManager:DestroyParticle( prParticle, false )
	end)



	local prShard = ParticleManager:CreateParticle( "particles/units/heroes/hero_tusk/tusk_ice_shards.vpcf", PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleControl( prShard, 0, Vector( self.flShardDuration,0,0 ) )

	--Direction of the ice shards
	local flRotation = boss_winter_wyvern_ice_shards_lua:IceShardsCircleRotation( vFwdVector )

	if self.iShardCount % 2 == 1 then 
		ParticleManager:SetParticleControl( prShard, 1, boss_winter_wyvern_ice_shards_lua:IceShardsVC( self, 0 * self.flShardAngleStep, 
											flRotation, hTarget ) )

		for i = 1, (self.iShardCount - 1) / 2, 1 do 
			ParticleManager:SetParticleControl( prShard, i + 1, boss_winter_wyvern_ice_shards_lua:IceShardsVC( self, i * self.flShardAngleStep, flRotation, hTarget ) )
			ParticleManager:SetParticleControl( prShard, self.iShardCount + 1 - i, boss_winter_wyvern_ice_shards_lua:IceShardsVC( self, -i * self.flShardAngleStep,
												flRotation, hTarget ) )
		end
	end

	ApplyDamage( { victim = hTarget, attacker = self:GetCaster(), damage = self.iShardDamage, ability = self, damage_type = DAMAGE_TYPE_MAGICAL} )
end

-- Sets the vector control for the ice shard particle and create the pathing blocker
function boss_winter_wyvern_ice_shards_lua:IceShardsVC( self, flAngle, flRotation, hTarget )
	local v = hTarget:GetAbsOrigin() + Vector( math.cos( flRotation ) * math.cos( flAngle ) * self.iShardRadius - math.sin( flRotation ) * math.sin( flAngle ) * 
											self.iShardRadius, math.sin( flRotation ) * math.cos( flAngle ) * self.iShardRadius + math.cos( flRotation ) * 
											math.sin( flAngle ) * self.iShardRadius, 0 )
	local entObstruction = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = v})
	-- not sure what second parameter does
	entObstruction:SetEnabled( true, true )
	Timers:CreateTimer( self.flShardDuration, function()
		entObstruction:Destroy()
	end)
	return v
end

-- the direction that the ice shards is facing
function boss_winter_wyvern_ice_shards_lua:IceShardsCircleRotation( vFwdVector )
	if vFwdVector.x > 0 and vFwdVector.y > 0 then 
		return math.pi * 2 + math.atan( vFwdVector.y / vFwdVector.x )
	elseif vFwdVector.x < 0 and vFwdVector.y > 0 then
	 	return math.pi + math.atan( vFwdVector.y / vFwdVector.x )
	elseif vFwdVector.x < 0 and vFwdVector.y < 0 then
	 	return math.pi + math.atan( vFwdVector.y / vFwdVector.x )
	else
		return math.pi * 2 + math.atan( vFwdVector.y / vFwdVector.x )
	end
end