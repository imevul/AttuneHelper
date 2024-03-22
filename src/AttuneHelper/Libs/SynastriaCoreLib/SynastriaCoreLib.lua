﻿SynastriaCoreLib = {}

function SynastriaCoreLib.CheckItemValid(itemId)
    if type(itemId) ~= "number" then return 0 end
    return CanAttuneItemHelper(itemId)
end

function SynastriaCoreLib.IsItemValid(itemId)
    if type(itemId) ~= "number" then return false end
	return SynastriaCoreLib.CheckItemValid(itemId) > 0
end

--@deprecated
function SynastriaCoreLib.GetAttune(itemId)
    return SynastriaCoreLib.GetAttuneProgress(itemId)
end

function SynastriaCoreLib.GetAttuneProgress(itemId)
    if type(itemId) ~= "number" then return 0 end
	return GetItemAttuneProgress(itemId) or 0
end

function SynastriaCoreLib.IsAttuned(itemId)
    if type(itemId) ~= "number" then return false end
	return SynastriaCoreLib.GetAttuneProgress(itemId) >= 100
end

function SynastriaCoreLib.IsAttunable(itemId)
    if type(itemId) ~= "number" then return false end
	return SynastriaCoreLib.IsItemValid(itemId) and not SynastriaCoreLib.IsAttuned(itemId)
end

function SynastriaCoreLib.HasAttuneProgress(itemId)
    if type(itemId) ~= "number" then return false end
	return SynastriaCoreLib.IsItemValid(itemId) and SynastriaCoreLib.GetAttuneProgress(itemId) > 0 and not SynastriaCoreLib.IsAttuned(itemId)
end

-- @returns (Iterator() -> itemId, progress), nil
function SynastriaCoreLib.InProgressItems()
    local index = nil
    local count = GetCustomGameDataCount(11)

    return function()
        if (index or 0) < count then
            local itemId, progress = 0

            while (progress == 0 or progress == 100) and (index or 0) < count do
                index = (index or 0) + 1
                itemId = GetCustomGameDataIndex(11, index)
                progress = GetCustomGameData(11, itemId) or 0
            end

            if progress > 0 and progress < 100 then
                return itemId, progress
            end
        end
    end, index
end

function SynastriaCoreLib.GetAttunedSuffix(itemId)
    if type(itemId) ~= "number" then return nil end
    local suffixId = GetCustomGameData(15, itemId) or 0
    if suffixId > 0 then suffixId = suffixId - 100 end

    return suffixId, SynastriaCoreLib.GetSuffixName(suffixId)
end

function SynastriaCoreLib.GetSuffixName(itemId, suffixId)
    if type(suffixId) ~= "number" then return nil end
    local suffixName = GetAttuneAffixName(itemId, suffixId)
    if suffixName and string.len(suffixName) > 0 then
        return suffixName
    end

    return nil
end

function SynastriaCoreLib.GetItemStats(itemLink, suffixId)
	local itemId = tonumber(itemLink:match('item:(%d+)'))
	if type(itemId) ~= "number" or itemId <= 0 then return {} end
    if suffixId == nil then
        suffixId = SynastriaCoreLib.GetAttunedSuffix(itemId)
    end

    local uniqueId = itemLink:match('item:%d+:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:([^:]*)')
    local linkLevel = itemLink:match('item:%d+:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:([^:]*)')
    local _, link = GetItemInfo(('item:%d::::::%s:%s:%s'):format(itemId, suffixId, uniqueId, linkLevel))

    local stats = {}
    GetItemStats(link, stats)

    for k, v in pairs(stats) do
        if v and v ~= 0 then
            table.insert(stats, {
                id = k,
                name = tostring(_G[k]),
                value = v
            })
        end
    end

    return stats
end

function SynastriaCoreLib.GetItemInfo(itemLink)
	local itemId = tonumber(itemLink:match('item:(%d+)'))
	if type(itemId) ~= "number" or itemId <= 0 then return nil end

    local progress = SynastriaCoreLib.GetAttuneProgress(itemId)
    local suffixId = SynastriaCoreLib.GetAttunedSuffix(itemId)

    return {
        itemId = itemId,
        attuned = progress >= 100,
        progress = progress,
        suffixId = suffixId,
        suffixName = SynastriaCoreLib.GetSuffixName(itemId, suffixId),
        stats = SynastriaCoreLib.GetItemStats(itemLink, suffixId)
    }
end

function SynastriaCoreLib.IsPerkActive(perkId)
    if type(perkId) ~= "number" then return false end
    return GetPerkActive(perkId)
end

function SynastriaCoreLib.HasPerk(perkId)
    if type(perkId) ~= "number" then return false end
    return GetPerkAcquired(perkId) or 0
end
