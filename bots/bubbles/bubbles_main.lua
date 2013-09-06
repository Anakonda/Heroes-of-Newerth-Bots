local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic		 = true
object.bRunBehaviors	= true
object.bUpdates		 = true
object.bUseShop		 = true

object.bRunCommands	 = true 
object.bMoveCommands	 = true
object.bAttackCommands	 = true
object.bAbilityCommands = true
object.bOtherCommands	 = true

object.bReportBehavior = false
object.bDebugUtility = false

object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core		 = {}
object.eventsLib	 = {}
object.metadata	 = {}
object.behaviorLib	 = {}
object.skills		 = {}

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


BotEcho(object:GetName()..' loading bubbles_main...')


-- hero_<hero>  to reference the internal hon name of a hero, Hero_Yogi ==wildsoul
object.heroName = 'Hero_bubbles'


--   item buy order. internal names  
--[[
behaviorLib.StartingItems  = {}
behaviorLib.LaneItems  = {}
behaviorLib.MidItems  = {}
behaviorLib.LateItems  = {}
]]--
-- skillbuild table, 0=q, 1=w, 2=e, 3=r, 4=attri
object.tSkills = {
	0, 2, 0, 1, 0,
	3, 0, 1, 1, 1, 
	3, 2, 2, 2, 4,
	3, 4, 4, 4, 4,
	4, 4, 4, 4, 4,
}

------------------------------
--	 skills			   --
------------------------------

function object:SkillBuild()
	core.VerboseLog("skillbuild()")

-- takes care at load/reload, <name_#> to be replaced by some convinient name.
	local unitSelf = self.core.unitSelf
	if  skills.abilSurf == nil then
		
		skills.abilSurf = core.WrapInTable(unitSelf:GetAbility(0))
		skills.abilSurf.nCastTime = 0 --When surf was last used
		skills.abilSurf.vecCastPos = Vector3.Create(0,0) --Where it was used
		skills.abilSurf.nCastAngle = 0 --Angle where shell went
		skills.abilSurf.nShellLifeTime = 2817

		skills.abilSong = unitSelf:GetAbility(1)
		skills.abilCover = unitSelf:GetAbility(2)
		skills.abilUlt = unitSelf:GetAbility(3)
		skills.abilAttributeBoost = unitSelf:GetAbility(4)
	end
	if unitSelf:GetAbilityPointsAvailable() <= 0 then
		return
	end
	
   
	local nlev = unitSelf:GetLevel()
	local nlevpts = unitSelf:GetAbilityPointsAvailable()
	for i = nlev, nlev+nlevpts do
		unitSelf:GetAbility( object.tSkills[i] ):LevelUp()
	end
end

------------------------------------------------------
--			onthink override					  --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
	self:onthinkOld(tGameVariables)

	-- custom code here
end
object.onthinkOld = object.onthink
object.onthink 	= object.onthinkOverride


----------------------------------------------
--			oncombatevent override		--
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function object:oncombateventOverride(EventData)
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent	 = object.oncombateventOverride


------------------------------------------------------
--			customharassutility override		  --
-- change utility according to usable spells here   --
------------------------------------------------------
-- @param: iunitentity hero
-- @return: number
local function CustomHarassUtilityFnOverride(hero)
	return 40
end
-- assisgn custom Harrass function to the behaviourLib object
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride   


--------------------------------------------------------------
--					Harass Behavior					   --
-- All code how to use abilities against enemies goes here  --
--------------------------------------------------------------
-- @param botBrain: CBotBrain
-- @return: none
--
local function HarassHeroExecuteOverride(botBrain)
	
	local unitTarget = behaviorLib.heroTarget
	if unitTarget == nil then
		return object.harassExecuteOld(botBrain) --Target is invalid, move on to the next behavior
	end
	
	local nTime = HoN.GetMatchTime()

	local unitSelf = core.unitSelf
	local vecMyPosition = unitSelf:GetPosition() 
	local nAttackRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
	local nMyExtraRange = core.GetExtraRange(unitSelf)
	
	local vecTargetPosition = unitTarget:GetPosition()
	local nTargetExtraRange = core.GetExtraRange(unitTarget)
	local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)
	
	local nLastHarassUtility = behaviorLib.lastHarassUtil
	local bCanSee = core.CanSeeUnit(botBrain, unitTarget)	
	local bActionTaken = false
	
	
	if skills.abilSurf:CanActivate() then
		local shell = object.getShellPosition()
		if skills.abilSurf.nCastTime + skills.abilSurf.nShellLifeTime < nTime then
			bActionTaken = object.useSurf(botBrain, vecTargetPosition)
		elseif Vector3.Distance2DSq(object.getShellPosition(), vecTargetPosition) < 300*300 then
			bActionTaken = object.useSurf(botBrain, vecTargetPosition)
		end
	end

	if not bActionTaken and skills.abilSong:CanActivate() and nTargetDistanceSq < 160000 then
		core.OrderAbility(botBrain, skills.abilSong)
	end
	
	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end 
end
-- overload the behaviour stock function with custom 
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride



---------------------------------------------
--			  New functions			  --
---------------------------------------------

 local function getUnitsBetween(startPoint, endPoint, radius)
	local distance = vectorLength(startPoint, endPoint)

	local units = HoN.GetUnitsInRadius(startPoint, distance, core.UNIT_MASK_UNIT + core.UNIT_MASK_ALIVE)

	local unitsBetween = {}

	-- Ax + By + C = 0
	local A = -(endPoint.y-startPoint.y)
	local B = endPoint.x-startPoint.x
	local C = startPoint.x*endPoint.y - endPoint.x*startPoint.y

	local radiusSQ = radius * radius
	local divisor = (A*A+B*B)
	for key,unit in pairs(units) do
		local unitPos = unit:GetPosition()
		if radiusSQ <= ((A * unitPos.x + B * unitPos.y + C)^2)/divisor and distance*distance > Vector3.Distance2DSq(endPoint, unitPos) then
			unitsBetween[key]=unit
		end
	end
	return unitsBetween
end


function object.getShellPosition()
	local nCurrentTime = HoN.GetMatchTime()
	local nTravelTime = nCurrentTime - skills.abilSurf.nCastTime
	if nTravelTime > skills.abilSurf.nShellLifeTime then
		return
	end
	local nDistance = nTravelTime * 850/1000
	return Vector3.Create(math.cos(skills.abilSurf.nCastAngle)*nDistance + skills.abilSurf.vecCastPos.x, math.sin(skills.abilSurf.nCastAngle)*nDistance + skills.abilSurf.vecCastPos.y)
end

function object.useSurf(botBrain, target)
	if skills.abilSurf:CanActivate() then
		local nTime = HoN.GetMatchTime()
		if nTime - skills.abilSurf.nShellLifeTime > skills.abilSurf.nCastTime then
			BotEcho(tostring(nTime- skills.abilSurf.nShellLifeTime).." " ..tostring(skills.abilSurf.nCastTime))
			skills.abilSurf.nCastTime = nTime
			local vecCastPos = core.unitSelf:GetPosition()
			skills.abilSurf.vecCastPos = vecCastPos

			local vecCastDirection = target - vecCastPos
			skills.abilSurf.nCastAngle = math.atan2(vecCastDirection.y, vecCastDirection.x)
			botBrain:OrderAbilityPosition(skills.abilSurf.object, target)
			return true
		elseif nTime - 100 > skills.abilSurf.nCastTime then
			botBrain:OrderAbility(skills.abilSurf.object)
			return true
		end
	end
	return false
end
