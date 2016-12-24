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
local classColor 

function start()	
	classColor = WoW.ClassColors[select(3,UnitClass("player"))]
	parent.t:SetColorTexture(classColor.R, classColor.G, classColor.B, 1)	
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
		local _,  _,  pZ = ObjectPosition("player")
		local dist = GetDistanceBetweenObjects("player", "target")		
		local pX,  pY,  _ = GetPositionBetweenObjects("target", "player", dist - 4)
		local tX,  tY,  tZ = ObjectPosition("target")
		LibDraw.SetColorRaw(classColor.R, classColor.G, classColor.B, 1)	
		LibDraw.Line(pX, pY, pZ, tX, tY, tZ)		
		LibDraw.Circle(tX, tY, tZ, 8);	
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
	
	if WoW.PlayerBuffRemainingTime("Ice Barrier") <= 5 and not WoW.InCombat() then
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
	if WoW.GetHealth("Player") < 5 and WoW.SpellCharges("Ice Block") > 0 and WoW.CanCast("Ice Block", 0, false) then
		WoW.CastSpell("Ice Block");
		return;
	end;
	
	-- Survival Stuff (Higest Priority)
	if WoW.GetHealth("Player") < 95 and WoW.CanCast("Ice Barrier", 0, false) then
		WoW.CastSpell("Ice Barrier")
		return;
	end;

	-- Rotation Stuff 	
		
	-- 1. Cast Rune of Power if talented, and it is at 2 charges.
	if WoW.CanCast("Rune of Power", 40, true) and WoW.SpellCharges("Rune of Power") == 2 then
		WoW.CastSpell("Rune of Power");			
		return;
	end	
	-- Rune of Power advanced
	-- Use RoP If icy veins is 40+ secs away, Frost Orb is soon, We Have FoF procs
	if WoW.CanCast("Rune of Power", 40, true) and 
	   WoW.SpellCharges("Rune of Power") >= 1 and 
	   WoW.SpellCooldownRemainingTime("Icy Veins") > 40 and 
	  (WoW.SpellCooldownRemainingTime("Frozen Orb") <= 1 or WoW.SpellCooldownRemainingTime("Frozen Touch") <= 1 ) then
		WoW.Log("Optimal Rune of Power triggered")
		WoW.CastSpell("Rune of Power");			
		return;
	end		
	-- Prolong RoP when Icy Veins Up
	-- If Icy Veins active, or we have capped rune of power Use RoP
	-- Since we are about to trigger RoP cast Orb if up to ready FoF procs
	if UnitBuff("Player", "Icy Veins") and
	   WoW.CanCast("Rune of Power", 40, true) and 
	   WoW.SpellCharges("Rune of Power") >= 1 then
		WoW.Log("Prolong rune of power because Icy Veins is up")
		WoW.CastSpell("Rune of Power");		
	end
	
	if WoW.CanCast("Icy Veins", 40, true) and WoW.PlayerTalentAtTier(3) == 2 and UnitBuff("Player", "Rune of Power") then
		WoW.CastSpell("Icy Veins");	
	end		
	-- 1. Cast Icy Veins if it is off cooldown.	
	if WoW.CanCast("Icy Veins", 40, true) and not WoW.PlayerTalentAtTier(3) == 2 then
		WoW.CastSpell("Icy Veins");	
	end		
	if WoW.CanCast("Mirror Image", 40, true) then
		WoW.CastSpell("Mirror Image");
		return;
	end		
	-- 8. Cast Frostbolt and immediately Flurry if Brain Freeze is active.
		-- Cast Ice Lance immediately after Flurry.
		-- You should dump your Fingers of Frost procs before casting Flurry, as Ice Lance does not need Fingers of Frost to benefit from Winter's Chill.
	if WoW.CanCast("Ice Lance", 40, true) and WoW.LastSpell() == "Flurry" then
		WoW.CastSpell("Ice Lance");
		return;
	end;
	-- 12. Cast Blizzard on cooldown if you are talented into Arctic Gale.
	if WoW.CanCast("Blizzard") and WoW.PlayerTalentAtTier(6) == 3 then
		WoW.CastAtUnit("target", "Blizzard");
		return;
	end
	-- 2. Cast Ice Lance if you are at 3 charges of Fingers of Frost.
	if WoW.CanCast("Ice Lance", 40, true) and WoW.PlayerBuffCount("Fingers of Frost") == 3 then
		--WoW.Log("Cast Ice Lance if you are at 3 charges of Fingers of Frost")
		WoW.CastSpell("Ice Lance");
		return;
	end;		
	-- 3. Cast Frost Bomb if talented, and you will trigger it with a minimum of 2 Fingers of Frost.
	if WoW.CanCast("Frost Bomb", 40, true) and WoW.PlayerBuffCount("Fingers of Frost") >= 2 and not WoW.TargetHasDebuff("Frost Bomb") then
		WoW.CastSpell("Frost Bomb");
		return;
	end
	-- 4. Cast Frozen Orb if it is off cooldown.
	if WoW.CanCast("Frozen Orb", 40, true) then
		WoW.CastSpell("Frozen Orb");
		return;
	end
	-- 5. Cast Freeze from your Water Elemental if it will hit at least 2 adds that can be rooted (bosses are immune to Freeze).
	if WoW.CanCast("Freeze", 40, true) and enemiesInMeleeRangeOfTarget >= 2 then 
		WoW.Log('Pet Should Freeze here.')
		WoW.CastAtUnit("target", "Freeze") 	--  this spell does not activate GCD no return needed		
	end
	-- 6. Cast Frozen Touch if talented, and you currently have 1 or less charges of Fingers of Frost.
	if WoW.CanCast("Frozen Touch", 40, true) and WoW.PlayerBuffCount("Fingers of Frost") <= 1 then
		WoW.CastSpell("Frozen Touch");
		return;
	end;
	-- 7. Cast Ebonbolt if it is off cooldown and you have 1 or less charges of Fingers of Frost.
	if WoW.CanCast("Ebonbolt", 40, true) and WoW.PlayerBuffCount("Fingers of Frost") <= 1 then
		WoW.CastSpell("Ebonbolt");
		return;
	end;
	-- 8. Cast Frostbolt and immediately Flurry if Brain Freeze is active.
		-- Cast Ice Lance immediately after Flurry.
		-- You should dump your Fingers of Frost procs before casting Flurry, as Ice Lance does not need Fingers of Frost to benefit from Winter's Chill.
	if WoW.CanCast("Flurry", 40, true) and WoW.PlayerHasBuff("Brain Freeze") then
		WoW.CastSpell("Flurry");
		return;
	end;
	-- 9. Cast Ice Lance following a Brain Freeze empowered Flurry cast to benefit from Winter's Chill.	
	if (WoW.CanCast("Ice Lance", 40, true) and WoW.PlayerHasBuff("Fingers of Frost")) then 
		WoW.CastSpell("Ice Lance");
		return;
	end;
	-- 10. Cast Water Jet from your Water Elemental if you currently have no charges of Fingers of Frost.		
	if WoW.CanCast("Water Jet", 40, true) then
		WoW.CastSpell("Water Jet");
		return;
	end;
	-- Your goal is to cast Frostbolt twice while Water Jet is being channeled to generate charges of Fingers of Frost (see our Water Jet section for more information).
	if WoW.CanCast("Frostbolt") and UnitChannelInfo("Pet") then
		WoW.Log("Casting Frostbolt because water jet is chanelling")
		WoW.CastSpell("Frostbolt")		
		return;
	end	
	-- AOE stuff here
	if enemiesInMeleeRangeOfTarget >= 4 then
		-- 11. Cast Ice Nova if talented.
		if WoW.CanCast("Ice Nova", 40, true) then
			WoW.CastSpell("Ice Nova");
			return;
		end;
		-- 12. Cast Blizzard if more than 4 targets are present and within the AoE. Cast on cooldown if you are talented into Arctic Gale.
		if WoW.CanCast("Blizzard", 40, true) then
			WoW.CastAtUnit("target", "Blizzard");
			return;
		end;
	end
	-- 11. Cast Ice Lance if you have 1 charge of Fingers of Frost.
	if WoW.CanCast("Ice Lance", 40, true) and WoW.PlayerBuffCount("Fingers of Frost") == 1 then
		WoW.CastSpell("Ice Lance");
		return;
	end;
	-- 12. Cast Glacial Spike if talented and available.
	if WoW.CanCast("Glacial Spike", 40, true) then
		WoW.CastSpell("Glacial Spike");
		return;
	end;
	-- 13. Cast Frostbolt as a filler spell.
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
