boss_winter_wyvern_ice_spirits_lua = class({})	
LinkLuaModifier( "modifier_boss_winter_wyvern_ice_spirits_lua", "libraries/modifiers/winter_wyvern_boss/modifier_boss_winter_wyvern_ice_spirits_lua.lua", 
				LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function boss_winter_wyvern_ice_spirits_lua:OnAbilityPhaseStart()
	if not IsServer() then return false end
	self.flPlaybackRate = self:GetLevelSpecialValueFor( "playbackRate", self:GetLevel() - 1 )

	self:GetCaster():RemoveGesture( ACT_DOTA_CAST_ABILITY_3 )
	self:GetCaster():StartGestureWithPlaybackRate( ACT_DOTA_CAST_ABILITY_3, self.flPlaybackRate )

	return true
end

--------------------------------------------------------------------------------

function boss_winter_wyvern_ice_spirits_lua:OnAbilityPhaseInterrupted()
	if not IsServer() then return end
	self:GetCaster():RemoveGesture( ACT_DOTA_CAST_ABILITY_3 )
end

--------------------------------------------------------------------------------

function boss_winter_wyvern_ice_spirits_lua:OnSpellStart()
	if not IsServer() then return end

	self.iDuration = self:GetLevelSpecialValueFor( "duration", self:GetLevel() - 1 )
	
	EmitSoundOn( "Hero_DeathProphet.Exorcism.Cast", self:GetCaster() )

	if not self:GetCaster():HasModifier( "modifier_boss_winter_wyvern_ice_spirits_lua" ) then
		self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_boss_winter_wyvern_ice_spirits_lua", {duration = self.iDuration } )
	else
		self:GetCaster():RemoveModifierByName( "modifier_boss_winter_wyvern_ice_spirits_lua" )
		self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_boss_winter_wyvern_ice_spirits_lua", {duration = self.iDuration } )
	end
end

--------------------------------------------------------------------------------

function boss_winter_wyvern_ice_spirits_lua:OnChannelFinish( bInterrupted )
	--self:GetCaster():RemoveModifierByName( "modifier_boss_winter_wyvern_ice_spirits_lua" )
	if not IsServer() or bInterrupted then
		return 
	end
end

--------------------------------------------------------------------------------