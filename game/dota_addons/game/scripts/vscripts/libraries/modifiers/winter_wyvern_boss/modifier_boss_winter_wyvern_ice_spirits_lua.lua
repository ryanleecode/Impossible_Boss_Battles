modifier_boss_winter_wyvern_ice_spirits_lua = class({}) 
LinkLuaModifier( "modifier_boss_winter_wyvern_ice_spirits_spirit_lua", "libraries/modifiers/winter_wyvern_boss/modifier_boss_winter_wyvern_ice_spirits_spirit_lua.lua", 
				LUA_MODIFIER_MOTION_NONE )

function modifier_boss_winter_wyvern_ice_spirits_lua:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_EVENT_ON_DEATH
  }
 
  return funcs
end

function modifier_boss_winter_wyvern_ice_spirits_lua:OnCreated( keys )
	if not IsServer() then return end
	self:GetParent():EmitSound( "Hero_DeathProphet.Exorcism")

	self.iNumberOfSpirits = self:GetAbility():GetLevelSpecialValueFor( "numberOfSpirits", self:GetAbility():GetLevel() - 1 )
	self.flDelayBetweenSpirits = self:GetAbility():GetLevelSpecialValueFor( "delayBetweenSpirits", self:GetAbility():GetLevel() - 1 )

	self.hSpirits = {}
	self.iCurrentNumberOfSpirits = 0 

	modifier_boss_winter_wyvern_ice_spirits_lua:InitializeSpirit( self )

	self:StartIntervalThink( self.flDelayBetweenSpirits )
end

function modifier_boss_winter_wyvern_ice_spirits_lua:OnIntervalThink()
	if not IsServer() then return end

	if self.iCurrentNumberOfSpirits < self.iNumberOfSpirits and self:GetAbility():GetCaster():GetCurrentActiveAbility() == self:GetAbility() then
		modifier_boss_winter_wyvern_ice_spirits_lua:InitializeSpirit( self )
	else
		self:StartIntervalThink( -1 )
	end
end

-- Initialize the table to keep track of all spirits
function modifier_boss_winter_wyvern_ice_spirits_lua:InitializeSpirit( self )

	self.iDuration = self:GetAbility():GetLevelSpecialValueFor( "duration", self:GetAbility():GetLevel() - 1 )

	local hSpirit = CreateUnitByName( "npc_dummy_unit", self:GetParent():GetAbsOrigin(), true, self:GetParent(), self:GetParent(), self:GetParent():GetTeamNumber() )

	-- The modifier takes care of the physics and logic
	hSpirit:AddNewModifier( self:GetAbility():GetCaster(), self:GetAbility(), "modifier_boss_winter_wyvern_ice_spirits_spirit_lua", {} )	

	-- Add the spawned unit to the table
	table.insert( self.hSpirits, hSpirit)

	-- Initialize the number of hits, to define the heal done after the ability ends
	hSpirit.numberOfHits = 0

	-- counter to stop the creation of spirits
	self.iCurrentNumberOfSpirits = self.iCurrentNumberOfSpirits + 1

	-- Double check to kill the units, remove this later
	Timers:CreateTimer( self.iDuration + 10, function() 
		if hSpirit and IsValidEntity( hSpirit ) then 
			hSpirit:RemoveSelf() 
		end
	end)
end

function modifier_boss_winter_wyvern_ice_spirits_lua:OnDestroy()
	if not IsServer() then return end
	self:GetAbility():GetCaster():StopSound("Hero_DeathProphet.Exorcism")

	for _,unit in pairs( self.hSpirits ) do		
	   	if unit and IsValidEntity( unit ) then
    	  	unit.state = "end"
    	end
	end

	-- Reset the last_targeted
	self:GetAbility().last_targeted = nil
end

function modifier_boss_winter_wyvern_ice_spirits_lua:OnAttack( keys )
	if not IsServer() then return end
	self:GetAbility().last_targeted = keys.target
	--print("LAST TARGET: "..target:GetUnitName())
end

function modifier_boss_winter_wyvern_ice_spirits_lua:OnDeath( keys )
	if not IsServer() then return end

	if keys.unit == self:GetAbility():GetCaster() then
		print("Exorcism Death")
		self:GetAbility():GetCaster():StopSound("Hero_DeathProphet.Exorcism")
		for _,unit in pairs( self.hSpirits ) do		
		   	if unit and IsValidEntity( unit ) then
	    	  	unit:SetPhysicsVelocity(Vector( 0, 0, 0 ))
		        unit:OnPhysicsFrame(nil)

				-- Kill
		        unit:ForceKill(false)
		        ParticleManager:DestroyParticle( unit.pSpiritGlow, false )
	        	ParticleManager:DestroyParticle( unit.pSpiritModel , false )

	    	end
		end
	end
end