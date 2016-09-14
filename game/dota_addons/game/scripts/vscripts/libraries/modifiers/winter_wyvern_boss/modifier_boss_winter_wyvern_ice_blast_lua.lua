modifier_boss_winter_wyvern_ice_blast_lua = class({}) 
LinkLuaModifier( "modifier_boss_winter_wyvern_ice_blast_enemy_lua", "libraries/modifiers/winter_wyvern_boss/modifier_boss_winter_wyvern_ice_blast_enemy_lua", 
				LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_lua:OnCreated( keys )
	if not IsServer() then return end

	self.iVortexRadius = self:GetAbility():GetLevelSpecialValueFor( "vortexRadius", self:GetAbility():GetLevel() - 1 )
	self.iAuraRadius = self:GetAbility():GetLevelSpecialValueFor( "auraRadius", self:GetAbility():GetLevel() - 1 )
	self.flDamage = self:GetAbility():GetLevelSpecialValueFor( "damage", self:GetAbility():GetLevel() - 1 )
	self.flPlaybackRate = self:GetAbility():GetLevelSpecialValueFor( "playbackRate", self:GetAbility():GetLevel() - 1 )
	self.flThinkInterval = self:GetAbility():GetLevelSpecialValueFor( "playbackRate", self:GetAbility():GetLevel() - 1 )
	self.flDebuffDuration = self:GetAbility():GetLevelSpecialValueFor( "debuffDuration", self:GetAbility():GetLevel() - 1 )

	self.pVortexL = ParticleManager:CreateParticle( "particles/units/heroes/hero_ancient_apparition/ancient_ice_vortex.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControl( self.pVortexL, 0, self:GetParent():GetAttachmentOrigin( self:GetParent():ScriptLookupAttachment( "attach_wing_l" ) ) )
	ParticleManager:SetParticleControl( self.pVortexL, 5, Vector( keys.iVortexRadius, keys.iVortexRadius, keys.iVortexRadius) )

	self.pVortexR = ParticleManager:CreateParticle( "particles/units/heroes/hero_ancient_apparition/ancient_ice_vortex.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControl( self.pVortexR, 0, self:GetParent():GetAttachmentOrigin( self:GetParent():ScriptLookupAttachment( "attach_wing_r" ) ) )
	ParticleManager:SetParticleControl( self.pVortexR, 5, Vector( keys.iVortexRadius, keys.iVortexRadius, keys.iVortexRadius) )

	self.pWaves = ParticleManager:CreateParticle( "particles/econ/items/ancient_apparition/aa_blast_ti_5/ancient_apparition_ice_blast_sphere_ti5.vpcf", 
												PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControl( self.pWaves, 3, self:GetParent():GetAttachmentOrigin( self:GetParent():ScriptLookupAttachment( "attach_spine_1" ) ) )

	self.pMarker = ParticleManager:CreateParticle( "particles/custom/oscillating_rings.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )

	local tEnemies = FindEnemiesInRadius( self:GetParent(), self.iAuraRadius, nil )
	for _,hEnemy in pairs( tEnemies ) do
		hEnemy:AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_boss_winter_wyvern_ice_blast_enemy_lua", { duration = self.flDebuffDuration } )
	end

	EmitSoundOnLocationWithCaster( self:GetParent():GetAbsOrigin(), "Hero_Winter_Wyvern.WintersCurse.Cast", self:GetParent() )

	self:StartIntervalThink( self.flThinkInterval )
end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_lua:OnIntervalThink()
	if not IsServer() then return end

	self:GetParent():RemoveGesture( ACT_DOTA_CAST_ABILITY_3 )
	self:GetParent():StartGestureWithPlaybackRate( ACT_DOTA_CAST_ABILITY_3, self.flPlaybackRate )

	self.pMarker = ParticleManager:CreateParticle( "particles/custom/oscillating_rings.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )

	local tEnemies = FindEnemiesInRadius( self:GetParent(), self.iAuraRadius, nil )
	for _,hEnemy in pairs( tEnemies ) do
		hEnemy:AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_boss_winter_wyvern_ice_blast_enemy_lua", { duration = self.flDebuffDuration } )
	end

	EmitSoundOnLocationWithCaster( self:GetParent():GetAbsOrigin(), "Hero_Antimage.ManaVoid", self:GetParent() )
end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_lua:OnDestroy()
	if not IsServer() then return end

	ParticleManager:DestroyParticle( self.pVortexL, false )
	ParticleManager:DestroyParticle( self.pVortexR, false )
	ParticleManager:DestroyParticle( self.pWaves, false )
	ParticleManager:DestroyParticle( self.pMarker, false )

end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_lua:IsDebuff()
	return false
end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_lua:IsHidden()
	return false
end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_lua:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_lua:IsPurgeException()
	return false
end

--------------------------------------------------------------------------------
