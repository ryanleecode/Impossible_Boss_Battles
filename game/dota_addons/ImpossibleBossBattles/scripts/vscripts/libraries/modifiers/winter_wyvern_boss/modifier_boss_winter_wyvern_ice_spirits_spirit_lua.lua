modifier_boss_winter_wyvern_ice_spirits_spirit_lua = class({}) 

function modifier_boss_winter_wyvern_ice_spirits_spirit_lua:OnCreated( keys )
	if not IsServer() then return end
	-- Movement logic for each spirit
	-- Units have 4 states: 
		-- acquiring: transition after completing one target-return cycle.
		-- target_acquired: tracking an enemy or point to collide
		-- returning: After colliding with an enemy, move back to the casters location
		-- end: moving back to the caster to be destroyed and heal

	self.iSpiritSpeed = self:GetAbility():GetLevelSpecialValueFor( "spiritSpeed", self:GetAbility():GetLevel() - 1 )
	self.flMinTimeBetweenAttacks = self:GetAbility():GetLevelSpecialValueFor( "minTimeBetweenAttacks", self:GetAbility():GetLevel() - 1 )
	self.iRadius = self:GetAbility():GetLevelSpecialValueFor( "radius", self:GetAbility():GetLevel() - 1 )
	self.iMaxDistance = self:GetAbility():GetLevelSpecialValueFor( "maxDistance", self:GetAbility():GetLevel() - 1 )

	local pSpiritGlow = ParticleManager:CreateParticle( "particles/units/heroes/hero_death_prophet/death_prophet_spirit_glow.vpcf", PATTACH_ABSORIGIN_FOLLOW, 
						self:GetParent() )
	ParticleManager:SetParticleControl( pSpiritGlow, 0, self:GetParent():GetAbsOrigin() )
	ParticleManager:SetParticleControl( pSpiritGlow, 1, self:GetParent():GetAbsOrigin() )	
	print( self:GetParent():GetAbsOrigin() )

	local pSpiritModel = ParticleManager:CreateParticle( "particles/units/heroes/hero_death_prophet/death_prophet_spirit_model.vpcf", PATTACH_ABSORIGIN_FOLLOW, 
						 self:GetParent() )
	ParticleManager:SetParticleControl( pSpiritModel, 0, self:GetParent():GetAbsOrigin() )
	ParticleManager:SetParticleControl( pSpiritModel, 1, self:GetParent():GetAbsOrigin() )	
	ParticleManager:SetParticleControl( pSpiritModel, 2, self:GetParent():GetAbsOrigin() )	

	Physics:Unit( self:GetParent() )

	-- General properties
	self:GetParent():PreventDI( true )
	self:GetParent():SetAutoUnstuck( false )
	self:GetParent():SetNavCollisionType( PHYSICS_NAV_NOTHING )
	self:GetParent():FollowNavMesh( false )
	self:GetParent():SetPhysicsVelocityMax( self.iSpiritSpeed )
	self:GetParent():SetPhysicsVelocity( self.iSpiritSpeed * RandomVector( 1 ) )
	self:GetParent():SetPhysicsFriction( 0 )
	self:GetParent():Hibernate( false )
	self:GetParent():SetGroundBehavior( PHYSICS_GROUND_LOCK )

	-- Initial default state
	self:GetParent().sState = "acquiring"

	-- This is to skip frames
	local iFrameCount = 0

	-- Store the damage done
	self:GetParent().flDamageDone = 0

	-- Store the interval between attacks, starting at min_time_between_attacks
	self:GetParent().timeSinceLastAttack = GameRules:GetGameTime() - self.flMinTimeBetweenAttacks

	-- Color Debugging for points and paths. Turn it false later!
	local bDebug = true
	local vPathColor = Vector( 0,0,0 ) -- black to draw path
	local vTargetColor = Vector( 255,0,0 ) -- Red for enemy targets
	local vIdleColor = Vector( 0,255,0 ) -- Green for moving to idling points
	local vReturnColor = Vector( 0,0,255 ) -- Blue for the return
	local vEndColor = Vector( 0,0,0 ) -- Back when returning to the caster to end
	local flDraw_duration = 3.0

	-- Find one target point at random which will be used for the first acquisition.
	local vPoint = self:GetAbility():GetCaster():GetAbsOrigin() + RandomVector( RandomInt( self.iRadius/2, self.iRadius ) )
	vPoint.z = GetGroundHeight( vPoint, nil )


	-- doesnt like self:GetParent() so using unit variable
	local unit = self:GetParent()
	-- This is set to repeat on each frame
	self:GetParent():OnPhysicsFrame( function( unit )

		-- Move the unit orientation to adjust the particle
		self:GetParent():SetForwardVector( ( self:GetParent():GetPhysicsVelocity() ):Normalized() )

		-- Current positionsz
		local vSource = self:GetAbility():GetCaster():GetAbsOrigin()
		local vCurrentPosition = self:GetParent():GetAbsOrigin()

		-- Print the path on Debug mode
		if bDebug then 
			DebugDrawCircle( vCurrentPosition, vPathColor, 0, 2, true, flDraw_duration ) 
		end

		-- Use this if skipping frames is needed (--if frameCount == 0 then..)
		iFrameCount = ( iFrameCount + 1) % 3


		-- Movement and Collision detection are state independent

		-- MOVEMENT	
		-- Get the direction
		local vDirection = ( vPoint - self:GetParent():GetAbsOrigin() ):Normalized()
        vDirection.z = 0

		-- Calculate the angle difference
		local flAngleDifference = RotationDelta( VectorToAngles(self:GetParent():GetPhysicsVelocity():Normalized() ), VectorToAngles( vDirection ) ).y

		-- Set the new velocity
		if math.abs( flAngleDifference ) < 5 then
			-- CLAMP
			local vNewVel = self:GetParent():GetPhysicsVelocity():Length() * vDirection
			self:GetParent():SetPhysicsVelocity( vNewVel )
		elseif flAngleDifference > 0 then
			local vNewVel = RotatePosition( Vector(0,0,0), QAngle(0,10,0), self:GetParent():GetPhysicsVelocity() )
			self:GetParent():SetPhysicsVelocity( vNewVel )
		else		
			local vNewVel = RotatePosition( Vector(0,0,0), QAngle(0,-10,0), self:GetParent():GetPhysicsVelocity() )
			self:GetParent():SetPhysicsVelocity( vNewVel )
		end

		-- COLLISION CHECK
		local flDistance = ( vPoint - self:GetParent():GetAbsOrigin() ):Length()
		local bCollision = flDistance < 50

		-- MAX DISTANCE CHECK
		local flDistanceToCaster = ( vSource - self:GetParent():GetAbsOrigin() ):Length()
		if flDistance > self.iMaxDistance then 
			self:GetParent():SetAbsOrigin( vSource )
			self:GetParent().state = "acquiring" 
		end
	end)
end

function modifier_boss_winter_wyvern_ice_spirits_spirit_lua:CheckState()
	if not IsServer() then return end

	local hState = {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_FLYING] = true,
		[MODIFIER_STATE_DISARMED] = true
	}

	return hState
end

