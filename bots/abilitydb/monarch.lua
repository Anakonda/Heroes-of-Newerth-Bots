
local _G = getfenv(0)
local object = _G.object

runfile "/bots/abilitylib.lua"

object.abilityLib = object.abilityLib or {}
local abilityLib = object.abilityLib

object.tInitAbilityData = function()
	object.abilityLib.tAbilities["Ability_Monarch1"] = { targetScheme = abilityLib.targetSchemes.enemy + abilityLib.targetSchemes.hero, orderType = "targetunit", role = "cc", ultimate = false }
	object.abilityLib.tAbilities["Ability_Monarch2"] = { targetScheme = abilityLib.targetSchemes.ally + abilityLib.targetSchemes.hero, orderType = "targetunit", role = "support", ultimate = false }
	object.abilityLib.tAbilities["Ability_Monarch3"] = { targetScheme = abilityLib.targetSchemes.enemy + abilityLib.targetSchemes.hero + abilityLib.targetSchemes.creep, orderType = "targetpoint", role = "cc", ultimate = false }
	object.abilityLib.tAbilities["Ability_Monarch4"] = { targetScheme = abilityLib.targetSchemes.ally + abilityLib.targetSchemes.hero, orderType = "targetpoint", role = "support", ultimate = false }
end
