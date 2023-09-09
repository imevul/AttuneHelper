SynastriaCoreLib = {}

-- Credit: Synastria - meh321
function SynastriaCoreLib.IsArmorTypeValid(itemType, itemSubType, itemLevel)
    if not itemType or itemType ~= "Armor" or not itemSubType then return true end
    local ctype = 0
    if itemSubType == "Cloth" then ctype = 1 end
    if itemSubType == "Leather" then ctype = 2 end
    if itemSubType == "Mail" then ctype = 3 end
    if itemSubType == "Plate" then ctype = 4 end
    if ctype == 0 then return true end
    local mtype = 0
    local mtype2 = 0
    local _, mclass = UnitClass("player")
    if mclass == "WARRIOR" or mclass == "PALADIN" or mclass == "DEATHKNIGHT" then
        mtype = 4
        if itemLevel < 45 then mtype2 = 3 end
    elseif mclass == "DRUID" or mclass == "ROGUE" then
        mtype = 2
    elseif mclass == "HUNTER" or mclass == "SHAMAN" then
        if itemLevel < 45 then mtype = 2 else mtype = 3 end
    else -- warlock, mage, priest
        mtype = 1
    end
    if mtype ~= ctype and (mtype2 == 0 or mtype2 ~= ctype) then
        return false
    end
    return true
end

-- Credit: Synastria - meh321
function SynastriaCoreLib.CheckItemValid(itemId)
    if not itemId or type(itemId) ~= "number" or itemId <= 0 or ItemAttuneSkip == nil then return 0 end
    local _, _, _, itemLevel, itemMinLevel, itemType, itemSubType, _, itemEquipLoc = GetItemInfo("item:" .. itemId)
    if not itemEquipLoc or string.len(itemEquipLoc) == 0 then return 0 end
    if itemEquipLoc == "INVTYPE_NON_EQUIP" then return 0 end
    if itemEquipLoc == "INVTYPE_BODY" then return 0 end
    if itemEquipLoc == "INVTYPE_BAG" then return 0 end
    if itemEquipLoc == "INVTYPE_TABARD" then return 0 end
    if itemEquipLoc == "INVTYPE_AMMO" then return 0 end
    if itemEquipLoc == "INVTYPE_QUIVER" then return 0 end

    -- show N/A
    if ItemAttuneSkip[itemId] then return -5 end
    if itemEquipLoc ~= "INVTYPE_CLOAK" and not SynastriaCoreLib.IsArmorTypeValid(itemType, itemSubType, itemLevel) then return -2 end
    if itemEquipLoc == "INVTYPE_2HWEAPON" then return -4 end
    if itemEquipLoc == "INVTYPE_WEAPON" then return -4 end
    if itemEquipLoc == "INVTYPE_WEAPONMAINHAND" then return -4 end
    if itemEquipLoc == "INVTYPE_WEAPONOFFHAND" then return -4 end
    if itemEquipLoc == "INVTYPE_SHIELD" then
        local _, mclass = UnitClass("player")
        if mclass ~= "WARRIOR" and mclass ~= "PALADIN" and mclass ~= "SHAMAN" then return -6 end
    end
    if itemType == "Weapon" then
        if itemSubType == "Thrown" then
            local _, mclass = UnitClass("player")
            if mclass ~= "WARRIOR" and mclass ~= "ROGUE" then return -6 end
        elseif itemSubType == "Guns" or itemSubType == "Bows" or itemSubType == "Crossbows" then
            local _, mclass = UnitClass("player")
            if mclass ~= "WARRIOR" and mclass ~= "ROGUE" and mclass ~= "HUNTER" then return -6 end
        elseif itemSubType == "Wands" then
            local _, mclass = UnitClass("player")
            if mclass ~= "MAGE" and mclass ~= "PRIEST" and mclass ~= "WARLOCK" then return -6 end
        end
    end
    if itemEquipLoc == "INVTYPE_RELIC" then
        if itemSubType == "Librams" then
            local _, mclass = UnitClass("player")
            if mclass ~= "PALADIN" then return -6 end
        elseif itemSubType == "Idols" then
            local _, mclass = UnitClass("player")
            if mclass ~= "DRUID" then return -6 end
        elseif itemSubType == "Totems" then
            local _, mclass = UnitClass("player")
            if mclass ~= "SHAMAN" then return -6 end
        elseif itemSubType == "Sigils" then
            local _, mclass = UnitClass("player")
            if mclass ~= "DEATHKNIGHT" then return -6 end
        end
    end
    if ItemAttuneStatless[itemId] then return -3 end

    -- show valid
    return 1
end

function SynastriaCoreLib.IsItemValid(itemId)
    if type(itemId) ~= "number" then return false end
	return SynastriaCoreLib.CheckItemValid(itemId) > 0
end

function SynastriaCoreLib.GetAttune(itemId)
	if ItemAttuneHas == nil or type(itemId) ~= "number" then return 0 end

	return ItemAttuneHas[itemId] or 0
end

function SynastriaCoreLib.IsAttuned(itemId)
    if type(itemId) ~= "number" then return false end
	return SynastriaCoreLib.GetAttune(itemId) >= 100
end

function SynastriaCoreLib.IsAttunable(itemId)
    if type(itemId) ~= "number" then return false end
	return SynastriaCoreLib.IsItemValid(itemId) and not SynastriaCoreLib.IsAttuned(itemId)
end

function SynastriaCoreLib.HasAttuneProgress(itemId)
    if type(itemId) ~= "number" then return false end
	return SynastriaCoreLib.IsItemValud(itemId) and SynastriaCoreLib.GetAttune(itemId) > 0 and not SynastriaCoreLib.IsAttuned(itemId)
end
