boss_winter_wyvern_frozen_sigil_lua = class({})					 
LinkLuaModifier( "modifier_flying_control", "libraries/modifiers/modifier_flying_control.lua", LUA_MODIFIER_MOTION_NONE )

--[[Author: drdgvhbh
	Last Updated: August 16, 2016]]

DEBUG = true -- Debug Flag to print messages to Console

function boss_winter_wyvern_frozen_sigil_lua:OnAbilityPhaseStart()
	if IsServer() then
		self:GetCaster():StartGestureWithPlaybackRate( ACT_DOTA_CAST_ABILITY_2, 0.9 )
		return true
	end

	return false
end

function boss_winter_wyvern_frozen_sigil_lua:OnAbilityPhaseInterrupted()
	if IsServer() then
		self:GetCaster():RemoveGesture( ACT_DOTA_CAST_ABILITY_2 )
	end
end

function boss_winter_wyvern_frozen_sigil_lua:OnChannelFinish( bInterrupted )
	if IsServer() then
		self:GetCaster():RemoveGesture( ACT_DOTA_CAST_ABILITY_2 )
	else
		debugPrint( "boss_winter_wyvern_frozen_sigil_lua is not on server.dll" )
		return
	end

	if not bInterrupted then
		-- sigil will be created at a location near the caster
		self.vSpawnLocation = self:GetCaster():GetAbsOrigin() + RandomVector( self:GetLevelSpecialValueFor( "iDistance", self:GetLevel() - 1 ) )

		-- create the sigil
		self.hSigil = CreateUnitByName( "summon_frozen_sigil", self.vSpawnLocation, true, nil, nil, self:GetCaster():GetTeamNumber() )

		-- make it fly
		self.hSigil:AddNewModifier( self:GetCaster(), self, "modifier_flying_control", nil )

		-- make it controllable by me
		self.hSigil:SetControllableByPlayer(0, true)

	end
end

