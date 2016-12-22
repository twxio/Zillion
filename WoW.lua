local WoW = LibStub:NewLibrary("WoW", 1)

function WoW.CastSpell(spellName)
    if UnitExists("Target") then 
		FaceDirection(GetAnglesBetweenObjects("Player", "Target"), true);	
	end;	
	WoW.Log('Casting: ' .. spellName);
	if UnitExists("Target") then 
		CastSpellByName(spellName, "Target");
	else
		CastSpellByName(spellName, "");
	end;	
end

function WoW.CanCast(spellName, range, requiresTarget)
	if requiresTarget then	
		if not UnitExists("Target") and target ~= player then 
			return false; 
		end;
		if not WoW.LOS("Target") then
			return false;
		end;
		if WoW.GetDistanceTo("Target") > range then 
			return false; 
		end;	
		if UnitIsDeadOrGhost("Target") then 
			return false;
		end;
	end;
	if UnitCastingInfo("Player") then 
		return false;
	end;
	if UnitChannelInfo("Player") then 
		return false;	
	end;		
	if UnitIsDeadOrGhost("Player") then 
		return false;
	end;
	if UnitMovementFlags("Player") ~= 0 and select(4, GetSpellInfo(spellName)) ~= 0 then -- If the player is moving and not trying to cast an instant cast spell
		return false;
	end;
	if not IsUsableSpell(spellName) then
		return false;
	end;
	start, duration, enabled = GetSpellCooldown(spellName)
	if duration ~= 0 then 
		return false;
	end;
	
	return true;
end

function WoW.LOS(unit)
	if not UnitExists(unit) then	
		return true;
	end
	local sX, sY, sZ = ObjectPosition("Player");
	local oX, oY, oZ = ObjectPosition(unit);
	local losFlags =  bit.bor(0x10, 0x100, 0x1)
	return TraceLine(sX, sY, sZ + 2.25, oX, oY, oZ + 2.25, losFlags) == nil;
end

function WoW.GetDistanceTo(unit)
	if not UnitExists(unit) then	
		return 999
	end
  local X1, Y1, Z1 = ObjectPosition(unit)
  local X2, Y2, Z2 = ObjectPosition("Player")
  return math.sqrt(((X1 - X2)^2) + ((Y1 - Y2)^2) + ((Z1 - Z2)^2))
end

function WoW.UnitsInRangeXofTarget(rangeX)
	if not UnitExists("Target") then 
		return 0
	end;

	local noUnits = 0;
	local count = GetObjectCount();		
	for i = 1, count do
		currentObj = GetObjectWithIndex(i);		
		if ObjectIsType(currentObj, ObjectTypes.Unit) then
			if GetDistanceBetweenObjects(currentObj, "target") < rangeX then			
				noUnits = noUnits + 1;
			end
		end
	end
	
	return noUnits
end

function WoW.EnemyUnitsInRangeXofTarget(rangeX)
	if not UnitExists("Target") then 
		return 0
	end;

	local noUnits = 0;
	local count = GetObjectCount();		
	for i = 1, count do
		currentObj = GetObjectWithIndex(i);		
		if ObjectIsType(currentObj, ObjectTypes.Unit) and currentObj ~= target then
			if GetDistanceBetweenObjects(currentObj, "target") < rangeX and UnitCanAttack("Player", currentObj) then			
				noUnits = noUnits + 1;
			end
		end
	end
	
	return noUnits
end

function WoW.SpellCharges(spell)
	charges = select(1, GetSpellCharges(spell))
	if charges ~= nil then
		return charges
	end;
		
	return 0;		
end

function WoW.PlayerHasBuff(buffName)
	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitBuff("Player", buffName)
	local getTime = GetTime()
    local remainingTime = 0
	if expirationTime == nil then 
		expirationTime = 0 
	end;		
    if expirationTime ~=0 then
		remainingTime = math.floor(expirationTime - getTime + 0.5)
    end
	if remainingTime == 0 then
		return false;	
	end;
	return true;
end

function WoW.PlayerBuffRemainingTime(buffName)
	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitBuff("Player", buffName)
	local getTime = GetTime()
    local remainingTime = 0
	if expirationTime == nil then 
		expirationTime = 0 
	end;		
    if expirationTime ~=0 then
		remainingTime = math.floor(expirationTime - getTime + 0.5)
    end
	
	return remainingTime
end

function WoW.InCombat()
	return UnitAffectingCombat("player");
end 

function WoW.GetHealth(unit)
  currentHealth = UnitHealth(unit) / UnitHealthMax(unit) * 100
  return currentHealth
end

local dtLog = date("%H-%M-%S");			
local LogFile = ""
if IsHackEnabled then
	LogFile = GetWoWDirectory() .. "\\" .. "Interface" .. "\\" ..  "Addons" .. "\\" .. "Zillion" .. "\\Logs\\" .. dtLog .."-log.txt"
end
	
function WoW.Log(message, color)
	if color == nil then 
		color = "|cffFFFFFF"
	end;
	local dt = date("%H:%M:%S");			
	print('[|cFFC00000'.. dt ..'|r] ' .. color .. message)
	if IsHackEnabled then
		WriteFile(LogFile, "[".. dt .."] " .. message .. "\n", true)
	end	
end