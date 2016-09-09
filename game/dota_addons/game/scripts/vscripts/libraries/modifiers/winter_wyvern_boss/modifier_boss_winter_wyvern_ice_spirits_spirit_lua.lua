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
	self.iGiveUpDistance = self:GetAbility():GetLevelSpecialValueFor( "giveUpDistance", self:GetAbility():GetLevel() - 1 )

	self.iMinDamage = self:GetAbility():GetLevelSpecialValueFor( "minDamage", self:GetAbility():GetLevel() - 1 )
	self.iMaxDamage = self:GetAbility():GetLevelSpecialValueFor( "maxDamage", self:GetAbility():GetLevel() - 1 )

	self.pParticleDamage = "particles/units/heroes/hero_death_prophet/death_prophet_exorcism_attack.vpcf"
	self.pParticleDamageBuilding = "particles/units/heroes/hero_death_prophet/death_prophet_exorcism_attack_building.vpcf"

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
	self:GetParent().lastArrackTime = GameRules:GetGameTime() - self.flMinTimeBetweenAttacks

	-- Color Debugging for points and paths. Turn it false later!
	self.bDebug = true
	self.vPathColor = Vector( 0,0,0 ) -- black to draw path
	self.vTargetColor = Vector( 255,0,0 ) -- Red for enemy targets
	self.vIdleColor = Vector( 0,255,0 ) -- Green for moving to idling points
	self.vReturnColor = Vector( 0,0,255 ) -- Blue for the return
	self.vEndColor = Vector( 0,0,0 ) -- Back when returning to the caster to end
	self.flDraw_duration = 3.0

	-- Find one target point at random which will be used for the first acquisition.
	self:GetParent().vPoint = self:GetAbility():GetCaster():GetAbsOrigin() + RandomVector( RandomInt( self.iRadius/2, self.iRadius ) )
	self:GetParent().vPoint.z = GetGroundHeight( self:GetParent().vPoint, nil )


	-- doesnt like self:GetParent() so using unit variable
	local unit = self:GetParent()
	-- This is set to repeat on each frame
	self:GetParent():OnPhysicsFrame( function( unit )

		-- Move the unit orientation to adjust the particle
		self:GetParent():SetForwardVector( ( self:GetParent():GetPhysicsVelocity() ):Normalized() )

		-- Current positions
		local self.vSource = self:GetAbility():GetCaster():GetAbsOrigin()
		local vCurrentPosition = self:GetParent():GetAbsOrigin()

		-- Print the path on Debug mode
		if self.bDebug then 
			DebugDrawCircle( vCurrentPosition, vPathColor, 0, 2, true, flDraw_duration ) 
		end

		self:GetParent().hEnemies = nil

		-- Use this if skipping frames is needed (--if frameCount == 0 then..)
		iFrameCount = ( iFrameCount + 1) % 3


		-- Movement and Collision detection are state independent

		-- MOVEMENT	
		-- Get the direction
		local vDirection = ( self:GetParent().vPoint - self:GetParent():GetAbsOrigin() ):Normalized()
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
		local flDistance = ( self:GetParent().vPoint - self:GetParent():GetAbsOrigin() ):Length()
		self:GetParent().bCollision = flDistance < 50

		-- MAX DISTANCE CHECK
		self:GetParent().flDistanceToCaster = ( self.vSource - self:GetParent():GetAbsOrigin() ):Length()
		if flDistance > self.iMaxDistance then 
			self:GetParent():SetAbsOrigin( self.vSource )
			self:GetParent().sState = "acquiring" 
		end

		-- STATE DEPENDENT LOGIC
		-- Damage, Healing and Targeting are state dependent.
		-- Update the point in all frames

		-- Acquiring...
		-- Acquiring -> Target Acquired (enemy or idle point)
		-- Target Acquired... if collision -> Acquiring or Return
		-- Return... if collision -> Acquiring

		
		if self:GetParent().sState == "acquiring" then
			modifier_boss_winter_wyvern_ice_spirits_spirit_lua:AcquiringState( self )
		else if self:GetParent().sState == "target_acquired" then
			modifier_boss_winter_wyvern_ice_spirits_spirit_lua:AcquiredState( self )
		elseif self:GetParent().state == "returning" then
			modifier_boss_winter_wyvern_ice_spirits_spirit_lua:ReturningState( self )
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

--[[Acquiring finds new targets and changes state to target_acquired with a current_target if it finds enemies or nil and a 
	random point if there are no enemies]]
function modifier_boss_winter_wyvern_ice_spirits_spirit_lua:AcquiringState( self )

	-- This is to prevent attacking the same target very fast
	local flTimeBetweenLastAttack = GameRules:GetGameTime() - self:GetParent().lastArrackTime 
	--print("Time Between Last Attack: "..flTimeBetweenLastAttack)

	-- If enough time has passed since the last attack, attempt to acquire an enemy
	if flTimeBetweenLastAttack >= self.flMinTimeBetweenAttacks then
		-- If the unit doesn't have a target locked, find enemies near the caster
		self:GetParent().hEnemies = FindEnemiesInRadius( self:GetParent(), self.iRadius )

		local hTargetEnemy = self:GetParent().hEnemies[ RandomInt( 1, #self:GetParent().hEnemies ) ]

		-- Keep track of it, set the state to target_acquired
		if hTargetEnemy then
			self:GetParent().sState = "target_acquired"
			self:GetParent().hCurrentTarget = hTargetEnemy
			self:GetParent().vPoint = self:GetParent().hCurrentTarget:GetAbsOrigin()
			print( "Acquiring -> Enemy Target acquired: "..self:GetParent().hCurrentTarget:GetUnitName() )
		else 
			self:GetParent().sState = "target_acquired"
			self:GetParent().hCurrentTarget = nil
			self:GetParent().bIdling = true
			self:GetParent().vPoint = self.vSource + RandomVector( RandomInt( self.iRadius / 2, self.iRadius ) )
			self:GetParent().vPoint.z = GetGroundHeight( self:GetParent().vPoint, nil )
			
			--print("Acquiring -> Random Point Target acquired")
			if self.Debug then 
				DebugDrawCircle( self:GetParent().vPoint, self.vIdleColor, 100, 25, true, self.flDraw_duration ) 
			end
		end

	-- not enough time since the last attack, get a random point
	else
		self:GetParent().sState = "target_acquired"
		self:GetParent().hCurrentTarget = nil
		self:GetParent().bIdling = true
		self:GetParent().vPoint = self.vSource + RandomVector( RandomInt( self.iRadius / 2, self.iRadius ) )
		self:GetParent().vPoint.z = GetGroundHeight( self:GetParent().vPoint, nil )
		
		print("Waiting for attack time. Acquiring -> Random Point Target acquired")
		if self.Debug then 
			DebugDrawCircle( self:GetParent().vPoint, self.vIdleColor, 100, 25, true, self.flDraw_duration ) 
		end
	end
end

-- If the state was to follow a target enemy, it means the unit can perform an attack.
function modifier_boss_winter_wyvern_ice_spirits_spirit_lua:AcquiredState( self )
	-- Update the point of the target's current position
	if self:GetParent().hCurrentTarget then
		self:GetParent().vPoint = self:GetParent().hCurrentTarget:GetAbsOrigin()
		if self.Debug then 
			DebugDrawCircle( self:GetParent().vPoint, self.vTargetColor, 100, 25, true, self.flDraw_duration ) 
		end
	end

	-- Give up on the target if the distance goes over the give_up_distance
	if self:GetParent().flDistanceToCaster  > self.iGiveUpDistance then
		self:GetParent().sState = "acquiring"
		--print("Gave up on the target, acquiring a new target.")

	end

	-- Do physical damage here, and increase hit counter. 
	if self:GetParent().bCollision then

		-- If the target was an enemy and not a point, the unit collided with it
		if self:GetParent().hCurrentTarget ~= nil then
			
			-- Damage, units will still try to collide with attack immune targets but the damage wont be applied
			if not self:GetParent().hCurrentTarget:IsAttackImmune() then
				local iDamage =  damage = RandomInt( self.iMinDamage, self.iMaxDamage )
				local hDamageTable = 
				{
					victim = self:GetParent().hCurrentTarget,
					attacker = self:GetAbility():GetCaster()
					damage_type = DAMAGE_TYPE_PURE
					damage = iDamage
				}

				ApplyDamage( hDamageTable )

				-- Calculate how much physical damage was dealt
				--[[local targetArmor = self:GetParent().hCurrentTarget:GetPhysicalArmorValue()
				local damageReduction = ((0.06 * targetArmor) / (1 + 0.06 * targetArmor))
				local damagePostReduction = spirit_damage * (1 - damageReduction)]]

				self:GetParent().flDamageDone = self:GetParent().flDamageDone + iDamage

				-- Damage particle, different for buildings
				if self:GetParent().hCurrentTarget:IsBuilding() then
					local particle = ParticleManager:CreateParticle( self.pParticleDamageBuilding, PATTACH_ABSORIGIN, self:GetParent().hCurrentTarget )
					ParticleManager:SetParticleControl(particle, 0, self:GetParent().hCurrentTarget:GetAbsOrigin() )
					ParticleManager:SetParticleControlEnt(particle, 1, unit.current_target, PATTACH_POINT_FOLLOW, "attach_hitloc", unit.current_target:GetAbsOrigin(), true)
				elseif unit.damage_done > 0 then
					local particle = ParticleManager:CreateParticle( self.pParticleDamage, PATTACH_ABSORIGIN, self:GetParent().hCurrentTarget )
					ParticleManager:SetParticleControl(particle, 0, self:GetParent().hCurrentTarget:GetAbsOrigin())
					ParticleManager:SetParticleControlEnt(particle, 1, self:GetParent().hCurrentTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent().hCurrentTarget:GetAbsOrigin(), true)
				end

				-- Increase the numberOfHits for this unit
				self:GetParent().iNumberOfHits = self:GetParent().numberOfHits + 1 

				-- Fire Sound on the target unit
				self:GetParent().hCurrentTarget:EmitSound("Hero_DeathProphet.Exorcism.Damage")
				
				-- Set to return
				self:GetParent().sState = "returning"
				self:GetParent().vPoint = self.vSource
				--print("Returning to caster after dealing ",unit.damage_done)

				-- Update the attack time of the unit.
				self:GetParent().lastArrackTime = GameRules:GetGameTime()
				--unit.enemy_collision = true

			end

		-- In other case, its a point, reacquire target or return to the caster (50/50)
		else
			if RollPercentage(50) then
				self:GetParent().sState = "acquiring"
				--print("Attempting to acquire a new target")
			else
				self:GetParent().sState = "returning"
				self:GetParent().vPoint = self.vSource
				--print("Returning to caster after idling")
			end
		end
	end
end

function modifier_boss_winter_wyvern_ice_spirits_spirit_lua:ReturningState( self )
	-- Update the point to the caster's current position
	self:GetParent().vPoint = self.vSource
	if self.bDebug then 
		DebugDrawCircle( self:GetParent().vPoint, self.vReturnColor, 100, 25, true, self.flDrawDuration ) 
	end

	if self:GetParent().bCollision then 
		self:GetParent().sState = "acquiring"
	end	
end