local parent = CreateFrame("frame", "Recount", UIParent)
parent:SetSize(10, 10);  -- Width, Height
parent:SetPoint("TOPLEFT", 0, 0)
parent:RegisterEvent("ADDON_LOADED")
parent.t = parent:CreateTexture()
parent.t:SetColorTexture(0, 1, 0, 1)
parent.t:SetAllPoints(parent)

local WoW = LibStub("WoW")

function LoadFile(FilePath,LoadMsg)
	local WowAddon = GetWoWDirectory() .. "\\" .. "Interface" .. "\\" ..  "Addons" .. "\\"
	local AddonName = "Zillion"
	local Root =  WowAddon .. AddonName .. "\\"

	lua = ReadFile(Root .. FilePath)

	if lua == "" then 
		WoW.Log("Class file [" .. FilePath .. "] is not coded yet.")
	end
	
	if not lua then
		WoW.Log(Root .. FilePath .. " Does not exist")
	end
	local func,err = loadstring(lua, Root .. "\\" .. FilePath)
	if err then
		error(err,0)
	end
	pcall(func)
	if LoadMsg then
		WoW.Log(LoadMsg)
	else
		WoW.Log('Successfully loaded ['.. FilePath .. ']')
	end
end

function start()
	if not IsHackEnabled then 
		WoW.Log('Please load Zillions requirements first...', "|cfff00000");
		return; 
	end;
			
	WoW.Log('Zillion Loaded.')
	
	local PlayerClass, englishClass, classIndex = UnitClass("Player");
	WoW.Log('Player Class ' .. englishClass)
	if (englishClass == "MAGE") then
		LoadFile("Classes\\Mage\\Frost.lua")
	end	
	if (englishClass == "PRIEST") then
		LoadFile("Classes\\Priest\\Disc.lua")
	end	
end

local function eventHandler(self, event, ...)
	local arg1 = ...
	if event == "ADDON_LOADED" then
		if (arg1 == "Zillion") then
			start()            
		end
	end
end	
parent:SetScript("OnEvent", eventHandler)
parent:SetScript("OnUpdate", update)