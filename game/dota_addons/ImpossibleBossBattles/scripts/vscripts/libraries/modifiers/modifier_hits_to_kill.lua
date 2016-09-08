modifier_hits_to_kill = class({})

HERO_HIT_DAMAGE = {
	["boss_winter_wyvern_frozen_sigil"] = 4	
}

HITS_TO_KILL = {
	["boss_winter_wyvern_frozen_sigil"] = 16
}

function modifier_hits_to_kill:OnCreated()
	self.hitsToKill = HITS_TO_KILL[self:GetParent():GetUnitName()] or 16
	self.heroHit = HERO_HIT_DAMAGE[self:GetParent():GetUnitName()] or 4
end

function modifier_hits_to_kill:DeclareFunctions()
	if IsServer() then
		local funcs = {
			MODIFIER_EVENT_ON_ATTACKED,
			MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
			MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
			MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE, 
		}

		return funcs
	end
end

function modifier_hits_to_kill:OnAttacked( event )
	if event.target == self:GetParent() then 
		if event.attacker:IsRealHero() then
			self.hitsToKill = self.hitsToKill - self.heroHit
		else
			self.hitsToKill = self.hitsToKill - 1
		end
	end

	if self.hitsToKill > 0 then
		self:GetParent():SetHealth( self.hitsToKill ) 
	else
		self:GetParent():Kill( nil, event.attacker )
	end
end

function modifier_hits_to_kill:CheckState()
	if IsServer() then 
		local state = {
			[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		}

		return state
	end
end

function modifier_hits_to_kill:IsPurgable()
	return false
end
function modifier_hits_to_kill:IsHidden()
	return true
end

function modifier_hits_to_kill:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_hits_to_kill:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_hits_to_kill:GetAbsoluteNoDamagePure()
	return 1
end