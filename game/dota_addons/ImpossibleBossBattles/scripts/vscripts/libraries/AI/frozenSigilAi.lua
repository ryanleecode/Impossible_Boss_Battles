LinkLuaModifier( "modifier_hits_to_kill", "libraries/modifiers/modifier_hits_to_kill.lua", LUA_MODIFIER_MOTION_NONE )

frozenSigilAi = {}
frozenSigilAi.__index = frozenSigilAi

DEBUG = true -- Debug Flag to print messages to Console

function Spawn(entityKeyValues) 
	local hUnit = thisEntity
	hUnit:AddNewModifier( hUnit, nil, "modifier_hits_to_kill", nil )
	--frozenSigilAi:CreateInstance( hUnit )
	debugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex(), DEBUG)
end