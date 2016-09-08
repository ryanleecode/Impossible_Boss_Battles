modifier_boss_winter_wyvern_ice_spirits_lua = class({}) 
LinkLuaModifier( "modifier_boss_winter_wyvern_ice_spirits_spirit_lua", "libraries/modifiers/winter_wyvern_boss/modifier_boss_winter_wyvern_ice_spirits_spirit_lua.lua", 
				LUA_MODIFIER_MOTION_NONE )


function modifier_boss_winter_wyvern_ice_spirits_lua:OnCreated( keys )
	if not IsServer() then return end
	EmitSoundOn( "Hero_DeathProphet.Exorcism.Cast", self:GetParent() )

	self.iNumberOfSpirits = self:GetAbility():GetLevelSpecialValueFor( "numberOfSpirits", self:GetAbility():GetLevel() - 1 )
	self.flDelayBetweenSpirits = self:GetAbility():GetLevelSpecialValueFor( "delayBetweenSpirits", self:GetAbility():GetLevel() - 1 )
	self.iDuration = self:GetAbility():GetLevelSpecialValueFor( "duration", self:GetAbility():GetLevel() - 1 )

	self.hSpirits = {}
	self.iCurrentNumberOfSpirits = 0 

	modifier_boss_winter_wyvern_ice_spirits_lua:InitializeSpirit( self )

	self:StartIntervalThink( self.flDelayBetweenSpirits )
end

function modifier_boss_winter_wyvern_ice_spirits_lua:OnIntervalThink()
	if not IsServer() then return end

	if self.iCurrentNumberOfSpirits >= self.iNumberOfSpirits then
		self:StartIntervalThink( -1 )
	else
		modifier_boss_winter_wyvern_ice_spirits_lua:InitializeSpirit( self )
	end
end

-- Initialize the table to keep track of all spirits
function modifier_boss_winter_wyvern_ice_spirits_lua:InitializeSpirit( self )
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