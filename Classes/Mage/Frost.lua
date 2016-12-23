local parent = CreateFrame("frame", "Recount", UIParent)
parent:SetSize(0, 0);  -- Width, Height
parent:SetPoint("TOPLEFT", 0, 0)
parent:RegisterEvent("ADDON_LOADED")
parent.t = parent:CreateTexture()
parent.t:SetAllPoints(parent)

local button = CreateFrame("Button", nil, UIParent)
button:SetPoint("TOP", UIParent, "TOP", 0, 0)
button:SetWidth(85)
button:SetHeight(25)

button:SetText("DPS Test")
button:SetNormalFontObject("GameFontNormal")

local ntex = button:CreateTexture()
ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
ntex:SetTexCoord(0, 0.625, 0, 0.6875)
ntex:SetAllPoints()	
button:SetNormalTexture(ntex)

local htex = button:CreateTexture()
htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
htex:SetTexCoord(0, 0.625, 0, 0.6875)
htex:SetAllPoints()
button:SetHighlightTexture(htex)

local ptex = button:CreateTexture()
ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
ptex:SetTexCoord(0, 0.625, 0, 0.6875)
ptex:SetAllPoints()
button:SetPushedTexture(ptex)

local LibDraw = LibStub("LibDraw-1.0")

local clicked = false;

local tick = 0;
local inCombatTime = 0;
local WoW = LibStub("WoW")

function start()	
	c = WoW.ClassColors[select(3,UnitClass("player"))]
	parent.t:SetColorTexture(c.R, c.G, c.B, 1)	
	LibDraw.Enable(0.005)
end

function update(self, elapsed)
	tick = tick + elapsed	
	inCombatTime = inCombatTime + elapsed
	if tick >= .250 then
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
	
	if not WoW.InCombat() then		
		inCombatTime = 0;		
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
		inCombatTime = 0;
		return;		
	end	
		
	-- Do InCombat Stuff	
	local x = math.floor(inCombatTime)	
	button:SetText('Timer: ' .. x)
	if x >= 5 * 60 and clicked then	-- 5 mins DPS testing	
		PetStopAttack()	
		ClearTarget()
		WoW.Log("DPS Testing has completed.")
		button:SetText('DPS Test')		
		clicked = false;
		return;
	end
	
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
	if WoW.CanCast("Mirror Image", 40, true) then
		WoW.CastSpell("Mirror Image");
		return;
	end		
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

button:RegisterForClicks("AnyUp", "AnyDown")

function Click()
	clicked = true;
	WoW.Log('DPS Test Started...');
	TargetNearestEnemy()
	WoW.CastSpell("Ice Lance");
end

button:SetScript("OnClick", Click)
