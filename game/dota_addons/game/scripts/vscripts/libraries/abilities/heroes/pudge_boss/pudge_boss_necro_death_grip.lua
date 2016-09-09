function pudge_boss_necro_death_grip_init( keys )
	local ability = keys.ability
	local caster = keys.caster
	ability.target = keys.target
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_death_grip_caster_datadriven", {duration = 5.0 + 0.0666666}) 
	ability.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_lion/lion_spell_mana_drain.vpcf", PATTACH_POINT, caster) 
	ParticleManager:SetParticleControl(ability.particle, 0, ability.target:GetAbsOrigin())
	ParticleManager:SetParticleControl(ability.particle, 1, caster:GetAbsOrigin()) 
end

function pudge_boss_necro_death_grip( keys )
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	if caster:IsChanneling() then
		ability:ApplyDataDrivenModifier(caster, ability.target, "modifier_death_grip_datadriven", {duration = 0.5}) 
		drainMana( keys )
	else
		killCaster(keys)
	end
end

function killCaster (keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = ability.target
	local manaToHealth = caster:GetMana()
	caster:ForceKill(false)
	ParticleManager:DestroyParticle(ability.particle, true)
	-- Create the projectile
	local pudgeBoss = {}
	for k, v in pairs (Entities:FindAllByName("npc_dota_creature")) do
		if v:GetUnitName() == "pudge_boss" or v:GetName() == "pudge_boss" then
			pudgeBoss = v
		end
	end
	if pudgeBoss:IsAlive() then
	    local info = {
	        Target = caster,
	        Source = pudgeBoss,
	        Ability = ability,
	        EffectName = "particles/units/heroes/hero_undying/undying_soul_rip_heal.vpcf",
	        bDodgeable = false,
	        bProvidesVision = true,
	        iMoveSpeed = 50,
	        iVisionRadius = 0,
	        iVisionTeamNumber = caster:GetTeamNumber(),
	        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
	    }
	    ProjectileManager:CreateTrackingProjectile( info )
	    pudgeBoss:SetHealth(pudgeBoss:GetHealth()+manaToHealth)
	end	
end

function drainMana (keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = ability.target 
	local targetMana = target:GetMana()
	local manaDrain = ability:GetLevelSpecialValueFor("manaDrain", ability:GetLevel() - 1) * target:GetMaxMana()
	if targetMana >= manaDrain then
		target:ReduceMana(manaDrain)
		caster:GiveMana(manaDrain)
	else
		target:ReduceMana(targetMana)
		caster:GiveMana(targetMana)
	end
end
