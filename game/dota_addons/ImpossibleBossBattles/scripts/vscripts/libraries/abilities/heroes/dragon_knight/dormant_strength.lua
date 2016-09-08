function dormant_strength_init(keys)
	local ability = keys.ability
	local target = keys.target
	local ability_level = ability:GetLevel() - 1
	local modifier = keys.modifier
	local maxStack = ability:GetLevelSpecialValueFor("maxAttacks", ability_level)

	-- Set the number of attacks allowed
	target:SetModifierStackCount(modifier, target, maxStack)
end

function dormant_strength_stack(keys)
	local ability = keys.ability
	local attacker = keys.attacker
	local target = keys.target
	local modifier = keys.modifier
	local debuff = keys.debuff

	local ability_level = ability:GetLevel() - 1
	local health = attacker:GetHealth() 

	local baseSelfDamage = 0.013 * attacker:GetMaxHealth()
	local selfDamageMultiplier = ability:GetLevelSpecialValueFor("selfDamageMultiplier", ability_level)
	
	local currentStack = attacker:GetModifierStackCount(modifier, attacker)

	if currentStack <= 1 then
		attacker:RemoveModifierByNameAndCaster(modifier, attacker)
	else
		attacker:SetModifierStackCount(modifier, attacker, currentStack - 1)
	end

	local damageTable = {
		victim = attacker,
		attacker = attacker,
		damage = health * selfDamageMultiplier + baseSelfDamage,
		damage_type = DAMAGE_TYPE_PURE,
	}

	ApplyDamage(damageTable)
	local debuffStack = target:GetModifierStackCount(debuff, target)
	if debuffStack <= 0 then
		ability:ApplyDataDrivenModifier(target, target, debuff, {}) 
		target:SetModifierStackCount(debuff, target, debuffStack + 1)
	else
		target:SetModifierStackCount(debuff, target, debuffStack + 1)
	end
end

function debuffDestroyed(keys)
    local caster = keys.caster
    local target = keys.target
    local debuff = keys.debuff
    local stacks = target:GetModifierStackCount(debuff, target)
    print(target:GetName() )
	local debuffStack = target:GetModifierStackCount(debuff, target)
	if debuffStack > 1 then
		target:SetModifierStackCount(debuff, target, debuffStack - 1)
	else
        target:RemoveModifierByName(debuff)
	end
    
end