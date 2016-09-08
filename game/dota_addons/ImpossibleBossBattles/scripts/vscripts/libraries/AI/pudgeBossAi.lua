--[[
	Author: drdgvhbh
	Last Updated: July 26 2016
	Description: AI Script for 'Pudge the Butcher' (Boss)
]]--

DEBUG = false -- Debug Flag to print messages to Console

--==========================--
--[[AI Parameter Constants]]--
--==========================--
INNER_SEARCH_RANGE = 680 -- The search range to attack units
AI_THINK_INTERVAL = 0.125 -- How often the AI thinks
AI_BASE_TIME_SINCE_LAST_CAST = 2.0 -- The minimum amount of time required to cast another spell after a previous spell was cast
-- Thinker States
AI_STATE_NEUTRAL_STATE = 1 
AI_STATE_PROVOKED_STATE = 2
AI_STATE_ENRAGED_STATE = 3
AI_STATE_INFINITY_STATE = 4
AI_STATE_CASTING_STATE = 5
-- Mana Regeneration States
MANA_STATE =  {
	[AI_STATE_NEUTRAL_STATE] 	= 12.5 	* AI_THINK_INTERVAL,
	[AI_STATE_PROVOKED_STATE] 	= 25.0 	* AI_THINK_INTERVAL,
	[AI_STATE_ENRAGED_STATE] 	= 37.5 	* AI_THINK_INTERVAL,
	[AI_STATE_INFINITY_STATE] 	= 0.0	* AI_THINK_INTERVAL,
	[AI_STATE_CASTING_STATE] 	= 0.0	* AI_THINK_INTERVAL
}
-- Abilities as Numbered Keys
KEY_FART_JUMP = 1
KEY_DEATH_GRIP = 2
KEY_MEAT_HOOK = 3
-- Table of Pudge's ability names assigned to numbered keys
ABILITY_TABLE = {
	[KEY_FART_JUMP] = "pudge_boss_fart_jump_datadriven",
	[KEY_DEATH_GRIP] = "pudge_boss_death_grip_datadriven",
	[KEY_MEAT_HOOK] = "pudge_boss_meat_hook_lua"
}
-- Table of the Base chance for each spell to be cast
BASE_CAST_TABLE = {
	[KEY_FART_JUMP] = 0.0,
	[KEY_DEATH_GRIP] = 0.7,
	[KEY_MEAT_HOOK] = 0.3
}

-- Table for the decay time for ability to return to their base cast percentage
DECAY_CONSTANT = (math.log(0.001)/math.log(10))/(math.log(math.exp(1.0))/math.log(10)) * -1.0
DECAY_TIME  = { -- Measured in Seconds
	[KEY_FART_JUMP] = 2.0/DECAY_CONSTANT, 
	[KEY_DEATH_GRIP] = 15.0/DECAY_CONSTANT,
	[KEY_MEAT_HOOK] = 10.0/DECAY_CONSTANT
}
-- Growth Constant for changing ability cast percentages
GROWTH_CONSTANT = DECAY_CONSTANT * 3.0

-- Ability State Constants
ABILITY_STATE_DECAYING = 0
ABILITY_STATE_GROWING = 1

--===================--
--[[Class Functions]]--
--===================--
-- Create the Pudge Boss AI Class
pudgeBossAi = {}
pudgeBossAi.__index = pudgeBossAi

function Spawn(entityKeyValues) -- Function run when the entity spawns into the game
	local unit = thisEntity
	pudgeBossAi:CreateInstance(unit)
	debugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex(), DEBUG)
end

function pudgeBossAi:CreateInstance( unit )
	-- Creates an instance of the class
	local ai = {}
	setmetatable( ai, pudgeBossAi)
	-- Set variables for the instance
	ai.unit = unit -- The instance itself
	ai.state = AI_STATE_NEUTRAL_STATE -- Starting state for the instance thinker
	ai.previousState = AI_STATE_NEUTRAL_STATE -- The previous state for the instance thinker, starts as the same as the current state
	ai.timeSinceLastCast = 0 -- The amount of time in seconds since the last ability was cast
	ai.currentInterval = 0 --[[ Starting from 1.0 seconds after a boss spell has been cast, this variable measures the amount of times in AI_THINK_INTERVAL * 2 intervals a
							 	boss spell has not been cast ]]--
	ai.abilityPointsPool = 0 -- Used to redistribute percentages
	-- Values which pertain to the boss' current thinking state
	ai.stateThinks = {
		[AI_STATE_NEUTRAL_STATE] = 'NeutralState',
		[AI_STATE_CASTING_STATE] = 'CastingState'
	}
	-- Values which pertain to the percentage chance for an ability to be cast
	ai.castTable = {
		[KEY_FART_JUMP] = BASE_CAST_TABLE[KEY_FART_JUMP],
		[KEY_DEATH_GRIP] = BASE_CAST_TABLE[KEY_DEATH_GRIP],
		[KEY_MEAT_HOOK] = BASE_CAST_TABLE[KEY_MEAT_HOOK]
	}
	-- State of the ability. Decaying or Growing in percentage?
	ai.abilityState = {
		[KEY_FART_JUMP] = ABILITY_STATE_DECAYING,
		[KEY_DEATH_GRIP] = ABILITY_STATE_DECAYING,
		[KEY_MEAT_HOOK] = ABILITY_STATE_DECAYING
	}
	-- Starts the thinker for the instance
	Timers:CreateTimer ( ai.GlobalThink, ai )
	debugPrint(thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex().." has sucessfully begun thinking!", DEBUG)

	-- Return constructed instance
	return ai	
end

--======================--
--[[Instance Functions]]--
--======================--

function pudgeBossAi:GlobalThink() -- The thinker for the instance
	if not self.unit:IsAlive() then -- End the thinker if the unit has died
		return nil
	end
	self.unit:GiveMana(MANA_STATE[self.state]) -- Gives the boss mana (scripted mana regeneration) based on his current state
	Dynamic_Wrap(pudgeBossAi, self.stateThinks[ self.state ])( self ) -- Perform actions pertaining to a certain state
	self.timeSinceLastCast = self.timeSinceLastCast + AI_THINK_INTERVAL -- Increase the amount of time since a spell has been cast by the think interval
	return AI_THINK_INTERVAL
end

--==============================--
--[[State Instance Functions]]--
--==============================--
function pudgeBossAi:CastingState() -- This prevents the boss from gaining mana during certain cast states
	if self.unit:HasModifier("modifier_fart_jumping") == false and self.unit:IsChanneling() == false then -- Checks if the boss is in a fart jump
		pudgeBossAi:ChangeAggroTarget( self ) -- Begin attacking the closest target
		if (self.previousState ~= AI_STATE_CASTING_STATE) then -- prevents infinite looping
			self.state = self.previousState -- return to the previous state
		else 
			self.state = AI_STATE_NEUTRAL_STATE -- if for some reason the previous state was also casting, default to neutral
		end
	end
end

function pudgeBossAi:NeutralState() -- Performs attacks and cast spells using neutral table values
	local aggroTarget = self.unit:GetAggroTarget()
	if aggroTarget == nil then 
		pudgeBossAi:AggroTarget( self ) -- Finds a target within INNER_SEARCH_RANGE to attack
	else
		pudgeBossAi:ChangeAggroTarget( self ) -- If the current target has moved outside of the INNER_SEARCH_RANGE, then attack a new target
	end
	if self.unit:GetCurrentActiveAbility() == nil then
		local ability = pudgeBossAi:FindAbility( self ) -- Choose an ability to cast
		if self.timeSinceLastCast >= AI_BASE_TIME_SINCE_LAST_CAST then
			pudgeBossAi:AttemptCast( self, ability, 0.1, 0.925) -- Determines whether the ability should be cast or not
		end
	end
	pudgeBossAi:BackgroundCheck( self )
end

--==============================--
--[[Ability Instance Functions]]--
--==============================--
function pudgeBossAi:FindAbility( self ) -- Chooses an ability to cast
	local randomNumber = math.random()
	local chanceCounter = 0
	local ability = {}
	--[[ Goes through the list of bosses' abilities. Each ability has been assigned a number between 0 and 1.0 (their % chance to be cast). Goes to the first ability
	and checks if its percentage number ranges from 0 to 0 + ability1%. If not, it moves to the second ability, starting at 0+ability1% to 0+ability2%. Continues to do
	this until an ability corresponds to the random number]]--
	for k, v in pairs(self.castTable) do 
		if randomNumber > chanceCounter and randomNumber <= chanceCounter + v then
			ability = self.unit:FindAbilityByName(ABILITY_TABLE[k]) -- References the ability table that pertains to the key
		end	
		chanceCounter = chanceCounter + v
	end
	return ability
end

function pudgeBossAi:AttemptCast( self, ability, BC, CM )
	--[[ Attempts to cast an ability. The longer the time since the last ability was cast, the higher the chance of another aiblity to be cast. The maximum time is 4 
	seconds with current values	]]--
	local baseChance = BC
	local chanceMultiplier = CM
	local caster = self.unit
	local abilityLevel = ability:GetLevel()
	if self.timeSinceLastCast >= AI_BASE_TIME_SINCE_LAST_CAST + AI_THINK_INTERVAL * self.currentInterval and math.random() <= baseChance * 	chanceMultiplier 
	* self.currentInterval and self.timeSinceLastCast % AI_THINK_INTERVAL * 4 == 0 and ability:IsCooldownReady() == true and 
	caster:GetMana() >= ability:GetManaCost(abilityLevel-1) and caster:HasModifier("modifier_knockback") == false and caster:IsHexed() == false and 
	caster:IsSilenced() == false and caster:IsStunned() == false and caster:IsChanneling() == false then
		caster:CastAbilityNoTarget(ability, caster:GetPlayerOwnerID() )
		ability:StartCooldown(ability:GetLevelSpecialValueFor("cooldown", ability:GetLevel()-1) --[[Returns:table
		No Description Set
		]])
		self.state = AI_STATE_CASTING_STATE
		debugPrint(caster:GetUnitName().." "..caster:GetEntityIndex().." has successfully casted "..ability:GetName(), DEBUG)
		self.timeSinceLastCast = 0
		self.currentInterval = 0
	else
		self.currentInterval = self.currentInterval + AI_THINK_INTERVAL
	end
end

function pudgeBossAi:GrowthNDecay(self, ability, growthTime, growTo)
	local abilityKey = {} -- Create an empty ability key
	local change = 0
	for k, v in pairs(ABILITY_TABLE) do -- Reference the ability table and find the key for the ability
		if ability:GetName() == v then
			abilityKey = k
		end
	end
	local currentChance = self.castTable[abilityKey] -- Find the current cast chance for the ability
	local baseChance = BASE_CAST_TABLE[abilityKey] -- Find the base chance to cast for this ability
	local diff = currentChance - baseChance -- difference between the current chance and base chance
	if self.abilityState[abilityKey] == ABILITY_STATE_DECAYING then
		change = ((1 - math.exp(-AI_THINK_INTERVAL / DECAY_TIME[abilityKey])) * diff) -- Calculate the change in percentage using an exponential formula
		self.castTable[abilityKey] = currentChance - change -- Apply the change
		self.abilityPointsPool = self.abilityPointsPool + change -- Send the points in pool to determine if there is surplus or a deficit	
	else 
		--change = math.log(math.exp(AI_THINK_INTERVAL/(growthTime/GROWTH_CONSTANT))) * (currentChance - growTo) / math.log(10) 
		--[[ change in percentage using a logarithmic formula]]--
		self.castTable[abilityKey] = ((currentChance - math.log(math.exp(AI_THINK_INTERVAL/(growthTime/GROWTH_CONSTANT))) * (currentChance - growTo) / math.log(10))
		+ (currentChance - math.log(math.exp(AI_THINK_INTERVAL/(growthTime/GROWTH_CONSTANT))) * (-currentChance - growTo) / math.log(10)))/2
		self.abilityPointsPool = self.abilityPointsPool + (currentChance - self.castTable[abilityKey]) -- Send the points in pool to determine if there is surplus or a deficit	
	end
	debugPrint("The chance of "..ABILITY_TABLE[abilityKey].." to be cast has been changed from "..currentChance.." to "..self.castTable[abilityKey], DEBUG)
end

function pudgeBossAi:AbilityReadjustment( self )
	local distribution = self.abilityPointsPool / table.getn(ABILITY_TABLE)
	debugPrint("The distribution rate has been set to "..distribution, DEBUG) 
	for k, v in pairs(self.castTable) do
		self.castTable[k] = v + distribution
		debugPrint("The chance of "..ABILITY_TABLE[k].." to be cast has adjusted from "..v.." to "..self.castTable[k], DEBUG) 
		self.abilityPointsPool = self.abilityPointsPool - distribution
		debugPrint(self.abilityPointsPool.." remain in the ability points pool", DEBUG) 
	end	
end

function pudgeBossAi:BackgroundCheck( self ) -- Changes ability cast chance values based on certain background events
	pudgeBossAi:FartJumpCheck(self)
	pudgeBossAi:GrowthNDecay(self, self.unit:FindAbilityByName(ABILITY_TABLE[KEY_DEATH_GRIP]), nil, nil)
	pudgeBossAi:AbilityReadjustment(self)
end

function pudgeBossAi:FartJumpCheck( self)
--[[Fart Jump Ability
	Does a background check to determine whether the pudge boss should perform a fart jump or not. The more units outside of the INNER_SEARCH_RADIUS, the higher 
	the chance.]]--
	local ability = self.unit:FindAbilityByName(ABILITY_TABLE[KEY_FART_JUMP])
	local selectedHeroes = {}
	local heroes = HeroList:GetAllHeroes() 
	local origin = self.unit:GetAbsOrigin() 
	local counter = 1
	for k, v in pairs(heroes) do -- Find all alive heroes
		local pass = UnitFilter(v, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED, DOTA_TEAM_GOODGUYS)
		if pass == 1 and v:IsAlive() == true then
			table.insert(selectedHeroes, counter, v)
			counter = counter + 1
		end		
	end
	local numberAlive = table.getn(selectedHeroes) -- Set the number of alive heroes
	local outside = 0
	for k, v in pairs(selectedHeroes) do -- set the number of heroes outside the INNER_SEARCH_RANGE
		if (origin - v:GetAbsOrigin()):Length2D() >= INNER_SEARCH_RANGE then
			outside = outside + 1
		end
	end	
	local fraction = outside / numberAlive
	--DebugPrint("fraction "..fraction, DEBUG)
	if numberAlive > 0 then 
		if fraction == 0 then 
			self.abilityState[KEY_FART_JUMP] = ABILITY_STATE_DECAYING
			pudgeBossAi:GrowthNDecay(self, ability, nil, nil)
		elseif fraction <= (numberAlive*0.25/numberAlive) and self.castTable[KEY_FART_JUMP] <= 0.0625 then
			self.abilityState[KEY_FART_JUMP] = ABILITY_STATE_GROWING
			pudgeBossAi:GrowthNDecay(self, ability, 15.0, 0.0625)
		elseif fraction <= (numberAlive*0.5/numberAlive) and self.castTable[KEY_FART_JUMP] <= 0.078125 then -- mutliples of 1.25?
			self.abilityState[KEY_FART_JUMP] = ABILITY_STATE_GROWING
			pudgeBossAi:GrowthNDecay(self, ability, 7.5, 0.078125)
		elseif fraction <= (numberAlive*0.75/numberAlive) and self.castTable[KEY_FART_JUMP] <= 0.09765625 then 
			self.abilityState[KEY_FART_JUMP] = ABILITY_STATE_GROWING
			pudgeBossAi:GrowthNDecay(self, ability, 3.75, 0.09765625)
		elseif fraction < (numberAlive*1.0/numberAlive) and self.castTable[KEY_FART_JUMP] <= 0.1220703125 then 
			self.abilityState[KEY_FART_JUMP] = ABILITY_STATE_GROWING
			pudgeBossAi:GrowthNDecay(self, ability, 1.875, 0.1220703125)
		elseif fraction == 1 and self.castTable[KEY_FART_JUMP] <= 0.244140625 then
			self.abilityState[KEY_FART_JUMP] = ABILITY_STATE_GROWING
			pudgeBossAi:GrowthNDecay(self, ability, 0.9375, 0.244140625)
		else
			self.abilityState[KEY_FART_JUMP] = ABILITY_STATE_DECAYING
			pudgeBossAi:GrowthNDecay(self, ability, nil, nil)
		end
	else
		self.abilityState[KEY_FART_JUMP] = ABILITY_STATE_DECAYING
		pudgeBossAi:GrowthNDecay(self, ability, nil, nil)
	end
end
--=============================--
--[[Attack Instance Functions]]--
--=============================--
function pudgeBossAi:AggroTarget( self )	-- Finds a target within INNER_SEARCH_RANGE to attack
	local attacker = self.unit
	local origin = attacker:GetAbsOrigin() 
	local teamNumber = attacker:GetTeam()
	local units = FindUnitsInRadius(teamNumber, origin, nil, INNER_SEARCH_RANGE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, 
	FIND_CLOSEST, false) -- Find enemy hero units in INNER_SEARCH_RANGE
	local failure = false
	repeat
		for k, v in pairs(units) do 
			if v:IsAlive() == true then
				if k == 1 then -- Finds the closest target
					local order = 
					{
						UnitIndex = attacker:entindex(),
						OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
						TargetIndex = v:entindex()
					}
					ExecuteOrderFromTable(order) -- Attack the closest target
					if (attacker:GetAggroTarget() == v:entindex()) then
						debugPrint(attacker:GetUnitName().." "..attacker:GetEntityIndex().." has successfully set its aggro target to "..v:GetName().." "..v:GetEntityIndex(), DEBUG)
					else
						debugPrint(attacker:GetUnitName().." "..attacker:GetEntityIndex().." has failed set its aggro target to "..v:GetName().." "..v:GetEntityIndex(), DEBUG)	
						failure = true
					end
				end
			else
				table.remove(units, k) -- If the target is dead, remove it
			end
		end
		if failure == true then break end
	until attacker:GetAggroTarget() ~= nil or table.getn(units) == 0 or attacker:IsChanneling() == true
end

function pudgeBossAi:ChangeAggroTarget( self )		-- Changes the attack target, if the current target is outside of the INNER_SEARCH_RANGE
	local attacker = self.unit
	local origin = attacker:GetAbsOrigin() 
	local aggroTarget = attacker:GetAggroTarget()
	local teamNumber = attacker:GetTeam()
	local units = FindUnitsInRadius(teamNumber, origin, nil, INNER_SEARCH_RANGE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
	if table.getn(units) ~= 0 then 
		for k, v in pairs(units) do
			if (v ~= attacker:GetAggroTarget()) then  -- Check if current aggro target is in INNER_SEARCH RANGE
				table.remove(units, k)
			end
		end
		if table.getn(units) == 0 then -- If the table is empty, then the current target is not within range. Issue order to switch targets
			pudgeBossAi:AggroTarget( self )
			debugPrint("Issuing new order for "..attacker:GetUnitName().." "..attacker:GetEntityIndex().." to attack a new target", DEBUG)
		end
	end
end
