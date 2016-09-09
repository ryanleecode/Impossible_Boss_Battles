if not Players then
    Players = class({})
end

function Players:Init( playerID, hero )
	if not self.PlayerTable then
		self.PlayerTable = {}
	end
end

function Players:Add( playerID, hero )
	if not self.PlayerTable then return end
	table.insert( self.PlayerTable, playerID, hero)
end

function Players:Remove( playerID )
	if not self.PlayerTable then return end
	table.remove( self.PlayerTable, playerID )
end