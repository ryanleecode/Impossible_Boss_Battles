function dragon_knight_mortal_strike(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target 								  
	local damageMultiplier = ability:GetLevelSpecialValueFor("damageMultiplier", ability:GetLevel() - 1 )
	local damageType = ability:GetAbilityDamageType()
	local missingHealth = caster:GetHealthDeficit() 
	local cooldown = ability:GetCooldown(ability:GetLevel() - 1)
	local modifier = keys.modifier

	local damageTable = {
		victim = target,
		attacker = caster,
		damage = damageMultiplier * missingHealth,
		damage_type = damageType,
	}
	if ability.off_cooldown == 1 then
		ApplyDamage(damageTable)
		ability:ApplyDataDrivenModifier(caster, target, modifier, {}) 
		Timers:CreateTimer({
			endTime = 0.1,
			callback = function()
				target:RemoveModifierByName(modifier)
			end
		})
		ability:StartCooldown(cooldown)
		ability.off_cooldown = 0
	end
end

function checkCooldown(keys)
	local caster = keys.caster
	local ability = keys.ability
	local mana = ability:GetLevelSpecialValueFor("AbilityManaCost", ability:GetLevel() - 1)
	
	-- If orb is off cooldown, applies the particles and sound, and removes the necessary mana
	if ability:IsCooldownReady() then
		ability.off_cooldown = 1
		caster:SetMana(caster:GetMana() - mana)
		--EmitSoundOn(keys.sound, caster)
		--local particle = ParticleManager:CreateParticle(keys.particle, PATTACH_ABSORIGIN_FOLLOW, caster) 
		--ParticleManager:SetParticleControlEnt(particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_origin", caster:GetAbsOrigin(), true)
	end
end