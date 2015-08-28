
local _G = getfenv(0)
local object = _G.object

object.core = object.core or {}

local core, eventsLib, behaviorLib, metadata, illusionLib = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.illusionLib

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
	= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
	= _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
	
local nSqrtTwo = math.sqrt(2)

object.abilityLib = object.abilityLib or {}
local abilityLib = object.abilityLib


abilityLib.targetSchemes = {"ally" = 0x01, "neutral" = 0x02, "enemy" = 0x04, "creep" = 0x10, "hero" = 0x20 } -- ally + hero means this ability can target ally heroes

-- Just to list possible values
abilityLib.orderTypes = {"passive", "notarget", "targetunit", "targetpoint" } --choose one. vectors will be added later
abilityLib.roles = {"support", "carry", "cc", "nuke", "escape" }

--[[
string typename => { int targetScheme, string orderType, string role, bool ultimate }
]]
abilityLib.abilities = {}

function abilityLib.loadAbilities(strHeroTypeName)
	runfile "abilitydb/" .. strHeroTypeName:sub(6) .. ".lua"
end

