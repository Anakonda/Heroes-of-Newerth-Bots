--Universal/abilitylib 


local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic 		= true
object.bRunBehaviors	= true
object.bUpdates 		= true
object.bUseShop 		= true

object.bRunCommands 	= true
object.bMoveCommands 	= true
object.bAttackCommands 	= true
object.bAbilityCommands = true
object.bOtherCommands 	= true

object.bReportBehavior = false
object.bDebugUtility = false
object.bDebugExecute = false


object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core 		= {}
object.eventsLib 	= {}
object.metadata 	= {}
object.behaviorLib 	= {}
object.skills 		= {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
	= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
	= _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading ability lib bot...')

object.heroName = 'Hero_Monarch'

local sMyRole = "support" -- TODO: riftwars - teambotgives you one, normal game - another DB?

local abilityLib = {}

local function testflag(set, flag)
	return set % (2*flag) >= flag
end

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 3, ShortSolo = 3, LongSolo = 3, ShortSupport = 3, LongSupport = 3, ShortCarry = 3, LongCarry = 3}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()

	local unitSelf = self.core.unitSelf

	if not bSkillsValid then
		skills[1] = unitSelf:GetAbility(0)
		skills[2] = unitSelf:GetAbility(1)
		skills[3] = unitSelf:GetAbility(2)
		skills[4] = unitSelf:GetAbility(3)
		
		if skills[1] and skills[2] and skills[3] and skills[4] then
			bSkillsValid = true
		else
			return
		end
	end
		
	if unitSelf:GetAbilityPointsAvailable() <= 0 then
		return
	end

	--Pick ult
	if skills[4]:CanLevelUp() then
		upgradedSkill = skills[4]
		skills[4]:LevelUp()
		return
	end

	local tSkillRoles = {}
	
	--TODO Pick these even more dynamically
	if sMyRole == "support" then
		tSkillRoles = {"heal", "cc", "support"}
	elseif sMyrole == "carry" then
		tSkillRoles = {"carry", "cc", "escape"}
	end
	
	for skill in pairs(skills) do
		local tAbilityLibEntry = tMyAbilityLib[skill:GetTypeName()]
		if core.tableContains(tSkillRoles, tAbilityLibEntry.role) then
			skill:LevelUp()
			return
		end	
	end

	for _,skill in pairs(skills) do
		if skill:CanLevelUp() then
			skill:LevelUp()
			return
		end
	end

	if upgradedSkill == nil then
		unitSelf:GetAbility(4):LevelUp() --stats
	end
end


local tMyAbilityLib = {}
local bAbilitylibInitialized = false
function object:onthinkOverride(tGameVariables)
	self:onthinkOld(tGameVariables)

	if not bAbilitylibInitialized and core.unitSelf and core.unitSelf:IsValid() then
		bAbilitylibInitialized = true
		local teambot = core.teamBotBrain
		abilityLib = teambot.GetAbilityLib()
		for _, skill in pairs(skills) do
			local sTypeName = skill:GetTypeName()
			tMyAbilityLib[sTypeName] = abilityLib.tAbilities[sTypeName]
		end
	end
end

object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride



local function HarassHeroExecuteOverride(botBrain)
	local unitTarget = behaviorLib.heroTarget
	if unitTarget == nil or not unitTarget:IsValid() then
		return false --can not execute, move on to the next behavior
	end
	
	local vecTargetPosition = unitTarget:GetPosition()
	local vecMyPosition = core.unitSelf:GetPosition()
	local nDistance2DSQ = Vector3.Distance2DSq(vecTargetPosition, vecMyPosition)
	
	local bActionTaken = false
	
	for _, skill in pairs(skills) do
		if not bActionTaken then
			if skill:CanActivate() then
				local tAbilityLibEntry = tMyAbilityLib[skill:GetTypeName()]
				if testflag(tAbilityLibEntry.targetScheme, abilityLib.targetSchemes.enemy) and testflag(tAbilityLibEntry.targetScheme, abilityLib.targetSchemes.hero) then
					if skill:GetRange() ^ 2 > nDistance2DSQ then
						if tAbilityLibEntry.orderType == "targetunit" then
							bActionTaken = core.OrderAbilityEntity(botBrain, skill, unitTarget)
						elseif tAbilityLibEntry.orderType == "targetpoint" then
							bActionTaken = core.OrderAbilityPosition(botBrain, skill, unitTarget:GetPosition())
						end
					end
				end
			end
		end
	end

	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end
	
	return true
end

object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

BotEcho('finished loading ability test bot')
