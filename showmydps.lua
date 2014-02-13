local ShowMyDPS = LibStub("AceAddon-3.0"):NewAddon("ShowMyDPS", "AceConsole-3.0", "AceEvent-3.0")

DBDefault = {
	char = {
		isLock = false,
		isShown = true,
		oocHide = false,
	}
}

function ShowMyDPS:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("SMDdb", DBDefault)
end

function ShowMyDPS:OnEnable()
	self:CreateFrame()
	self:RegisterEvent("PLAYER_REGEN_ENABLED","LeaveCombat")
	self:RegisterEvent("PLAYER_REGEN_DISABLED","EnterCombat")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED","AddAmount")
end

function ShowMyDPS:CreateFrame()
	smdFrame = CreateFrame("Frame", "ShowMyDPSFrame", UIParent, "GameTooltipTemplate")
	smdFrame:SetPoint("CENTER", UIParent, self.db.char.x and "BOTTOMLEFT" or "CENTER", self.db.char.x or 0, self.db.char.y or 0)
	smdFrame:EnableMouse(true)
	smdFrame:SetToplevel(true)
	smdFrame:SetMovable(true)
	smdFrame:SetFrameStrata("LOW")
	smdFrame:SetWidth(80)
	smdFrame:SetHeight(25)
	if self.db.char.isShown and not self.db.char.oocHide then
		smdFrame:Show()
	end

	local backdrop_header = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile=1, tileSize=16, edgeSize = 16,
			insets = {left = 5, right = 5, top = 5, bottom = 5}}

	smdFrame:SetBackdrop(backdrop_header);
	smdFrame:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b)
	smdFrame:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b)

	smdFrame.text = smdFrame:CreateFontString("$parentText", "ARTWORK", "GameFontNormalSmall")
	smdFrame.text:SetPoint("CENTER", smdFrame, "CENTER", 0, 0)
	smdFrame.text:Show()

	smdFrame:SetScript("OnMouseDown", function(frame, button) 
		if not self.db.char.isLock and button ~= "RightButton" then
			frame.isMoving = true
			frame:StartMoving()	
		end
	end)

	smdFrame:SetScript("OnMouseUp", function(frame, button) 
		if not self.db.char.isLock and button ~= "RightButton" then
			if( frame.isMoving ) then
				frame.isMoving = nil
				frame:StopMovingOrSizing()
				self.db.char.x, self.db.char.y = frame:GetCenter()
			end
		else
			self:RefreshFrame()
		end
	end)
	self:RefreshFrame()
	ShowMyDPS.Frame = smdFrame
end

local cbtDuration, cbtStart = nil, nil
local cbtDPS, cbtDmgAmount, cbtDmgShown = nil, nil, nil

function ShowMyDPS:EnterCombat()
	if self.db.char.isShown and self.db.char.oocHide then smdFrame:Show() end
	if cbtStart and cbtStart > 3.6 then
		cbtDmgAmount = 0
		cbtStart = GetTime() - 3.5
	else
		self:RefreshFrame()
	end
end

function ShowMyDPS:AddAmount(event, ...)
	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15 = ...
	if (type(arg3) == "boolean") then arg1, arg2, arg3, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15 = ... end
	if bit.band(arg5, 0x1111) == 0x1111 or bit.band(arg5, 0x511) == 0x511 then -- Checking source
		if arg2 and string.find(arg2, "_DAMAGE") then
			-- Get recount-like feature
			if InCombatLockdown() then
				cbtDmgAmount = cbtDmgAmount or 0
				cbtStart = cbtStart or GetTime() - 3.5
			else
				cbtDmgAmount = 0
				cbtStart = GetTime() - 3.5
			end
			
			if not arg14 then -- Checking dps type
				cbtDmgAmount = cbtDmgAmount + arg11 -- Melee swing
			else
				cbtDmgAmount = cbtDmgAmount + arg14 -- Anything else
			end
			
			-- Calc
			self:CalculateDmg()
			
			-- Show
			if InCombatLockdown() then
				self:RefreshFrame()
			end
		end
	end
end

function ShowMyDPS:CalculateDmg()
	-- Calculation
	cbtDuration = GetTime() - cbtStart
	if cbtDmgAmount then cbtDPS = (floor((cbtDmgAmount/cbtDuration * 100) + 0.5))/100 end
	if cbtDmgAmount > 1000000 then cbtDmgShown = floor(cbtDmgAmount/1000).."k" else cbtDmgShown = cbtDmgAmount end
end


function ShowMyDPS:RefreshFrame()
		if cbtDmgAmount and cbtDmgAmount > 0 then
			ShowMyDPSFrameText:SetText(format("%0.1fk dps", cbtDPS/1000.0))
		else
			ShowMyDPSFrameText:SetText("DPS")
		end
end

function ShowMyDPS:LeaveCombat()
	self:RefreshFrame()
	if self.db.char.oocHide then smdFrame:Hide() end
	cbtDmgAmount = nil
	cbtStart = nil
end