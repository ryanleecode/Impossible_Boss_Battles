boss_winter_wyvern_splinter_blast_lua = class({})	

function boss_winter_wyvern_splinter_blast_lua:OnAbilityPhaseStart()
	if not IsServer() then return false end
	self:GetCaster():StartGestureWithPlaybackRate( ACT_DOTA_CAST_ABILITY_2, 0.8 )
	return true
end

function boss_winter_wyvern_splinter_blast_lua:OnAbilityPhaseInterrupted()
	if not IsServer() then return end
	self:GetCaster():RemoveGesture( ACT_DOTA_CAST_ABILITY_2 )
end

function boss_winter_wyvern_splinter_blast_lua:OnChannelFinish( bInterrupted )
	if not IsServer() or bInterrupted then return end
	--[[ Locations for the splinter blast will be incremental. E.x. Radius of 1200, 12 blasts. Blast will be 100, 200, 300 ... distance from caster
	]]
	self.iRadius = self:GetLevelSpecialValueFor( "radius", self:GetLevel() - 1 )
	self.iQuantity = self:GetLevelSpecialValueFor( "quantity", self:GetLevel() - 1 )
	self.flBlastSpeed = self:GetLevelSpecialValueFor( "blastSpeed", self:GetLevel() - 1 )
	self.flSplinterSpeed = self:GetLevelSpecialValueFor( "splinterSpeed", self:GetLevel() - 1 )
	self.iImpactRadius = self:GetLevelSpecialValueFor( "impactRadius", self:GetLevel() - 1 )
	self.iSplinterImpactRadius = self:GetLevelSpecialValueFor( "splinterImpactRadius", self:GetLevel() - 1 )
	self.iSplinterRadius = self:GetLevelSpecialValueFor( "splinterRadius", self:GetLevel() - 1 )
	self.iSplinterQuantity = self:GetLevelSpecialValueFor( "splinterQuantity", self:GetLevel() - 1 )
	self.iBlastDamage = self:GetLevelSpecialValueFor( "blastDamage", self:GetLevel() - 1 )
	self.iSplinterDamage = self:GetLevelSpecialValueFor( "splinterDamage", self:GetLevel() - 1 )
	self.iSecondSplinterDamage = self:GetLevelSpecialValueFor( "secondSplinterDamage", self:GetLevel() - 1 )
	
	-- Distance between each blast
	local flBlastDistance = self.iRadius / self.iQuantity
	TimeToRandomSeed()

	EmitSoundOnLocationWithCaster( self:GetCaster():GetAbsOrigin(), "Hero_Winter_Wyvern.SplinterBlast.Cast" , self:GetCaster() )
	Timers:CreateTimer( function()
		EmitSoundOnLocationWithCaster( self:GetCaster():GetAbsOrigin(), "Hero_Winter_Wyvern.SplinterBlast.Projectile" , self:GetCaster() )
	end)

	for i = 1, self.iQuantity, 1 do
		-- First blast
		local blast = boss_winter_wyvern_splinter_blast_lua:LaunchProjectile( 
			"particles/units/heroes/hero_winter_wyvern/wyvern_splinter.vpcf",  
			self:GetCaster():GetAttachmentOrigin( self:GetCaster():ScriptLookupAttachment( "attach_attack1" ) ),
			self.iBlastSpeed,
			flBlastDistance,
			self.iImpactRadius,
			i,
			self,
			Vector(255,0,0),
			self.iBlastDamage,
			self.flBlastSpeed
		)
		-- Splinter blasts
		Timers:CreateTimer( blast["expire"], function()
			-- Distance between each splinter
			local flSplinterDistance = self.iSplinterRadius / self.iSplinterQuantity
			for i2 =  1, self.iSplinterQuantity, 1 do 
				local splinter = boss_winter_wyvern_splinter_blast_lua:LaunchProjectile( 
					"particles/units/heroes/hero_winter_wyvern/wyvern_splinter_blast.vpcf",  
					blast["endPosition"],
					self.iBlastSpeed,
					flSplinterDistance,
					self.iSplinterImpactRadius,
					i2,
					self,
					Vector(0,0,255),
					self.iSplinterDamage,
					self.flSplinterSpeed
				)
				-- Second Splinter 
				Timers:CreateTimer( splinter["expire"], function()
					for i3 =  1, self.iSplinterQuantity, 1 do 
						local SecondSplinter = boss_winter_wyvern_splinter_blast_lua:LaunchProjectile( 
							"particles/units/heroes/hero_winter_wyvern/wyvern_splinter_blast.vpcf",  
							splinter["endPosition"],
							self.iBlastSpeed,
							flSplinterDistance,
							self.iSplinterImpactRadius,
							i3,
							self,
							Vector(0,0,255),
							self.iSecondSplinterDamage,
							self.flSplinterSpeed
						)	
					end
				end ) 
			end
		end ) 
	end
end	

-- Creates the particle projectile and damages units in the target area
function boss_winter_wyvern_splinter_blast_lua:LaunchProjectile( sParticle, vOrigin, iSpeed, flDistance, iRadius, iLoopNumber, self, vColor, iDamage, flExpire )
	-- Pythagoras   
    local iX = math.random( 0, math.floor( iLoopNumber * flDistance ) ) * math.floor( math.pow( -1, math.random( 0, 1) ) )
    local iY = math.floor( math.sqrt( math.pow( math.floor( iLoopNumber * flDistance ), 2) - math.pow( iX, 2) ) ) * math.floor( math.pow( -1, math.random( 0, 1) ) )  
	local vEndPosition = vOrigin + Vector( iX, iY, 0)
	vEndPosition.z = GetGroundHeight( vEndPosition, self:GetCaster() ) 
	local flDistanceToTarget = (  vEndPosition - vOrigin ):Length2D()
	local flSpeed = flDistanceToTarget / flExpire
	local blast = ParticleManager:CreateParticle( sParticle, PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleControl( blast, 0, vOrigin )
	ParticleManager:SetParticleControl( blast, 1, vEndPosition )
	ParticleManager:SetParticleControl( blast, 2, Vector( flSpeed, 0, 0 ) )	
	Timers:CreateTimer( flExpire, function()  
		EmitSoundOnLocationWithCaster( vEndPosition, "Hero_Winter_Wyvern.SplinterBlast.Splinter" , self:GetCaster() )
		if self:GetCaster().debug then 	
			print( vOrigin )
			print( vEndPosition )
			print( Vector( iSpeed, 0, 0 ) )
			print ( "------------------------------------" )
			--DebugDrawCircle(vEndPosition, vColor, 25, iRadius, true, 6)
		end
        ParticleManager:DestroyParticle(blast, false)
        local tTargets = FindEnemiesInRadius( self:GetCaster(), iRadius, vEndPosition )
        local ground = ParticleManager:CreateParticle( "particles/custom/boss_winter_wyvern_ice_wall_snow_ground.vpcf", PATTACH_CUSTOMORIGIN, nil )
        local particleDivision = 2
        ParticleManager:SetParticleControl( ground, 0, vEndPosition + Vector( -iRadius/particleDivision, -iRadius/particleDivision, 0 ) )
        ParticleManager:SetParticleControl( ground, 1, vEndPosition + Vector( iRadius/particleDivision, iRadius/particleDivision, 0 ) )
        Timers:CreateTimer( 1.25, function()   	
        	ParticleManager:DestroyParticle(ground, false)
        end)
        for _,unit in pairs(tTargets) do
        	EmitSoundOnLocationWithCaster( unit:GetAbsOrigin(), "Hero_Winter_Wyvern.SplinterBlast.Target" , self:GetCaster() ) 
        	ApplyDamage( { victim = unit, attacker = self:GetCaster(), damage = iDamage, ability = self, damage_type = DAMAGE_TYPE_MAGICAL} )
        end
    end )    

	local tInfo = {
		["expire"] = flExpire,	
		["endPosition"] = vEndPosition
	}
	return tInfo
end