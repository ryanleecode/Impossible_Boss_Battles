-- This is the entry-point to your game mode and should be used primarily to precache models/particles/sounds/etc

require('internal/util')
require('gamemode')


function Precache( context )    
  --[[
      This function is used to precache resources/units/items/abilities that will be needed
      for sure in your game and that will not be precached by hero selection.  When a hero
      is selected from the hero selection screen, the game will precache that hero's assets,
      any equipped cosmetics, and perform the data-driven precaching defined in that hero's
      precache{} block, as well as the precache{} block for any equipped abilities.

      See GameMode:PostLoadPrecache() in gamemode.lua for more information
    ]]

    print("[IBB] Performing Pre-Load precache")

    _G.PRECACHE_TABLE = LoadKeyValues("scripts/kv/precache.kv")

    for k,_ in pairs(PRECACHE_TABLE.UnitSync) do
        PrecacheUnitByNameSync(k, context)
    end

    for k,_ in pairs(PRECACHE_TABLE.ItemSync) do
        PrecacheItemByNameSync(k, context)
    end

    for resource_type,v in pairs(PRECACHE_TABLE.Resource) do
        for k,_ in pairs(v) do
            PrecacheResource(resource_type, k, context)
        end
    end

    print("[IBB] Pre-Load precache done!")
end

-- Create the game mode when we activate
function Activate()
  GameRules.GameMode = GameMode()
  GameRules.GameMode:_InitGameMode()
end
  