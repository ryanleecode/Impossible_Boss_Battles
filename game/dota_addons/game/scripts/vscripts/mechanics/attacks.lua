if not Attacks then
    Attacks = class({})
end

-- Attack Ground for Artillery attacks, redirected from FilterProjectile
function AttackGroundPos(attacker, position)
    local iSpeed = attacker:GetProjectileSpeed()
    local projectile = ParticleManager:CreateParticle(GetRangedProjectileName(attacker), PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(projectile, 0, attacker:GetAttachmentOrigin(attacker:ScriptLookupAttachment("attach_attack1")))
    ParticleManager:SetParticleControl(projectile, 1, position)
    ParticleManager:SetParticleControl(projectile, 2, Vector(iSpeed, 0, 0))
    ParticleManager:SetParticleControl(projectile, 3, position)
    attacker:PerformAttack(attacker,false,false,false,false,false) --self-attack, used for putting the attack on cooldown, denied in damage filter

    local distanceToTarget = (attacker:GetAbsOrigin() - position):Length2D()
    local time = distanceToTarget/iSpeed
    Timers:CreateTimer(time, function()
        -- Destroy the projectile
        ParticleManager:DestroyParticle(projectile, false)

        -- Deal ground attack damage
       SplashAttackGround( attacker, position )

       --[[if attacker.OnAttackGround then
            attacker.OnAttackGround(position)
        end]]
    end)
end

-- Deals damage based on the attacker around a position, with full/medium/small factors based on distance from the impact
function SplashAttackGround(attacker, position)
    SplashAttackUnit(attacker, position)
    
    -- Hit ground particle. This could be each particle endcap instead
    local hit = ParticleManager:CreateParticle(GetArtilleryImpactProjectileName( attacker ), PATTACH_CUSTOMORIGIN, attacker)
    ParticleManager:SetParticleControl(hit, 0, position)

    -- Tree damage (NElves only deal ground damage with upgrade)    
    local damage_to_trees = 10
    local small_damage_radius = attacker:GetKeyValue("SplashSmallRadius") or 10
    local trees = GridNav:GetAllTreesAroundPoint(position, small_damage_radius, true)

    for _,tree in pairs(trees) do
        if tree:IsStanding() then
             tree:CutDown(attacker:GetPlayerOwnerID())

            -- Hit tree particle
            --[[local particleName = "particles/custom/tree_pine_01_destruction.vpcf"
            local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, attacker)
            ParticleManager:SetParticleControl(particle, 0, tree:GetAbsOrigin())]]
        end
    end
end

function SplashAttackUnit(attacker, position)
    local full_damage_radius = attacker:GetKeyValue("SplashFullRadius") or 0
    local medium_damage_radius = attacker:GetKeyValue("SplashMediumRadius") or 0
    local small_damage_radius = attacker:GetKeyValue("SplashSmallRadius") or 0

    local full_damage = attacker:GetAttackDamage()
    local medium_damage = full_damage * attacker:GetKeyValue("SplashMediumDamage") or 0
    local small_damage = full_damage * attacker:GetKeyValue("SplashSmallDamage") or 0
    medium_damage = medium_damage + small_damage -- Small damage gets added to the mid aoe

    local splash_targets = FindEnemiesInRadius(attacker, small_damage_radius, position)
    if true then
        DebugDrawCircle(position, Vector(255,0,0), 50, full_damage_radius, true, 3)
        DebugDrawCircle(position, Vector(255,0,0), 50, medium_damage_radius, true, 3)
        DebugDrawCircle(position, Vector(255,0,0), 50, small_damage_radius, true, 3)
    end

    -- Damage each unit only once    
    for _,unit in pairs(splash_targets) do
        if not unit:HasFlyMovementCapability() then
        	local hit = ParticleManager:CreateParticle(GetUnitImpactParticle( attacker ), PATTACH_CUSTOMORIGIN, attacker)
   			ParticleManager:SetParticleControl( hit, 0, attacker:GetAbsOrigin() )
   			local pos = position
   			pos.z = pos.z + 128
   			ParticleManager:SetParticleControl( hit, 3, pos )
            local distance_from_impact = (unit:GetAbsOrigin() - position):Length2D()
            if distance_from_impact <= full_damage_radius then
                ApplyDamage({ victim = unit, attacker = attacker, damage = full_damage, ability = nil, damage_type = DAMAGE_TYPE_PHYSICAL})
            elseif distance_from_impact <= medium_damage_radius then
                ApplyDamage({ victim = unit, attacker = attacker, damage = medium_damage, ability = nil, damage_type = DAMAGE_TYPE_PHYSICAL})
            else
                ApplyDamage({ victim = unit, attacker = attacker, damage = small_damage, ability = nil, damage_type = DAMAGE_TYPE_PHYSICAL})
            end
        end
    end
end
