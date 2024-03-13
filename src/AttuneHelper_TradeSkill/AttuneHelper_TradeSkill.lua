local CONST_ADDON_NAME = "AttuneHelper_TradeSkill"
AttuneHelper_TradeSkill = AttuneHelper:NewModule(CONST_ADDON_NAME)

local L, db
local FILTER_NONE = 1
local FILTER_ITEMS = 2
local toggle = FILTER_NONE;

local items = {}

function AttuneHelper_TradeSkill:OnInitialize()
	L = LibStub("AceLocale-3.0"):GetLocale(CONST_ADDON_NAME, true)

	items[FILTER_NONE] = L["Show all items"]
	items[FILTER_ITEMS] = L["Hide attuned items"]

	local defaults = {
		profile = {
			tradeskill = {

			}
		}
	}

	db = LibStub("AceDB-3.0"):New("AttuneHelperDB", defaults, "profile")
end

function AttuneHelper_TradeSkill:OnEnable( )
    self:RegisterEvent("TRADE_SKILL_SHOW");
end

function AttuneHelper_TradeSkill:refreshFilters()
	if _G.Skillet then
		_G.Skillet.dataSourceChanged = true
	end

	C_TradeSkillUI.SetOnlyShowSkillUpRecipes(not C_TradeSkillUI.GetOnlyShowSkillUpRecipes())
	C_TradeSkillUI.SetOnlyShowSkillUpRecipes(not C_TradeSkillUI.GetOnlyShowSkillUpRecipes())
end

function AttuneHelper_TradeSkill:OnClick()
	UIDropDownMenu_SetSelectedID(FilterDropDown, self:GetID())
	toggle = self:GetID()
	self:refreshFilters()
end

function AttuneHelper_TradeSkill:DropDown_Initialize(level)
	local info = UIDropDownMenu_CreateInfo()

	for k, v in pairs(items) do
		info = UIDropDownMenu_CreateInfo()
		info.text = v
		info.value = k
		info.func = self.OnClick
		info.checked = toggle == k
		UIDropDownMenu_AddButton(info, level)
	end
end

function AttuneHelper_TradeSkill:OnEvent(event, ...)
	local arg1 = ...;

	if event == "" then
		self:refreshFilters()
	end

	if event == "TRADE_SKILL_SHOW" then
		local tsParent, tsX, tsY, tsWidth, tsBWidth

		if _G.TSMCraftingTradeSkillFrame then
			tsParent = _G.TSMCraftingTradeSkillFrame
			tsX = -60
			tsY = 0
			tsWidth = 116
			tsBWidth = 24
		elseif _G.Skillet then
			tsParent = _G.SkilletFrame
			tsX = -325
			tsY = -30
			tsWidth = 116
			tsBWidth = 24
		else
			if not _G.TradeSkillFrame then
				return
			end
			tsParent = _G.TradeSkillFrame
			tsX = -80
			tsY = -52
			tsWidth = 116
			tsBWidth = 24
		end

		if not FilterDropDown then
			CreateFrame("Frame", "FilterDropDown", tsParent, "UIDropDownMenuTemplate")
		end

		UIDropDownMenu_Initialize(FilterDropDown, self.DropDown_Initialize)
		UIDropDownMenu_SetWidth(FilterDropDown, tsWidth);
		UIDropDownMenu_SetButtonWidth(FilterDropDown, tsBWidth)
		UIDropDownMenu_SetSelectedID(FilterDropDown, toggle)
		UIDropDownMenu_JustifyText(FilterDropDown, "LEFT")

		FilterDropDown:ClearAllPoints()
		FilterDropDown:SetParent(tsParent)
		FilterDropDown:SetPoint("TOPRIGHT", tsParent, "TOPRIGHT", tsX, tsY)

		FilterDropDown:Show()
	end
end

local origGetFilteredRecipeIDs = C_TradeSkillUI.GetFilteredRecipeIDs

function AttuneHelper_TradeSkill.isAttuned(itemLink, itemId)
    if not GetItemAttuneProgress then
        return false
    end

    return (GetItemAttuneProgress(itemId) or 0) == 100
end

function AttuneHelper_TradeSkill.filterRecipeIDs(...)
	local newTable = {}
	local oldTable = origGetFilteredRecipeIDs(...)

	for k, v in pairs(oldTable) do
		local itemLink = C_TradeSkillUI.GetRecipeItemLink(v)
		local itemId = string.match(itemLink, "item:(%d+)")

		if itemId then
			local _, _, _, slotName = GetItemInfoInstant(itemLink)

			if(toggle == FILTER_ITEMS or (slotName ~= "INVTYPE_TRINKET" and not AttuneHelper_TradeSkill.isAttuned(itemLink, itemId))) then
				newTable[#newTable+1] = v
			end
		end
	end

	return newTable
end

function C_TradeSkillUI.GetFilteredRecipeIDs(...)
	if(toggle == FILTER_ITEMS) then
		return AttuneHelper_TradeSkill.filterRecipeIDs(...)
	end

	return origGetFilteredRecipeIDs(...)
end