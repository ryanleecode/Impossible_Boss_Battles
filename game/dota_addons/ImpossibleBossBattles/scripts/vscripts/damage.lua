function GameMode:FilterDamage( filterTable )
	local victim_index = filterTable["entindex_victim_const"]
    local attacker_index = filterTable["entindex_attacker_const"]
    if not victim_index or not attacker_index then
        return true
    end

    local victim = EntIndexToHScript( victim_index )
    local attacker = EntIndexToHScript( attacker_index )
    local damagetype = filterTable["damagetype_const"]

    -- Physical attack damage filtering
    if damagetype == DAMAGE_TYPE_PHYSICAL then
        if victim == attacker then
        	return false 
        end -- Self attack, for fake attack ground
    end

	return true
end