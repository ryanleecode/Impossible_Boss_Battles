function dragon_call(keys)
	local ability = keys.ability
	ability.stop = 1
	local caster = keys.caster

	local teamNumber = caster:GetTeamNumber()
	local target = caster:GetAbsOrigin() 
	local targetTeams = ability:GetAbilityTargetTeam()
	local targetTypes = ability:GetAbilityTargetType()
	local targetFlags = ability:GetAbilityTargetFlags()

	local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1 )



	-- Look for units to taunt
	local units = FindUnitsInRadius(teamNumber, target, nil, radius, targetTeams, targetTypes, targetFlags, FIND_CLOSEST, false) 
	for k, v in pairs(units) do
		v:SetForceAttackTarget(nil)
		if caster:IsAlive() then
			local order = 
			{
				UnitIndex = v:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
				TargetIndex = caster:entindex()
			}

			ExecuteOrderFromTable(order)
		else
			target:Stop()
		end
	end
end

function resetParticle(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	local attackTarget = target:GetAttackTarget()
	local modifier = keys.modifier
	if attackTarget == caster then
		ability:ApplyDataDrivenModifier(caster, target, modifier, {}) 
	end
end

