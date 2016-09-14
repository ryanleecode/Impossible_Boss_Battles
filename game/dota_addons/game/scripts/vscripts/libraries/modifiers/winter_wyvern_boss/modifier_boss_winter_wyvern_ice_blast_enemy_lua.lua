modifier_boss_winter_wyvern_ice_blast_enemy_lua = class({})

function modifier_boss_winter_wyvern_ice_blast_enemy_lua:OnCreated( keys )
	if not IsServer() then return end

	self.flDamage = self:GetAbility():GetLevelSpecialValueFor( "damage", self:GetAbility():GetLevel() - 1 )
	self.flThinkInterval = self:GetAbility():GetLevelSpecialValueFor( "playbackRate", self:GetAbility():GetLevel() - 1 )
	self.flBaseKillThreshold = self:GetAbility():GetLevelSpecialValueFor( "baseKillThreshold", self:GetAbility():GetLevel() - 1 )
	self.flThresholdIncrement = self:GetAbility():GetLevelSpecialValueFor( "ThresholdIncrement", self:GetAbility():GetLevel() - 1 )

	if self:GetStackCount() <= self.flBaseKillThreshold then 
		self.KillThreshold = self.flBaseKillThreshold
	else
		self.KillThreshold = self:GetStackCount()
	end

	self:SetStackCount( self.KillThreshold )

	local tDamageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = self.flDamage,
		damage_type = DAMAGE_TYPE_MAGICAL,
	}

	ApplyDamage( tDamageTable )

	self:StartIntervalThink( self.flThinkInterval )

end
--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_enemy_lua:GetStatusEffectName()
	return "particles/status_fx/status_effect_iceblast.vpcf"		
end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_enemy_lua:StatusEffectPriority()
    return 10
end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_enemy_lua:OnRefresh( keys )
	if not IsServer() then return end

	local tDamageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = self.flDamage,
		damage_type = DAMAGE_TYPE_MAGICAL,
	}

	ApplyDamage( tDamageTable )
		
end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_enemy_lua:OnIntervalThink()
	if not IsServer() then return end

	self.KillThreshold = self.KillThreshold + self.flThresholdIncrement
	self:SetStackCount( self.KillThreshold )

	self.flDamagePerTick = self:GetAbility():GetLevelSpecialValueFor( "damagePerTick", self:GetAbility():GetLevel() - 1 )

	local tDamageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = self.flDamagePerTick,
		damage_type = DAMAGE_TYPE_MAGICAL,
	}

	ApplyDamage( tDamageTable )

	EmitSoundOnLocationWithCaster( self:GetParent():GetAbsOrigin(), "Hero_Ancient_Apparition.IceBlastRelease.Tick", self:GetCaster() )
end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_enemy_lua:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DISABLE_HEALING,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_enemy_lua:OnTakeDamage( keys )
	if not ( IsServer() or keys.unit == self:GetParent() ) then return end

	print( "Attacker: "..keys.attacker:GetName() or keys.attacker:GetUnitName().." "..keys.attacker:GetEntityIndex() )
	print( "Victim: "..keys.unit:GetName() or keys.unit:GetUnitName().." "..keys.unit:GetEntityIndex() )

	local flCurrentPercentageHealth = self:GetParent():GetHealth() / self:GetParent():GetMaxHealth() * 100.0

	if flCurrentPercentageHealth <= self.KillThreshold then
		local tDamageTable = {
			victim = self:GetParent(),
			attacker = keys.attacker,
			damage_type = DAMAGE_TYPE_PURE,
			ability = self:GetAbility(),
			damage = self:GetParent():GetHealth() + 1

		}

		if keys.attacker == self:GetParent() then
			tDamageTable.attacker = self:GetAbility():GetCaster()
		end

		ApplyDamage( tDamageTable )		 
	end

end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_enemy_lua:OnDeath()
    ParticleManager:CreateParticle( "particles/units/heroes/hero_ancient_apparition/ancient_apparition_ice_blast_death.vpcf", PATTACH_ABSORIGIN_FOLLOW,
    								self:GetParent() ) 
end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_enemy_lua:GetDisableHealing()
    return 1
end

 --------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_enemy_lua:IsDebuff()
	return true
end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_enemy_lua:IsHidden()
	return false
end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_enemy_lua:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_enemy_lua:IsPurgeException()
	return false
end

--------------------------------------------------------------------------------

function modifier_boss_winter_wyvern_ice_blast_enemy_lua:RemoveOnDeath()
	return true
end

--------------------------------------------------------------------------------
