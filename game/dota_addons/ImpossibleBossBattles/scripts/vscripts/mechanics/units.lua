if not Units then
    Units = class({})
end

-- Returns all visible enemies in radius of the unit/point
function FindVisibleEnemiesInRadius( unit, radius, point )
    local team = unit:GetTeamNumber()
    local position = point or unit:GetAbsOrigin()
    local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
    local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS
    return FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_CLOSEST, false)
end

-- Returns all enemies in radius of the unit/point
function FindEnemiesInRadius( unit, radius, point )
    local team = unit:GetTeamNumber()
    local position = point or unit:GetAbsOrigin()
    local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
    local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
    return FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_CLOSEST, false)
end

function GetRangedProjectileName( unit )
    return unit.projectileName or unit:GetKeyValue("ProjectileModel") or ""
end

function GetArtilleryImpactProjectileName( unit )
    return unit.artilleryImpactName or unit:GetKeyValue("ArtilleryImpactProjectile") or ""
end

function GetUnitImpactParticle( unit )
    return unit.UnitImpactParticle or unit:GetKeyValue("UnitImpactParticle") or ""
end

-- Does the unit have a linear projectile auto attack?
function CDOTA_BaseNPC:HasArtilleryAttack()
    return self:GetKeyValue("ArtilleryAttack")
end