local CONST_ADDON_NAME = "AttuneHelper"
local AttuneHelper = LibStub("AceAddon-3.0"):NewAddon(CONST_ADDON_NAME, "AceConsole-3.0", "AceHook-3.0")

local cache = {}
local lastId = nil
local queriedItemId = nil
local suppressCounter = 0
local lastCheck = nil
local checkTimeout = 1

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

function AttuneHelper.printTable(tbl)
	if not tbl then
		return
	end

	if type(tbl) == 'table' then
		for k, v in pairs(tbl) do
			print(tostring(k) .. ": " .. tostring(v))
		end
	else
		print(tostring(tbl))
	end
end

function AttuneHelper:OnInitialize()
	L = LibStub("AceLocale-3.0"):GetLocale(CONST_ADDON_NAME, true)

	local defaults = {
		profile = {
			showTooltip = true,
			cacheDuration = 1,
			showItemId = false,
			showStats = true
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

			cacheDuration = {
				type = "range",
				name = L["Cache duration (minutes)"],
				min = 1,
				max = 60,
				step = 1,
				get = function() return db.profile.cacheDuration end,
				set = function(_, val)
					db.profile.cacheDuration = val
				end,
				order = 2
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
				order = 3
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
				order = 4
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

function AttuneHelper.CHAT_MSG_SYSTEM(_, _, message)
	local matched = false
	local id = tonumber(message:match('Item: [^%(]+ %((%d+)%)'))

	-- First message
	if id then
		lastId = id

		if not cache[id] then
			cache[id] = {}
		end

		cache[id].attuned = false
		cache[id].type = nil
		cache[id].suffixId = nil
		cache[id].timestamp = time()
		cache[id].queried = true
		matched = true
	else
		-- Second message
		local attuned = message:match('Attuned: (%w+)')
		if lastId and attuned == 'yes' then
			cache[lastId].attuned = true
			matched = true
		elseif lastId and attuned == 'no' then
			matched = true
		else
			-- Third message (optional)
			local type, suffixId = message:match('Random: ([^%(]+) %((-?%d+)%)')
			if lastId and type then
				cache[lastId].type = type
				cache[lastId].suffixId = tonumber(suffixId)
				matched = true
			end
		end

		if queriedItemId and lastId and queriedItemId == lastId then
			queriedItemId = nil
		end
	end

	if matched and suppressCounter > 0 then
		suppressCounter = suppressCounter - 1
		return true
	end
end

function AttuneHelper:CheckAttune(itemId)
	if type(itemId) ~= "number" then
		return
	end

	if not cache[itemId] then
		cache[itemId] = {}
		cache[itemId].timestamp = 0
	end

	local currentTime = time()

	if not ItemAttuneHas[itemId] or ItemAttuneHas[itemId] < 100 then
		cache[itemId].attuned = false
		cache[itemId].timestamp = currentTime
		return
	end

	if cache[itemId].queried and not cache[itemId].type then
		return
	end

	if cache[itemId].timestamp < currentTime - db.profile.cacheDuration * 60 then
		if lastCheck and lastCheck > currentTime - checkTimeout then
			return
		end

		lastCheck = currentTime
		cache[itemId].timestamp = currentTime
		queriedItemId = itemId
		suppressCounter = 3
		SendChatMessage(".checkattune " .. itemId)
	end
end

function AttuneHelper:OnEnable()
	if db.profile.showTooltip then
		self:HookTooltips()
	end
end

function AttuneHelper:HookTooltips()
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", AttuneHelper.CHAT_MSG_SYSTEM)

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
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", AttuneHelper.CHAT_MSG_SYSTEM)

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
	local itemId = tonumber(itemLink:match('item:(%d+)'))
	if type(itemId) ~= "number" or itemId <= 0 then
		return {}
	end

	local output = {}

	self:CheckAttune(itemId)

	if cache[itemId] then
		if cache[itemId].type then
			output[#output+1] = "Type: " .. cache[itemId].type .. " (" .. tostring(cache[itemId].suffixId) .. ")"

			if db.profile.showStats then
				local uniqueId = itemLink:match('item:%d+:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:([^:]*)')
				local linkLevel = itemLink:match('item:%d+:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:([^:]*)')
				local _, link = GetItemInfo('item:' .. tostring(itemId) .. '::::::' .. tostring(cache[itemId].suffixId) .. ':' .. tostring(uniqueId) .. ':' .. tostring(linkLevel))

				local stats = {}
				GetItemStats(link, stats)

				for k, v in pairs(stats) do
					if v and v ~= 0 then
						local sign = '+'
						if v < 0 then
							sign = '-'
						end

						output[#output+1] = '  |cffbbbbbb' .. sign .. tostring(v) .. ' ' .. tostring(_G[k]) .. '|r'
					end
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
