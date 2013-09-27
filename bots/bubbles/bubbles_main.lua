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

object.heroName = 'Hero_bubbles'

-----------------------------------------
--             Constants               --
-----------------------------------------

behaviorLib.nRecentDamageMul = 100


--   item buy order. internal names  

behaviorLib.StartingItems  = {"Item_MarkOfTheNovice", "2 Item_MinorTotem", "Item_GuardianRing", "Item_RunesOfTheBlight", "Item_ManaPotion"}
behaviorLib.LaneItems  = {"Item_Marchers", "Item_ManaRegen3", "Item_Bottle", "Item_Regen"}
behaviorLib.MidItems  = {"Item_Steamboots", "Item_PortalKey"}
behaviorLib.LateItems  = {"Item_Protect", "Item_FrostfieldPlate", "Item_Morph", "Item_Freeze"}

-- skillbuild table, 0=q, 1=w, 2=e, 3=r, 4=attri
object.tSkills = {
	0, 2, 0, 1, 0,
	3, 0, 1, 1, 1, 
	3, 2, 2, 2, 4,
	3, 4, 4, 4, 4,
	4, 4, 4, 4, 4,
}


object.nSurfUp = 12
object.nSongUp = 8
object.nUltUp = 35

object.nSurfUse = 15
object.nSongUse = 15
object.nUltUse = 35

object.nSurfTreshold = 35
object.nCoverTreshold = 25 --for retreat
object.nPortalKeyTreshold = 35
object.nSongTreshold = 45
object.nUltTreshold = 60

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

local function funcFindItemsOverride(botBrain)
	object.FindItemsOld(botBrain)

	core.ValidateItem(core.itemSheepstick)
	core.ValidateItem(core.itemFrostfieldPlate)
	core.ValidateItem(core.itemPortalKey)

	--only update if we need to
	if core.itemSheepstick and core.itemFrostfieldPlate and core.itemPortalKey then
		return
	end

	local inventory = core.unitSelf:GetInventory(false)
	for slot = 1, 6, 1 do
		local curItem = inventory[slot]
		if curItem then
			if core.itemSheepstick == nil and curItem:GetName() == "Item_Morph" then
				core.itemSheepstick = core.WrapInTable(curItem)
			elseif core.itemFrostfieldPlate == nil and curItem:GetName() == "Item_FrostfieldPlate" then
				core.itemFrostfieldPlate = core.WrapInTable(curItem)
			elseif core.itemPortalKey == nil and curItem:GetName() == "Item_PortalKey" then
				core.itemPortalKey = core.WrapInTable(curItem)
			end
		end
	end
end
object.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride

function object:onthinkOverride(tGameVariables)
	self:onthinkOld(tGameVariables)


	-- custom code here
end
object.onthinkOld = object.onthink
object.onthink 	= object.onthinkOverride

----------------------------------------------
--			oncombatevent override	    	--
----------------------------------------------
function object:oncombateventOverride(EventData)
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent	 = object.oncombateventOverride


local function CustomHarassUtilityFnOverride (hero)
	local nUtility = 0

	if skills.abilSurf:CanActivate() then
		nUtility = nUtility + object.nSurfUp
	end

	if skills.abilSong:CanActivate() then
		nUtility = nUtility + object.nSongUp
	end

	if skills.abilUlt:CanActivate() then
		nUtility = nUtility + object.nUltUp
	end

	return nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride   

--------------------------------------------------------------
--					Harass Behavior					   --
-- All code how to use abilities against enemies goes here  --
--------------------------------------------------------------
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

	local vecShellPos = object.getShellPosition()

	if skills.abilSurf:CanActivate() then
		if object.nSurfTreshold < nLastHarassUtility and skills.abilSurf.nCastTime + skills.abilSurf.nShellLifeTime < nTime then
			bActionTaken = object.useSurf(botBrain, vecTargetPosition)
		elseif vecShellPos ~= nil then
			if nTargetDistanceSq + 400 < Vector3.Distance2DSq(object.getShellPosition(), vecMyPosition) then --Shell have just passed the target
				bActionTaken = object.useSurf(botBrain, vecTargetPosition)                   --Now blink on top of target
			end
		end
	end

	if not bActionTaken and not skills.abilSurf:CanActivate() and core.itemPortalKey and core.itemPortalKey:CanActivate() then
		bActionTaken = core.OrderItemPosition(botBrain, unitSelf, core.itemPortalKey, vecTargetPosition)
	end

	if not bActionTaken and object.nSongTreshold < nLastHarassUtility and skills.abilSong:CanActivate() and nTargetDistanceSq < (400 + nMyExtraRange) * (400 + nMyExtraRange) then
		core.OrderAbility(botBrain, skills.abilSong)
	end

	if not bActionTaken and object.nUltTreshold < nLastHarassUtility then
		local funcWeighting = function(unit)
			if unit:IsHero() then
				return 1
			else
				return 0
			end
		end
		local vecUltPosition = core.AoETargeting(unitSelf, skills.abilUlt:GetRange() + nMyExtraRange, 400, true, unitTarget, core.enemyTeam, funcWeighting)
		if vecUltPosition ~= nil then
			bActionTaken = core.OrderAbilityPosition(botBrain, skills.abilUlt, vecUltPosition)
		end
	end

	if not bActionTaken and core.itemFrostfieldPlate ~= nil and core.itemFrostfieldPlate:CanActivate() then
		botBrain:OrderItem(core.itemFrostfieldPlate.object)
		bActionTaken = true
	end

	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end 
end
-- overload the behaviour stock function with custom 
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride


function behaviorLib.DontBreakChannelExecuteOverride(botBrain)
	if core.unitSelf:IsInvulnerable() then
		return behaviorLib.RetreatFromThreatBehavior["Execute"](botBrain)
	else
		return true
	end
end

behaviorLib.DontBreakChannelBehavior["Execute"] = behaviorLib.DontBreakChannelExecuteOverride



function behaviorLib.RetreatFromThreatExecuteOverride(botBrain)
	bActionTaken = false

	nLastRetreatUtil = behaviorLib.lastRetreatUtil

	local nTime = HoN.GetMatchTime()

	local unitSelf = core.unitSelf
	local vecMyPosition = unitSelf:GetPosition()
	BotEcho("run")
	BotEcho(core.NumberElements(eventsLib.incomingProjectiles["heroes"]))

--[[
	if skills.abilSurf:CanActivate() and nLastRetreatUtil > object.nSurfTreshold then
		BotEcho("surf")
		if skills.abilSurf.nCastTime + skills.abilSurf.nShellLifeTime < nTime then
			bActionTaken = object.useSurf(botBrain, object.bestPointOnPath(vecMyPosition,  BotMetaData.FindPath(vecMyPosition, core.allyWell:GetPosition()), 1300))
		elseif nTime > skills.abilSurf.nCastTime + 1500 then
			bActionTaken = object.useSurf(botBrain)
		end
	end
]]
	if not bActionTaken and skills.abilCover:CanActivate() and (nLastRetreatUtil >= object.nCoverTreshold or eventsLib.recentDamageSec > 200 or eventsLib.recentDotTime > nTime -1000) then
		BotEcho("take cover")
		bActionTaken = core.OrderAbility(botBrain, skills.abilCover)
	end

bActionTaken = core.OrderAbility(botBrain, skills.abilCover)
--[[
	unitSelf = core.unitSelf

	if unitSelf:IsInvulnerable() then
		--check pk
	end
]]--
	if not bActionTaken and not unitSelf:IsChanneling() then
		bActionTaken = behaviorLib.RetreatFromThreatExecuteOld(botBrain)
	end
	return bActionTaken
end
behaviorLib.RetreatFromThreatExecuteOld = behaviorLib.RetreatFromThreatBehavior["Execute"]
behaviorLib.RetreatFromThreatBehavior["Execute"] = behaviorLib.RetreatFromThreatExecuteOverride

---------------------------------------------
--	         New functions	    		   --
---------------------------------------------
--               MATH                      --

-- Furthest point on path within range from start
function object.bestPointOnPath(vecStartPoint, tPath, nRange)
	local nRangeSQ = nRange * nRange
	local vecReturn = nil
	for i = #tPath - 1, 1, -1 do
		local nDistanceToFirstPointSQ = Vector3.Distance2DSq(tPath[i]:GetPosition(), vecStartPoint)
		local nDistanceToSecondPointSQ = Vector3.Distance2DSq(tPath[i + 1]:GetPosition(), vecStartPoint)
		if (nDistanceToFirstPointSQ < nRangeSQ and nDistanceToSecondPointSQ > nRangeSQ) or
			(nDistanceToFirstPointSQ > nRangeSQ and nDistanceToSecondPointSQ < nRangeSQ) then
			--[[
			A-------D----------B
			 \     /
			  \	  /
			   \ /
			    C

			C is start point
			D is point we want
			A and B are points from tPath
			]]
			--Law of sines
			local nAngleAtA = core.AngleBetween(tPath[i]:GetPosition() - vecStartPoint, tPath[i + 1]:GetPosition() - tPath[i]:GetPosition())
			local nAngleAtD = math.asin(math.sqrt(nDistanceToFirstPointSQ) * math.sin(nAngleAtA)/nRange)
			local nAngleAtC = math.pi - nAngleAtA - nAngleAtD
			--Law of sines again
			nLengtAtoD = nRange/math.sin(nAngleAtA)*math.sin(nAngleAtC)
			local vecReturn = tPath[i]:GetPosition() + Vector3.Normalize(tPath[i + 1]:GetPosition() - tPath[i]:GetPosition()) * nLengtAtoD
			core.DrawXPosition(vecReturn, 'yellow')
			return vecReturn
		end
	end
	--We should not be here
	return vecStartPoint + Vector3.Normalize(tPath[1]:GetPosition() - vecStartPoint) * nRange
end

local function getUnitsBetween(startPoint, endPoint, radius, team)
	team = team or -1

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
		if unit:GetTeam() == team and radiusSQ <= ((A * unitPos.x + B * unitPos.y + C)^2)/divisor and distance*distance > Vector3.Distance2DSq(endPoint, unitPos) then
			unitsBetween[key]=unit
		end
	end
	return unitsBetween
end


--           shell surf          --

function object.getShellPosition()
	local nCurrentTime = HoN.GetMatchTime()
	local nTravelTime = nCurrentTime - skills.abilSurf.nCastTime
	if nTravelTime > skills.abilSurf.nShellLifeTime or nTravelTime < 0 then
		return
	end
	local nDistance = nTravelTime * 850/1000
	return Vector3.Create(math.cos(skills.abilSurf.nCastAngle)*nDistance + skills.abilSurf.vecCastPos.x, math.sin(skills.abilSurf.nCastAngle)*nDistance + skills.abilSurf.vecCastPos.y)
end

function object.useSurf(botBrain, target)
	if skills.abilSurf:CanActivate() then
		local nTime = HoN.GetMatchTime()
		if nTime - skills.abilSurf.nShellLifeTime > skills.abilSurf.nCastTime and target ~= nil then
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
