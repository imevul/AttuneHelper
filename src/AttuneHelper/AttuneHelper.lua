local CONST_ADDON_NAME = "AttuneHelper"
AttuneHelper = LibStub("AceAddon-3.0"):NewAddon(CONST_ADDON_NAME, "AceConsole-3.0", "AceHook-3.0")

local SynastriaCoreLib = LibStub('SynastriaCoreLib-1.0')
local L, db
local ttList = {
	["GameTooltip"] = {
		["OnTooltipSetItem"] = true,
	},
	["ItemRefTooltip"] = {
		["OnTooltipSetItem"] = true,
	},
	["AtlasLootTooltip"] = {
		["OnTooltipSetItem"] = true,
	},
}
local ttHooks = {}
local ttLine = {}

function AttuneHelper:OnInitialize()
	L = LibStub("AceLocale-3.0"):GetLocale(CONST_ADDON_NAME, true)

	local defaults = {
		profile = {
			showTooltip = true,
			showAttuned = true,
			showAttunedType = false,
			showItemId = false,
			showStats = true,
			colorBlindMode = false
		}
	}

	db = LibStub("AceDB-3.0"):New(CONST_ADDON_NAME .. "DB", defaults, "profile")

	local opts = {
		name = CONST_ADDON_NAME,
		handler = AttuneHelper,
		type = 'group',
		inline = true,
		args = {
			showTooltip = {
				type = "toggle",
				name = L["Enable Attunement Tooltips"],
				get = function()
					return db.profile.showTooltip
				end,
				set = function()
					db.profile.showTooltip = not db.profile.showTooltip
					if db.profile.showTooltip then
						AttuneHelper:HookTooltips()
					else
						AttuneHelper:UnhookTooltips()
					end
				end,
				order = 1
			},
			
			showItemId = {
				type = "toggle",
				name = L["Show item ID"],
				get = function()
					return db.profile.showItemId
				end,
				set = function()
					db.profile.showItemId = not db.profile.showItemId
				end,
				order = 2
			},

			showAttuned = {
				type = "toggle",
				name = L["Show attuned"],
				get = function()
					return db.profile.showAttuned
				end,
				set = function()
					db.profile.showAttuned = not db.profile.showAttuned
				end,
				order = 3
			},

--[[ 			showAttunedType = {
				type = "toggle",
				name = L["Show attuned type"],
				get = function()
					return db.profile.showAttunedType
				end,
				set = function()
					db.profile.showAttunedType = not db.profile.showAttunedType
				end,
				order = 4
			},

			showStats = {
				type = "toggle",
				name = L["Show stats"],
				get = function()
					return db.profile.showStats
				end,
				set = function()
					db.profile.showStats = not db.profile.showStats
				end,
				order = 5
			}, ]]

			colorBlindMode = {
				type = "toggle",
				name = L["Colorblind mode"],
				get = function()
					return db.profile.colorBlindMode
				end,
				set = function()
					db.profile.colorBlindMode = not db.profile.colorBlindMode
				end,
				order = 5
			},
		}
	}

	LibStub("AceConfig-3.0"):RegisterOptionsTable(CONST_ADDON_NAME, opts, { "attunementhelper", "ah" })
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(CONST_ADDON_NAME, CONST_ADDON_NAME)

	if LinkWrangler then
		LinkWrangler.RegisterCallback(CONST_ADDON_NAME, function(f)
			ttList[f:GetName()] = {
				["OnTooltipSetItem"] = true,
			}
			self:HookTip(f, "OnTooltipSetItem")
		end, "allocate", "allocatecomp")
	end
end

function AttuneHelper:OnEnable()
	if db.profile.showTooltip then
		self:HookTooltips()
	end
end

function AttuneHelper:HookTooltips()
	for tooltip, scripts in pairs(ttList) do
		if _G[tooltip] then
			for script, _ in pairs(scripts) do
				self:HookTip(_G[tooltip], script)
			end
		end
	end
end

function AttuneHelper:HookTip(tooltip, script)
	local ttName = tooltip:GetName()
	ttLine[ttName] = ttLine[ttName] or {}

	self:HookScript(tooltip, script)

	ttHooks[ttName] = ttHooks[ttName] or {}
	ttHooks[ttName][script] = true
end

function AttuneHelper:UnhookTooltips()
	for tooltip, scripts in pairs(ttHooks) do
		for script, _ in pairs(scripts) do
			self:UnhookTip(tooltip, script)
		end
	end
end

function AttuneHelper:UnhookTip(tooltip, script)
	self:Unhook(_G[tooltip], script)
	ttHooks[tooltip][script] = nil

	if not next(ttHooks[tooltip]) then
		ttHooks[tooltip] = nil
		ttLine[tooltip] = nil
	end
end

function AttuneHelper:GetAttunementInfo(itemLink)
	local output = {}
	local itemInfo = SynastriaCoreLib.GetItemInfo(itemLink, true)

	if itemInfo then
		if db.profile.showAttuned then
			if itemInfo.attuned then
				if db.profile.colorBlindMode then
					output[#output+1] = "Attuned: |c00648fffYes|r"
				else
					output[#output+1] = "Attuned: |c0000ff00Yes|r"
				end
			else
				if db.profile.colorBlindMode then
					output[#output+1] = "Attuned: |c00fe6100No|r"
				else
					output[#output+1] = "Attuned: |c00ff0000No|r"
				end
			end
		end
	end

	return output
end

function AttuneHelper:OnTooltipSetItem(tooltip, ...)
	local itemLink = select(2, tooltip:GetItem())
	if not itemLink then return end
	local itemId = tonumber(itemLink:match('item:(%d+)'))

	if itemLink and db.profile.showTooltip then
		local attunementInfo = self:GetAttunementInfo(itemLink)

		if #attunementInfo > 0 or db.profile.showItemId then
			if db.profile.showItemId then
				tooltip:AddLine("|cffff00aaAttuneHelper: " .. tostring(itemId) .. "|r")
			else
				tooltip:AddLine("|cffff00aaAttuneHelper:|r")
			end
		end

		if #attunementInfo > 0 then
			for _, v in pairs(attunementInfo) do
				tooltip:AddLine(v)
			end
		end
	end
end
