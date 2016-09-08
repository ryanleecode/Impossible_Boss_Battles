function wyrm_blade(keys)
	local caster = keys.caster
	local ability = keys.ability
	local modifierWyrmBlade = "modifiers_wyrm_blade"
	local wyrmBladeStacks = caster:GetModifierStackCount(modifierWyrmBlade, ability) + keys.strengthBonus
	caster:SetModifierStackCount(modifierWyrmBlade, ability, wyrmBladeStacks)
end

function test(keys)
	local ability = keys.ability
	print(ability:GetPlaybackRateOverride())
	print(ability:GetName())
	ability:SetPlaybackRate(1) 
end
	