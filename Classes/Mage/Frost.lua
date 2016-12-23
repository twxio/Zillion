local parent = CreateFrame("frame", "Recount", UIParent)
parent:SetSize(10, 10);  -- Width, Height
parent:SetPoint("TOPLEFT", 0, 0)
parent:RegisterEvent("ADDON_LOADED")
parent.t = parent:CreateTexture()
parent.t:SetColorTexture(0, 1, 0, 1)
parent.t:SetAllPoints(parent)

local LibDraw = LibStub("LibDraw-1.0")

local tick = 0;
local WoW = LibStub("WoW")

function start()	
	c = WoW.ClassColors[select(3,UnitClass("player"))]
	parent.t:SetColorTexture(c.R, c.G, c.B, 1)	
	LibDraw.Enable(0.005)
end

function update(self, elapsed)
	tick = tick + elapsed	
	if tick >= .50 then
		Pulse()
		tick = 0
	end
end

local lastEnemyCount = 0

LibDraw.Sync(function()
	if UnitExists("Target") then
		local pX,  pY,  pZ = ObjectPosition("player")
		local tX,  tY,  tZ = ObjectPosition("target")
		local hitbox = 8
		LibDraw.Circle(tX, tY, tZ, hitbox);
		LibDraw.Line(pX, pY, pZ, tX, tY, tZ)
	end
end)

function Pulse()	
	if UnitIsDeadOrGhost("Player") then
		return;
	end
	
	-- Do out of combat stuff

	if WoW.PlayerHasBuff("Ice Block") then
		return;
	end
	
	if not UnitIsVisible("pet") then
		start, duration, enabled = GetSpellCooldown("Summon Water Elemental")
		if duration ~= 0 then 
			return;
		end
		if not UnitCastingInfo("Player") then
			WoW.CastSpell("Summon Water Elemental")
		end
	end
	
	if WoW.PlayerBuffRemainingTime("Ice Barrier") < 20 then
		start, duration, enabled = GetSpellCooldown("Ice Barrier")
		if duration ~= 0 then 
			return;
		end
		WoW.CastSpell("Ice Barrier")
		return;
	end

	if not UnitExists("Target") then 		
		PetStopAttack()		
		return;
	end	
	
	if not UnitCanAttack("Player", "Target") then 
		return;	
	end
	
	if not WoW.InCombat() then		
		return;		
	end
	
	-- Do InCombat Stuff	
	
	if UnitCanAttack("Pet", "Target") and UnitExists("Target") then 
		PetAttack("target")
	else
		PetStopAttack()		
		return;
	end	
		
	local enemiesInMeleeRangeOfTarget = WoW.EnemyUnitsInRangeXofTarget(8)
	if enemiesInMeleeRangeOfTarget > 0 and lastEnemyCount ~= enemiesInMeleeRangeOfTarget then
		WoW.Log('Enemies in range 8 of target: ' .. enemiesInMeleeRangeOfTarget) 
		lastEnemyCount = enemiesInMeleeRangeOfTarget
	end
		
	-- Survival Stuff (Higest Priority)
	if WoW.GetHealth("Player") < 20 and WoW.SpellCharges("Ice Block") > 0 and WoW.CanCast("Ice Block", 0, false) then
		WoW.CastSpell("Ice Block");
		return;
	end;	
	
	-- Rotation Stuff 	
	if WoW.CanCast("Ebonbolt", 40, true) then
		WoW.CastSpell("Ebonbolt");
		return;
	end		
	if WoW.CanCast("Icy Veins", 40, true) then
		WoW.CastSpell("Icy Veins");
		return;
	end		
	if WoW.CanCast("Ray of Frost", 40, true) then
		WoW.CastSpell("Ray of Frost");
		return;
	end	
	if WoW.CanCast("Frozen Orb", 40, true) then
		WoW.CastSpell("Frozen Orb");
		return;
	end
	if WoW.CanCast("Frozen Touch", 40, true) and not WoW.PlayerHasBuff("Fingers of Frost") then
		WoW.CastSpell("Frozen Touch");
		return;
	end;
	if WoW.CanCast("Flurry", 40, true) and WoW.PlayerHasBuff("Brain Freeze") then
		WoW.CastSpell("Flurry");
		return;
	end;
	if (WoW.CanCast("Ice Lance", 40, true) and WoW.PlayerHasBuff("Fingers of Frost")) or (UnitMovementFlags("Player") ~= 0 and UnitExists("target")) then
		WoW.CastSpell("Ice Lance");
		return;
	end;
	if WoW.CanCast("Glacial Spike", 40, true) then
		WoW.CastSpell("Glacial Spike");
		return;
	end;
	if WoW.CanCast("Frostbolt", 40, true) then
		WoW.CastSpell("Frostbolt");
		return;
	end;
end

parent:SetScript("OnUpdate", update)
start()