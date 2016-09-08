function dragon_knight_dragons_blood( keys )
	local caster = keys.caster
	local ability = keys.ability
	local baseHeal = ability:GetLevelSpecialValueFor("baseBonusHealthRegen", ability:GetLevel() - 1 )
	local missingHealthMutliplier = ability:GetLevelSpecialValueFor("missHealthMutliplier", ability:GetLevel() - 1 )
	local healthDeficit = caster:GetHealthDeficit()
	local healValue = baseHeal + missingHealthMutliplier * healthDeficit
	-- Heal Caster 
	caster:SetBaseHealthRegen(healValue)
end	