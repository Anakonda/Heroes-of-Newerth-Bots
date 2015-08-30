
local _G = getfenv(0)
local object = _G.object

object.abilityLib = object.abilityLib or {}
local abilityLib = object.abilityLib



--Monarch
object.abilityLib.tAbilities["Ability_Monarch1"] = { targetScheme = abilityLib.targetSchemes.enemy + abilityLib.targetSchemes.hero, orderType = "targetunit", role = "cc", ultimate = false }
object.abilityLib.tAbilities["Ability_Monarch2"] = { targetScheme = abilityLib.targetSchemes.ally + abilityLib.targetSchemes.hero, orderType = "targetunit", role = "heal", ultimate = false }
object.abilityLib.tAbilities["Ability_Monarch3"] = { targetScheme = abilityLib.targetSchemes.enemy + abilityLib.targetSchemes.hero + abilityLib.targetSchemes.creep, orderType = "targetpoint", role = "cc", ultimate = false }
object.abilityLib.tAbilities["Ability_Monarch4"] = { targetScheme = abilityLib.targetSchemes.ally + abilityLib.targetSchemes.hero, orderType = "targetpoint", role = "support", ultimate = true }

object.abilityLib.tAbilities["Ability_Midas1"] = { targetScheme = abilityLib.targetSchemes.enemy + abilityLib.targetSchemes.hero + abilityLib.targetSchemes.creep, orderType = "targetpoint", role = "nuke", ultimate = false }
object.abilityLib.tAbilities["Ability_Midas2"] = { targetScheme = abilityLib.targetSchemes.enemy + abilityLib.targetSchemes.hero + abilityLib.targetSchemes.creep, orderType = "targetpoint", role = "nuke", ultimate = false }
object.abilityLib.tAbilities["Ability_Midas3"] = { targetScheme = abilityLib.targetSchemes.enemy + abilityLib.targetSchemes.hero + abilityLib.targetSchemes.creep, orderType = "targetpoint", role = "escape", ultimate = false }
object.abilityLib.tAbilities["Ability_Midas4"] = { targetScheme = abilityLib.targetSchemes.enemy + abilityLib.targetSchemes.hero + abilityLib.targetSchemes.creep, orderType = "passive", role = "cc", ultimate = false }
