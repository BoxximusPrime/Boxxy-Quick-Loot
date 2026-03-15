---@diagnostic disable: undefined-global

require "ISUI/ISButton"
require "ISUI/ISComboBox"
require "ISUI/ISInventoryPage"
require "ISUI/ISInventoryPane"
require "ISUI/ISPanel"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"
require "ISUI/ISToolTip"

BoxxyQuickLoot = BoxxyQuickLoot or {}
BoxxyQuickLoot.modDataKey = "BoxxyQuickLoots"
BoxxyQuickLoot.windowTitle = "Quick Loots"
BoxxyQuickLoot.windows = BoxxyQuickLoot.windows or {}

if not BoxxyQuickLoot.options and PZAPI and PZAPI.ModOptions then
    BoxxyQuickLoot.options = PZAPI.ModOptions:create("BoxxyQuickLoot", "Boxxy Quick Loot")
    BoxxyQuickLoot.autoLootKeyOption = BoxxyQuickLoot.options:addKeyBind(
        "BoxxyQuickLoot_triggerAutoLoot",
        "Quick Loots",
        Keyboard.KEY_NONE,
        "Trigger Quick Loot on the active loot window."
    )
end

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local CLOSE_ICON_SIZE = 24
local HELP_ICON_SIZE = 20
local CLOSE_ICON = getTexture("X.png") or getTexture("42.13/X.png")
local CLOSE_ICON_HOVER = getTexture("X_Hover.png") or getTexture("42.13/X_Hover.png") or CLOSE_ICON
local HELP_ICON = getTexture("help.png") or getTexture("42.13/help.png")
local SORT_DIRECTION_ICON = getTexture("up.png")
local SORT_PRIORITY_ICON = getTexture("sortarrow.png") or getTexture("42.13/sortarrow.png")

BoxxyQuickLootWindow = ISPanel:derive("BoxxyQuickLootWindow")
BoxxyQuickLootWindow.colorButtonWidth = 34
BoxxyQuickLootWindow.removeButtonWidth = 28
BoxxyQuickLootWindow.toggleButtonWidth = 72
BoxxyQuickLootWindow.addTermButtonWidth = 110
BoxxyQuickLootWindow.sortModeButtonWidth = 134
BoxxyQuickLootWindow.sortDirectionButtonWidth = 40
BoxxyQuickLootWindow.disabledLastCheckboxWidth = 201
BoxxyQuickLootWindow.colorSettingsButtonWidth = 92
BoxxyQuickLootWindow.actionButtonGap = 8
BoxxyQuickLootWindow.actionRightPadding = 28
BoxxyQuickLootWindow.helpButtonSize = 18
BoxxyQuickLootWindow.frameBackground = { r = 0.04, g = 0.04, b = 0.05, a = 0.96 }
BoxxyQuickLootWindow.frameBorder = { r = 0.32, g = 0.28, b = 0.16, a = 1.0 }
BoxxyQuickLootWindow.titleBarBackground = { r = 0.11, g = 0.11, b = 0.13, a = 0.95 }
BoxxyQuickLootWindow.titleBarBorder = { r = 0.36, g = 0.32, b = 0.2, a = 0.45 }
BoxxyQuickLootWindow.titleText = { r = 0.99, g = 0.96, b = 0.88, a = 1.0 }
BoxxyQuickLootWindow.sectionText = { r = 0.92, g = 0.86, b = 0.68, a = 1.0 }
BoxxyQuickLootWindow.surfaceBackground = { r = 0.03, g = 0.04, b = 0.04, a = 0.96 }
BoxxyQuickLootWindow.surfaceBorder = { r = 0.2, g = 0.32, b = 0.3, a = 0.9 }
BoxxyQuickLootWindow.scrollbarBackground = { r = 0.08, g = 0.09, b = 0.09, a = 0.9 }
BoxxyQuickLootWindow.scrollbarBorder = { r = 0.2, g = 0.24, b = 0.22, a = 0.7 }
BoxxyQuickLoot.highlightColorIdDefault = "green"
BoxxyQuickLoot.highlightColors = {
    {
        id = "green",
        label = "Green",
        preview = { r = 0.26, g = 0.82, b = 0.32, a = 1.0 },
        fill = { r = 0.18, g = 0.75, b = 0.18, a = 0.08 },
        marker = { r = 0.18, g = 0.9, b = 0.18, a = 0.65 },
        border = { r = 0.18, g = 0.9, b = 0.18, a = 0.25 },
    },
    {
        id = "gold",
        label = "Gold",
        preview = { r = 0.9, g = 0.72, b = 0.2, a = 1.0 },
        fill = { r = 0.82, g = 0.62, b = 0.16, a = 0.1 },
        marker = { r = 0.96, g = 0.78, b = 0.22, a = 0.72 },
        border = { r = 0.96, g = 0.78, b = 0.22, a = 0.28 },
    },
    {
        id = "blue",
        label = "Blue",
        preview = { r = 0.24, g = 0.6, b = 0.94, a = 1.0 },
        fill = { r = 0.2, g = 0.48, b = 0.82, a = 0.1 },
        marker = { r = 0.26, g = 0.7, b = 0.98, a = 0.72 },
        border = { r = 0.26, g = 0.7, b = 0.98, a = 0.28 },
    },
    {
        id = "red",
        label = "Red",
        preview = { r = 0.96, g = 0.14, b = 0.14, a = 1.0 },
        fill = { r = 0.88, g = 0.1, b = 0.1, a = 0.1 },
        marker = { r = 1.0, g = 0.16, b = 0.16, a = 0.72 },
        border = { r = 1.0, g = 0.16, b = 0.16, a = 0.28 },
    },
    {
        id = "violet",
        label = "Violet",
        preview = { r = 0.62, g = 0.48, b = 0.96, a = 1.0 },
        fill = { r = 0.48, g = 0.32, b = 0.88, a = 0.1 },
        marker = { r = 0.7, g = 0.54, b = 1.0, a = 0.72 },
        border = { r = 0.7, g = 0.54, b = 1.0, a = 0.28 },
    },
}

function BoxxyQuickLoot.getHighlightColorDefinition(colorId)
    local fallbackColor = BoxxyQuickLoot.highlightColors[1]
    for _, colorDef in ipairs(BoxxyQuickLoot.highlightColors) do
        if colorDef.id == colorId then
            return colorDef
        end
    end

    return fallbackColor
end

function BoxxyQuickLoot.isHighlightColorId(colorId)
    for _, colorDef in ipairs(BoxxyQuickLoot.highlightColors) do
        if colorDef.id == colorId then
            return true
        end
    end

    return false
end

function BoxxyQuickLoot.getDefaultColorPriorityIds()
    return {
        "red",
        "gold",
        "violet",
        "blue",
        "green",
    }
end

function BoxxyQuickLoot.normalizeColorPriorityIds(colorPriorityIds)
    local normalizedIds = {}
    local seenIds = {}

    if type(colorPriorityIds) == "table" then
        for _, colorId in ipairs(colorPriorityIds) do
            if BoxxyQuickLoot.isHighlightColorId(colorId) and not seenIds[colorId] then
                table.insert(normalizedIds, colorId)
                seenIds[colorId] = true
            end
        end
    end

    for _, colorDef in ipairs(BoxxyQuickLoot.highlightColors) do
        if not seenIds[colorDef.id] then
            table.insert(normalizedIds, colorDef.id)
        end
    end

    return normalizedIds
end

function BoxxyQuickLoot.getSavedColorPriorityIds(playerObj)
    local settings = BoxxyQuickLoot.getSettingsStore(playerObj)
    if not settings then
        return BoxxyQuickLoot.getDefaultColorPriorityIds()
    end

    return BoxxyQuickLoot.normalizeColorPriorityIds(settings.colorPriorityIds)
end

function BoxxyQuickLoot.saveColorPriorityIds(playerObj, colorPriorityIds)
    local settings = BoxxyQuickLoot.getSettingsStore(playerObj)
    if not settings then
        return
    end

    settings.colorPriorityIds = BoxxyQuickLoot.normalizeColorPriorityIds(colorPriorityIds)
    BoxxyQuickLoot.saveList(playerObj)
end

function BoxxyQuickLoot.getDefaultAutoLootColorStates()
    local autoLootColorStates = {}

    for _, colorDef in ipairs(BoxxyQuickLoot.highlightColors) do
        autoLootColorStates[colorDef.id] = true
    end

    return autoLootColorStates
end

function BoxxyQuickLoot.normalizeAutoLootColorStates(autoLootColorStates)
    local normalizedStates = BoxxyQuickLoot.getDefaultAutoLootColorStates()

    if type(autoLootColorStates) == "table" then
        for colorId, isEnabled in pairs(autoLootColorStates) do
            if BoxxyQuickLoot.isHighlightColorId(colorId) then
                normalizedStates[colorId] = isEnabled ~= false
            end
        end
    end

    return normalizedStates
end

function BoxxyQuickLoot.getSavedAutoLootColorStates(playerObj)
    local settings = BoxxyQuickLoot.getSettingsStore(playerObj)
    if not settings then
        return BoxxyQuickLoot.getDefaultAutoLootColorStates()
    end

    return BoxxyQuickLoot.normalizeAutoLootColorStates(settings.autoLootColorStates)
end

function BoxxyQuickLoot.saveAutoLootColorStates(playerObj, autoLootColorStates)
    local settings = BoxxyQuickLoot.getSettingsStore(playerObj)
    if not settings then
        return
    end

    settings.autoLootColorStates = BoxxyQuickLoot.normalizeAutoLootColorStates(autoLootColorStates)
    BoxxyQuickLoot.saveList(playerObj)
end

function BoxxyQuickLoot.isAutoLootEnabledForColor(playerObj, colorId)
    local autoLootColorStates = BoxxyQuickLoot.getSavedAutoLootColorStates(playerObj)
    return autoLootColorStates[colorId] ~= false
end

function BoxxyQuickLoot.getOrderedHighlightColors(playerObj)
    local orderedColors = {}

    for _, colorId in ipairs(BoxxyQuickLoot.getSavedColorPriorityIds(playerObj)) do
        table.insert(orderedColors, BoxxyQuickLoot.getHighlightColorDefinition(colorId))
    end

    return orderedColors
end

function BoxxyQuickLoot.getColorPriorityRank(playerObj, colorId)
    local orderedIds = BoxxyQuickLoot.getSavedColorPriorityIds(playerObj)

    for index, orderedId in ipairs(orderedIds) do
        if orderedId == colorId then
            return index
        end
    end

    return #orderedIds + 1
end

function BoxxyQuickLoot.copyColor(target, source)
    if not target or not source then
        return
    end

    target.r = source.r
    target.g = source.g
    target.b = source.b
    target.a = source.a
end

function BoxxyQuickLoot.applyButtonPalette(button, background, hover, border, text)
    if not button then
        return
    end

    button.backgroundColor = button.backgroundColor or {}
    button.backgroundColorMouseOver = button.backgroundColorMouseOver or {}
    button.borderColor = button.borderColor or {}
    BoxxyQuickLoot.copyColor(button.backgroundColor, background)
    BoxxyQuickLoot.copyColor(button.backgroundColorMouseOver, hover)
    BoxxyQuickLoot.copyColor(button.borderColor, border)
    if text then
        button.textColor = button.textColor or {}
        BoxxyQuickLoot.copyColor(button.textColor, text)
    end
end

function BoxxyQuickLoot.getMatchSyntaxTooltip()
    return "Match syntax:\n" ..
        "Plain text: chips\n" ..
        "+ means AND: baseball + bat\n" ..
        "| means OR: baseball | bat\n" ..
        "- excludes text: baseball -bat\n" ..
        "Operators can be combined in one rule."
end

function BoxxyQuickLoot.getPlayerObject(playerRef)
    if type(playerRef) == "number" then
        return getSpecificPlayer(playerRef)
    end
    return playerRef
end

function BoxxyQuickLoot.getPlayerNumber(playerRef)
    if type(playerRef) == "number" then
        return playerRef
    end
    if playerRef and playerRef.getPlayerNum then
        return playerRef:getPlayerNum()
    end
    return 0
end

function BoxxyQuickLoot.getListStore(playerObj)
    if not playerObj then
        return nil
    end

    local modData = playerObj:getModData()
    modData[BoxxyQuickLoot.modDataKey] = modData[BoxxyQuickLoot.modDataKey] or {}
    modData[BoxxyQuickLoot.modDataKey].items = modData[BoxxyQuickLoot.modDataKey].items or {}
    return modData[BoxxyQuickLoot.modDataKey].items
end

function BoxxyQuickLoot.getTermStore(playerObj)
    if not playerObj then
        return nil
    end

    local modData = playerObj:getModData()
    modData[BoxxyQuickLoot.modDataKey] = modData[BoxxyQuickLoot.modDataKey] or {}
    modData[BoxxyQuickLoot.modDataKey].terms = modData[BoxxyQuickLoot.modDataKey].terms or {}
    return modData[BoxxyQuickLoot.modDataKey].terms
end

function BoxxyQuickLoot.getSettingsStore(playerObj)
    if not playerObj then
        return nil
    end

    local modData = playerObj:getModData()
    modData[BoxxyQuickLoot.modDataKey] = modData[BoxxyQuickLoot.modDataKey] or {}
    modData[BoxxyQuickLoot.modDataKey].settings = modData[BoxxyQuickLoot.modDataKey].settings or {}
    return modData[BoxxyQuickLoot.modDataKey].settings
end

function BoxxyQuickLoot.getSavedWindowSettings(playerObj)
    local settings = BoxxyQuickLoot.getSettingsStore(playerObj)
    if not settings then
        return "alphabetical", "asc", false
    end

    local sortMode = "alphabetical"
    if settings.sortMode == "type" then
        sortMode = "type"
    elseif settings.sortMode == "priority" then
        sortMode = "priority"
    end
    local sortDirection = settings.sortDirection == "desc" and "desc" or "asc"
    local disabledItemsLast = settings.disabledItemsLast == true
    return sortMode, sortDirection, disabledItemsLast
end

function BoxxyQuickLoot.saveWindowSettings(playerObj, sortMode, sortDirection, disabledItemsLast)
    local settings = BoxxyQuickLoot.getSettingsStore(playerObj)
    if not settings then
        return
    end

    if sortMode == "type" then
        settings.sortMode = "type"
    elseif sortMode == "priority" then
        settings.sortMode = "priority"
    else
        settings.sortMode = "alphabetical"
    end
    settings.sortDirection = sortDirection == "desc" and "desc" or "asc"
    settings.disabledItemsLast = disabledItemsLast == true
    BoxxyQuickLoot.saveList(playerObj)
end

function BoxxyQuickLoot.refreshLootPane(playerObj)
    if not playerObj then
        return
    end

    local playerNum = BoxxyQuickLoot.getPlayerNumber(playerObj)
    local lootPage = getPlayerLoot and getPlayerLoot(playerNum) or nil
    if lootPage and lootPage.inventoryPane and lootPage.inventoryPane.refreshContainer then
        lootPage.inventoryPane:refreshContainer()
    end
end

function BoxxyQuickLoot.saveList(playerObj)
    if not playerObj then
        return
    end

    if isClient() and playerObj.transmitModData then
        playerObj:transmitModData()
    end

    BoxxyQuickLoot.refreshWindow(playerObj)
    BoxxyQuickLoot.refreshLootPane(playerObj)
end

function BoxxyQuickLoot.getDisplayName(itemOrFullType)
    if type(itemOrFullType) == "string" then
        return getItemNameFromFullType(itemOrFullType) or itemOrFullType
    end

    if not itemOrFullType then
        return "Unknown Item"
    end

    return itemOrFullType:getDisplayName() or itemOrFullType:getName() or itemOrFullType:getFullType()
end

function BoxxyQuickLoot.getStoredEntryInfo(value, fallbackName)
    local name = fallbackName
    local enabled = true
    local icon = nil
    local colorId = BoxxyQuickLoot.highlightColorIdDefault

    if type(value) == "table" then
        name = value.name or value.label or fallbackName
        enabled = value.enabled ~= false
        icon = value.icon
        colorId = BoxxyQuickLoot.getHighlightColorDefinition(value.colorId or value.color).id
    elseif type(value) == "string" then
        name = value
    elseif value == false then
        enabled = false
    end

    return name, enabled, icon, colorId
end

function BoxxyQuickLoot.getItemIconPath(item)
    if not item or not instanceof(item, "InventoryItem") then
        return nil
    end

    local texture = item.getTex and item:getTex() or nil
    if texture and texture.getName then
        return texture:getName()
    end

    return nil
end

function BoxxyQuickLoot.getTextureFromPath(texturePath)
    if type(texturePath) ~= "string" or texturePath == "" then
        return nil
    end

    return getTexture(texturePath)
end

function BoxxyQuickLoot.hasAnyStoredEntries(playerObj)
    return BoxxyQuickLoot.tableHasEntries(BoxxyQuickLoot.getListStore(playerObj)) or
        BoxxyQuickLoot.tableHasEntries(BoxxyQuickLoot.getTermStore(playerObj))
end

function BoxxyQuickLoot.normalizeSearchTerm(term)
    if type(term) ~= "string" then
        return nil
    end

    local normalized = string.lower(term)
    normalized = normalized:gsub("^%s+", "")
    normalized = normalized:gsub("%s+$", "")
    normalized = normalized:gsub("%s+", " ")

    if normalized == "" then
        return nil
    end

    return normalized
end

function BoxxyQuickLoot.getDisplaySearchTerm(term)
    if type(term) ~= "string" then
        return nil
    end

    local displayTerm = term:gsub("^%s+", "")
    displayTerm = displayTerm:gsub("%s+$", "")
    displayTerm = displayTerm:gsub("%s+", " ")

    if displayTerm == "" then
        return nil
    end

    return displayTerm
end

function BoxxyQuickLoot.getTermLabel(term)
    return 'Match: "' .. term .. '"'
end

function BoxxyQuickLoot.hasSearchOperators(term)
    if type(term) ~= "string" then
        return false
    end

    return string.find(term, "|", 1, true) ~= nil or string.find(term, "+", 1, true) ~= nil or
        string.match(term, "^%-") ~= nil or string.match(term, "[%s|+]%-") ~= nil
end

function BoxxyQuickLoot.parseSearchExpression(term)
    local normalizedTerm = BoxxyQuickLoot.normalizeSearchTerm(term)
    if not normalizedTerm or not BoxxyQuickLoot.hasSearchOperators(normalizedTerm) then
        return nil
    end

    local groups = {}

    for rawGroup in string.gmatch(normalizedTerm, "[^|]+") do
        local groupText = BoxxyQuickLoot.normalizeSearchTerm(rawGroup)
        if groupText then
            local group = {
                include = {},
                exclude = {},
            }
            local index = 1

            while index <= #groupText do
                local character = string.sub(groupText, index, index)
                if character == " " or character == "+" then
                    index = index + 1
                else
                    local isExcluded = false
                    if character == "-" then
                        isExcluded = true
                        index = index + 1
                        while index <= #groupText and string.sub(groupText, index, index) == " " do
                            index = index + 1
                        end
                    end

                    local tokenStart = index
                    while index <= #groupText do
                        character = string.sub(groupText, index, index)
                        if character == " " or character == "+" then
                            break
                        end
                        index = index + 1
                    end

                    local token = BoxxyQuickLoot.normalizeSearchTerm(string.sub(groupText, tokenStart, index - 1))
                    if token then
                        local tokenList = isExcluded and group.exclude or group.include
                        table.insert(tokenList, token)
                    end
                end
            end

            if #group.include > 0 or #group.exclude > 0 then
                table.insert(groups, group)
            end
        end
    end

    if #groups == 0 then
        return nil
    end

    return groups
end

function BoxxyQuickLoot.matchesSearchGroup(group, searchText)
    if type(group) ~= "table" or type(searchText) ~= "string" then
        return false
    end

    for _, token in ipairs(group.include or {}) do
        if string.find(searchText, token, 1, true) == nil then
            return false
        end
    end

    for _, token in ipairs(group.exclude or {}) do
        if string.find(searchText, token, 1, true) ~= nil then
            return false
        end
    end

    return #(group.include or {}) > 0 or #(group.exclude or {}) > 0
end

function BoxxyQuickLoot.getItemSearchText(item)
    if not item or not instanceof(item, "InventoryItem") then
        return nil
    end

    local parts = {
        item:getDisplayName() or "",
        item:getName() or "",
        item:getType() or "",
        item:getFullType() or "",
    }

    return string.lower(table.concat(parts, " "))
end

function BoxxyQuickLoot.matchesSearchTerm(term, item)
    local normalizedTerm = BoxxyQuickLoot.normalizeSearchTerm(term)
    local searchText = BoxxyQuickLoot.getItemSearchText(item)
    if normalizedTerm == nil or searchText == nil then
        return false
    end

    local parsedExpression = BoxxyQuickLoot.parseSearchExpression(normalizedTerm)
    if BoxxyQuickLoot.hasSearchOperators(normalizedTerm) then
        if not parsedExpression then
            return false
        end

        for _, group in ipairs(parsedExpression) do
            if BoxxyQuickLoot.matchesSearchGroup(group, searchText) then
                return true
            end
        end

        return false
    end

    return string.find(searchText, normalizedTerm, 1, true) ~= nil
end

function BoxxyQuickLoot.isExactTracked(playerObj, item)
    local store = BoxxyQuickLoot.getListStore(playerObj)
    local fullType = BoxxyQuickLoot.getItemFullType(item)
    if store == nil or fullType == nil or store[fullType] == nil then
        return false
    end

    local _, enabled = BoxxyQuickLoot.getStoredEntryInfo(store[fullType], BoxxyQuickLoot.getDisplayName(fullType))
    return enabled
end

function BoxxyQuickLoot.getExactTrackedColorId(playerObj, item)
    local store = BoxxyQuickLoot.getListStore(playerObj)
    local fullType = BoxxyQuickLoot.getItemFullType(item)
    if store == nil or fullType == nil or store[fullType] == nil then
        return nil
    end

    local _, enabled, _, colorId = BoxxyQuickLoot.getStoredEntryInfo(store[fullType],
        BoxxyQuickLoot.getDisplayName(fullType))
    if enabled == false then
        return nil
    end

    return colorId
end

function BoxxyQuickLoot.findMatchingTerm(playerObj, item)
    local terms = BoxxyQuickLoot.getTermStore(playerObj)
    if type(terms) ~= "table" then
        return nil
    end

    for term, value in pairs(terms) do
        local _, enabled = BoxxyQuickLoot.getStoredEntryInfo(value, term)
        if enabled and BoxxyQuickLoot.matchesSearchTerm(term, item) then
            return term
        end
    end

    return nil
end

function BoxxyQuickLoot.getMatchingTermColorId(playerObj, item)
    local terms = BoxxyQuickLoot.getTermStore(playerObj)
    if type(terms) ~= "table" then
        return nil
    end

    for term, value in pairs(terms) do
        local _, enabled, _, colorId = BoxxyQuickLoot.getStoredEntryInfo(value, term)
        if enabled and BoxxyQuickLoot.matchesSearchTerm(term, item) then
            return colorId
        end
    end

    return nil
end

function BoxxyQuickLoot.getItemHighlightColorId(playerObj, item)
    local colorId = BoxxyQuickLoot.getExactTrackedColorId(playerObj, item)
    if colorId then
        return colorId
    end

    return BoxxyQuickLoot.getMatchingTermColorId(playerObj, item)
end

function BoxxyQuickLoot.getItemHighlightColorDefinition(playerObj, item)
    local colorId = BoxxyQuickLoot.getItemHighlightColorId(playerObj, item)
    if colorId then
        return BoxxyQuickLoot.getHighlightColorDefinition(colorId)
    end

    return nil
end

function BoxxyQuickLoot.isAutoLootEnabledForItem(playerObj, item)
    local colorId = BoxxyQuickLoot.getItemHighlightColorId(playerObj, item)
    if not colorId then
        return true
    end

    return BoxxyQuickLoot.isAutoLootEnabledForColor(playerObj, colorId)
end

function BoxxyQuickLoot.getLootEntryColorPriorityRank(playerObj, paneEntry)
    local item = BoxxyQuickLoot.getEntryItem(paneEntry)
    local colorDef = BoxxyQuickLoot.getItemHighlightColorDefinition(playerObj, item)
    if not colorDef then
        return #BoxxyQuickLoot.highlightColors + 1
    end

    return BoxxyQuickLoot.getColorPriorityRank(playerObj, colorDef.id)
end

function BoxxyQuickLoot.sortPaneEntriesByColorPriority(playerObj, entries)
    if type(entries) ~= "table" or #entries <= 1 then
        return
    end

    table.sort(entries, function(a, b)
        local aPriority = BoxxyQuickLoot.getLootEntryColorPriorityRank(playerObj, a)
        local bPriority = BoxxyQuickLoot.getLootEntryColorPriorityRank(playerObj, b)
        if aPriority == bPriority then
            return (a.__boxxyOriginalIndex or 0) < (b.__boxxyOriginalIndex or 0)
        end

        return aPriority < bPriority
    end)
end

function BoxxyQuickLoot.hasTrackedItems(playerObj)
    local store = BoxxyQuickLoot.getListStore(playerObj)
    local terms = BoxxyQuickLoot.getTermStore(playerObj)

    if type(store) == "table" then
        for fullType, value in pairs(store) do
            local _, enabled = BoxxyQuickLoot.getStoredEntryInfo(value, BoxxyQuickLoot.getDisplayName(fullType))
            if enabled then
                return true
            end
        end
    end

    if type(terms) == "table" then
        for term, value in pairs(terms) do
            local _, enabled = BoxxyQuickLoot.getStoredEntryInfo(value, term)
            if enabled then
                return true
            end
        end
    end

    return false
end

function BoxxyQuickLoot.isTracked(playerObj, item)
    return BoxxyQuickLoot.isExactTracked(playerObj, item) or BoxxyQuickLoot.findMatchingTerm(playerObj, item) ~= nil
end

function BoxxyQuickLoot.addItems(playerObj, items)
    local store = BoxxyQuickLoot.getListStore(playerObj)
    if not store then
        return
    end

    for _, item in ipairs(items) do
        if item then
            store[item:getFullType()] = {
                name = BoxxyQuickLoot.getDisplayName(item),
                enabled = true,
                icon = BoxxyQuickLoot.getItemIconPath(item),
                colorId = BoxxyQuickLoot.highlightColorIdDefault,
            }
        end
    end

    BoxxyQuickLoot.saveList(playerObj)
end

function BoxxyQuickLoot.removeItems(playerObj, items)
    local store = BoxxyQuickLoot.getListStore(playerObj)
    if not store then
        return
    end

    for _, item in ipairs(items) do
        if item then
            store[item:getFullType()] = nil
        end
    end

    BoxxyQuickLoot.saveList(playerObj)
end

function BoxxyQuickLoot.removeFullType(playerObj, fullType)
    local store = BoxxyQuickLoot.getListStore(playerObj)
    if not store then
        return
    end

    store[fullType] = nil
    BoxxyQuickLoot.saveList(playerObj)
end

function BoxxyQuickLoot.addSearchTerm(playerObj, term)
    local normalizedTerm = BoxxyQuickLoot.normalizeSearchTerm(term)
    local displayTerm = BoxxyQuickLoot.getDisplaySearchTerm(term)
    local terms = BoxxyQuickLoot.getTermStore(playerObj)
    if not normalizedTerm or not displayTerm or not terms then
        return false
    end

    terms[normalizedTerm] = {
        label = displayTerm,
        enabled = true,
        colorId = BoxxyQuickLoot.highlightColorIdDefault,
    }
    BoxxyQuickLoot.saveList(playerObj)
    return true
end

function BoxxyQuickLoot.removeSearchTerm(playerObj, term)
    local normalizedTerm = BoxxyQuickLoot.normalizeSearchTerm(term)
    local terms = BoxxyQuickLoot.getTermStore(playerObj)
    if not normalizedTerm or not terms then
        return
    end

    terms[normalizedTerm] = nil
    BoxxyQuickLoot.saveList(playerObj)
end

function BoxxyQuickLoot.setFullTypeEnabled(playerObj, fullType, enabled)
    local store = BoxxyQuickLoot.getListStore(playerObj)
    if not store or not fullType or store[fullType] == nil then
        return
    end

    local name, _, icon, colorId = BoxxyQuickLoot.getStoredEntryInfo(store[fullType],
        BoxxyQuickLoot.getDisplayName(fullType))
    store[fullType] = {
        name = name,
        enabled = enabled ~= false,
        icon = icon,
        colorId = colorId,
    }
    BoxxyQuickLoot.saveList(playerObj)
end

function BoxxyQuickLoot.setSearchTermEnabled(playerObj, term, enabled)
    local normalizedTerm = BoxxyQuickLoot.normalizeSearchTerm(term)
    local terms = BoxxyQuickLoot.getTermStore(playerObj)
    if not normalizedTerm or not terms or terms[normalizedTerm] == nil then
        return
    end

    local label, _, _, colorId = BoxxyQuickLoot.getStoredEntryInfo(terms[normalizedTerm], normalizedTerm)
    terms[normalizedTerm] = {
        label = label,
        enabled = enabled ~= false,
        colorId = colorId,
    }
    BoxxyQuickLoot.saveList(playerObj)
end

function BoxxyQuickLoot.setFullTypeColor(playerObj, fullType, colorId)
    local store = BoxxyQuickLoot.getListStore(playerObj)
    if not store or not fullType or store[fullType] == nil then
        return
    end

    local name, enabled, icon = BoxxyQuickLoot.getStoredEntryInfo(store[fullType],
        BoxxyQuickLoot.getDisplayName(fullType))
    store[fullType] = {
        name = name,
        enabled = enabled,
        icon = icon,
        colorId = BoxxyQuickLoot.getHighlightColorDefinition(colorId).id,
    }
    BoxxyQuickLoot.saveList(playerObj)
end

function BoxxyQuickLoot.setSearchTermColor(playerObj, term, colorId)
    local normalizedTerm = BoxxyQuickLoot.normalizeSearchTerm(term)
    local terms = BoxxyQuickLoot.getTermStore(playerObj)
    if not normalizedTerm or not terms or terms[normalizedTerm] == nil then
        return
    end

    local label, enabled = BoxxyQuickLoot.getStoredEntryInfo(terms[normalizedTerm], normalizedTerm)
    terms[normalizedTerm] = {
        label = label,
        enabled = enabled,
        colorId = BoxxyQuickLoot.getHighlightColorDefinition(colorId).id,
    }
    BoxxyQuickLoot.saveList(playerObj)
end

function BoxxyQuickLoot.setEntryColor(playerObj, entry, colorId)
    if not playerObj or type(entry) ~= "table" then
        return
    end

    if entry.entryType == "term" then
        BoxxyQuickLoot.setSearchTermColor(playerObj, entry.term, colorId)
        return
    end

    BoxxyQuickLoot.setFullTypeColor(playerObj, entry.fullType, colorId)
end

function BoxxyQuickLoot.toggleEntryEnabled(playerObj, entry)
    if not playerObj or not entry or entry.empty then
        return
    end

    local newEnabled = entry.enabled == false
    if entry.entryType == "term" then
        BoxxyQuickLoot.setSearchTermEnabled(playerObj, entry.term, newEnabled)
    else
        BoxxyQuickLoot.setFullTypeEnabled(playerObj, entry.fullType, newEnabled)
    end
end

function BoxxyQuickLoot.getEntrySortName(entry)
    if type(entry) ~= "table" then
        return ""
    end

    return string.lower(entry.rawName or entry.name or "")
end

function BoxxyQuickLoot.compareEntries(a, b, sortMode, sortDirection, disabledLast)
    local mode = "alphabetical"
    if sortMode == "type" then
        mode = "type"
    elseif sortMode == "priority" then
        mode = "priority"
    end
    local direction = sortDirection == "desc" and "desc" or "asc"

    if disabledLast and (a.enabled == false) ~= (b.enabled == false) then
        return a.enabled ~= false
    end

    if mode == "priority" and a.priorityRank ~= b.priorityRank then
        if direction == "desc" then
            return a.priorityRank > b.priorityRank
        end
        return a.priorityRank < b.priorityRank
    end

    if mode == "type" and a.entryType ~= b.entryType then
        local aRank = a.entryType == "item" and 0 or 1
        local bRank = b.entryType == "item" and 0 or 1
        if direction == "desc" then
            return aRank > bRank
        end
        return aRank < bRank
    end

    local aName = BoxxyQuickLoot.getEntrySortName(a)
    local bName = BoxxyQuickLoot.getEntrySortName(b)
    if aName == bName then
        if a.entryType ~= b.entryType then
            return a.entryType == "item"
        end

        local aKey = a.fullType or a.term or ""
        local bKey = b.fullType or b.term or ""
        return string.lower(aKey) < string.lower(bKey)
    end

    if direction == "desc" then
        return aName > bName
    end

    return aName < bName
end

function BoxxyQuickLoot.getSortedEntries(playerObj, sortMode, sortDirection, disabledLast)
    local store = BoxxyQuickLoot.getListStore(playerObj)
    local terms = BoxxyQuickLoot.getTermStore(playerObj)
    local entries = {}

    if not store and not terms then
        return entries
    end

    if store then
        for fullType, value in pairs(store) do
            local name, enabled, icon, colorId = BoxxyQuickLoot.getStoredEntryInfo(value,
                BoxxyQuickLoot.getDisplayName(fullType))
            table.insert(entries, {
                entryType = "item",
                fullType = fullType,
                name = name or BoxxyQuickLoot.getDisplayName(fullType),
                enabled = enabled,
                icon = icon,
                colorId = colorId,
                priorityRank = BoxxyQuickLoot.getColorPriorityRank(playerObj, colorId),
            })
        end
    end

    if terms then
        for term, value in pairs(terms) do
            local label, enabled, _, colorId = BoxxyQuickLoot.getStoredEntryInfo(value, term)
            table.insert(entries, {
                entryType = "term",
                term = term,
                name = BoxxyQuickLoot.getTermLabel(label or term),
                rawName = label or term,
                enabled = enabled,
                colorId = colorId,
                priorityRank = BoxxyQuickLoot.getColorPriorityRank(playerObj, colorId),
            })
        end
    end

    table.sort(entries, function(a, b)
        return BoxxyQuickLoot.compareEntries(a, b, sortMode, sortDirection, disabledLast)
    end)

    return entries
end

function BoxxyQuickLoot.getContextItems(items)
    if not items or #items == 0 then
        return {}
    end

    return ISInventoryPane.getActualItems(items)
end

function BoxxyQuickLoot.getListRowItem(rowEntry)
    if not rowEntry then
        return nil
    end

    if instanceof(rowEntry, "InventoryItem") then
        return rowEntry
    end

    if rowEntry.items and rowEntry.items[2] and instanceof(rowEntry.items[2], "InventoryItem") then
        return rowEntry.items[2]
    end

    return nil
end

function BoxxyQuickLoot.getItemFullType(item)
    if not item or not instanceof(item, "InventoryItem") or item.getFullType == nil then
        return nil
    end

    return item:getFullType()
end

function BoxxyQuickLoot.tableHasEntries(value)
    if type(value) ~= "table" then
        return false
    end

    if type(next) == "function" then
        return next(value) ~= nil
    end

    if type(pairs) == "function" then
        for _ in pairs(value) do
            return true
        end
    end

    return false
end

function BoxxyQuickLoot.clearIndexedTable(value)
    if type(value) ~= "table" then
        return
    end

    for index = #value, 1, -1 do
        value[index] = nil
    end
end

function BoxxyQuickLoot.collectTrackedItems(playerObj, inventory)
    local matches = {}
    local heavyItem = nil
    local totalMatches = 0

    if not inventory or not BoxxyQuickLoot.hasTrackedItems(playerObj) then
        return matches, heavyItem, totalMatches
    end

    local items = inventory:getItems()
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if BoxxyQuickLoot.isTracked(playerObj, item) and BoxxyQuickLoot.isAutoLootEnabledForItem(playerObj, item) then
            totalMatches = totalMatches + 1
            if isForceDropHeavyItem(item) then
                heavyItem = item
            else
                table.insert(matches, item)
            end
        end
    end

    return matches, heavyItem, totalMatches
end

function BoxxyQuickLoot.containerHasTrackedItems(playerObj, inventory)
    if not inventory or not BoxxyQuickLoot.hasTrackedItems(playerObj) then
        return false
    end

    local items = inventory:getItems()
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if BoxxyQuickLoot.isTracked(playerObj, item) and BoxxyQuickLoot.isAutoLootEnabledForItem(playerObj, item) then
            return true
        end
    end

    return false
end

function BoxxyQuickLoot.getLootButtonState(playerObj, inventory)
    if not BoxxyQuickLoot.hasAnyStoredEntries(playerObj) then
        return true, "No quick loot entries yet. Click to open the list."
    end

    if BoxxyQuickLoot.containerHasTrackedItems(playerObj, inventory) then
        return true, nil
    end

    if BoxxyQuickLoot.hasTrackedItems(playerObj) then
        return false, "No matching items in this container."
    end

    if BoxxyQuickLoot.hasAnyStoredEntries(playerObj) then
        return false, "Enable auto loot entries first."
    end

    return false, "Add items to the auto loot list first."
end

function BoxxyQuickLoot.applyLootButtonState(control, buttonEnabled, tooltip)
    if not control then
        return
    end

    control:setEnable(buttonEnabled)
    control.tooltip = tooltip

    if not control.borderColor then
        return
    end
    if buttonEnabled then
        control.borderColor.r = 0.45
        control.borderColor.g = 0.45
        control.borderColor.b = 0.45
        control.borderColor.a = 0.9
        return
    end

    control.borderColor.r = 0
    control.borderColor.g = 0
    control.borderColor.b = 0
    control.borderColor.a = 1.0
end

function BoxxyQuickLoot.showListWindow(playerRef)
    local playerObj = BoxxyQuickLoot.getPlayerObject(playerRef)
    if not playerObj then
        return
    end

    BoxxyQuickLoot.windows = BoxxyQuickLoot.windows or {}

    local playerNum = BoxxyQuickLoot.getPlayerNumber(playerObj)
    local window = BoxxyQuickLoot.windows[playerNum]
    if window then
        window:refreshList()
        window:setVisible(true)
        window:addToUIManager()
        window:bringToTop()
        return
    end

    window = BoxxyQuickLootWindow:new(playerObj)
    window:initialise()
    window:instantiate()
    if #window.children == 0 then
        window:createChildren()
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    BoxxyQuickLoot.windows[playerNum] = window
end

function BoxxyQuickLoot.refreshWindow(playerRef)
    local playerNum = BoxxyQuickLoot.getPlayerNumber(playerRef)
    local window = BoxxyQuickLoot.windows and BoxxyQuickLoot.windows[playerNum] or nil
    if window then
        window:refreshList()
    end
end

function BoxxyQuickLoot.onAddToList(playerObj, items)
    BoxxyQuickLoot.addItems(playerObj, items)
end

function BoxxyQuickLoot.onRemoveFromList(playerObj, items)
    BoxxyQuickLoot.removeItems(playerObj, items)
end

function BoxxyQuickLoot.isMatchedViaSearchTerm(playerObj, item)
    if not playerObj or not item then
        return false
    end

    local matchTerm = BoxxyQuickLoot.findMatchingTerm(playerObj, item)
    return matchTerm ~= nil
end

function BoxxyQuickLoot.onShowMatchClicked(playerObj, item)
    local matchTerm = BoxxyQuickLoot.findMatchingTerm(playerObj, item)
    if not matchTerm then
        return
    end

    BoxxyQuickLoot.showListWindow(playerObj)

    local playerNum = BoxxyQuickLoot.getPlayerNumber(playerObj)
    local window = BoxxyQuickLoot.windows and BoxxyQuickLoot.windows[playerNum]
    if window then
        -- Store the term to highlight
        window.highlightedTerm = matchTerm
    end
end

function BoxxyQuickLoot.getContextMenuIcon()
    if BoxxyQuickLoot.contextMenuIcon == nil then
        BoxxyQuickLoot.contextMenuIcon = getTexture("contexticon.png")
    end

    return BoxxyQuickLoot.contextMenuIcon
end

function BoxxyQuickLoot.onFillInventoryObjectContextMenu(playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    local actualItems = BoxxyQuickLoot.getContextItems(items)
    if not playerObj or #actualItems == 0 then
        return
    end

    local anyTracked = false
    local anyUntracked = false
    local anyMatched = false
    local firstMatchedItem = nil

    for _, item in ipairs(actualItems) do
        if BoxxyQuickLoot.isExactTracked(playerObj, item) then
            anyTracked = true
        else
            anyUntracked = true
        end

        if BoxxyQuickLoot.isMatchedViaSearchTerm(playerObj, item) then
            anyMatched = true
            if not firstMatchedItem then
                firstMatchedItem = item
            end
        end
    end

    local option = context:addOption("Quick Loot")
    option.iconTexture = BoxxyQuickLoot.getContextMenuIcon()
    local subMenu = context:getNew(context)
    context:addSubMenu(option, subMenu)

    if anyUntracked then
        subMenu:addOption("Add to list", playerObj, BoxxyQuickLoot.onAddToList, actualItems)
    end
    if anyTracked then
        subMenu:addOption("Remove from list", playerObj, BoxxyQuickLoot.onRemoveFromList, actualItems)
    end
    if anyMatched and firstMatchedItem then
        subMenu:addOption("Show match", playerObj, BoxxyQuickLoot.onShowMatchClicked, firstMatchedItem)
    end
    subMenu:addOption("Show list", playerNum, BoxxyQuickLoot.showListWindow)
end

function BoxxyQuickLoot.onAutoLootClicked(page)
    local playerObj = getSpecificPlayer(page.player)
    local inventory = page.inventoryPane and page.inventoryPane.inventory or nil
    if not playerObj or not inventory then
        return
    end

    if not BoxxyQuickLoot.hasAnyStoredEntries(playerObj) then
        BoxxyQuickLoot.showListWindow(playerObj)
        return
    end

    if not luautils.walkToContainer(inventory, page.player) then
        return
    end

    local items, heavyItem, totalMatches = BoxxyQuickLoot.collectTrackedItems(playerObj, inventory)
    local playerInventory = getPlayerInventory(page.player).inventory

    if heavyItem and totalMatches == 1 and #items == 0 then
        ISInventoryPaneContextMenu.equipHeavyItem(playerObj, heavyItem)
        return
    end

    if #items == 0 then
        return
    end

    page.inventoryPane:transferItemsByWeight(items, playerInventory)
    page.inventoryPane.selected = {}
    getPlayerLoot(page.player).inventoryPane.selected = {}
    getPlayerInventory(page.player).inventoryPane.selected = {}
end

function BoxxyQuickLoot.isVisibleUiElement(uiElement)
    if not uiElement then
        return false
    end

    if uiElement.getIsVisible then
        return uiElement:getIsVisible()
    end

    if uiElement.isVisible then
        return uiElement:isVisible()
    end

    return uiElement.visible == true
end

function BoxxyQuickLoot.canTriggerAutoLoot(page)
    if not BoxxyQuickLoot.isVisibleUiElement(page) or not BoxxyQuickLoot.shouldShowLootActionForPage(page) then
        return false
    end

    local playerObj = getSpecificPlayer(page.player)
    local inventory = page.inventoryPane and page.inventoryPane.inventory or nil
    local buttonEnabled = BoxxyQuickLoot.getLootButtonState(playerObj, inventory)
    return buttonEnabled
end

function BoxxyQuickLoot.getActiveLootPage()
    for playerNum = 0, 3 do
        local lootPage = getPlayerLoot(playerNum)
        if BoxxyQuickLoot.canTriggerAutoLoot(lootPage) then
            return lootPage
        end
    end

    return nil
end

function BoxxyQuickLoot.onAutoLootKeyPressed(key)
    local keyOption = BoxxyQuickLoot.autoLootKeyOption
    if not getPlayer() or not keyOption then
        return
    end

    local boundKey = keyOption:getValue()
    if not boundKey or boundKey == Keyboard.KEY_NONE or key ~= boundKey then
        return
    end

    local lootPage = BoxxyQuickLoot.getActiveLootPage()
    if lootPage then
        BoxxyQuickLoot.onAutoLootClicked(lootPage)
    end
end

function BoxxyQuickLoot.hasCleanUILootControls()
    return ISLootWindowContainerControls ~= nil and ISLootWindowContainerControls.AddHandler ~= nil and
        ISLootWindowObjectControlHandler ~= nil and ISLootWindowFloorControlHandler ~= nil
end

function BoxxyQuickLoot.shouldShowLootActionForPage(page)
    if not page or page.onCharacter then
        return false
    end

    local playerObj = getSpecificPlayer(page.player)
    local inventory = page.inventoryPane and page.inventoryPane.inventory or nil
    if not playerObj or not inventory or not inventory.getItems then
        return false
    end

    local items = inventory:getItems()
    return items ~= nil and not items:isEmpty()
end

function BoxxyQuickLoot.registerCleanUIHandler()
    if not BoxxyQuickLoot.hasCleanUILootControls() or BoxxyQuickLoot.cleanUIHandlerRegistered then
        return
    end

    ISLootWindowObjectControlHandler_BoxxyQuickLoot = ISLootWindowObjectControlHandler:derive(
        "ISLootWindowObjectControlHandler_BoxxyQuickLoot")
    local ObjectHandler = ISLootWindowObjectControlHandler_BoxxyQuickLoot

    function ObjectHandler:shouldBeVisible()
        return BoxxyQuickLoot.shouldShowLootActionForPage(self.lootWindow)
    end

    function ObjectHandler:getControl()
        local control = self:getButtonControl("Quick Loot")
        local playerObj = self.lootWindow and getSpecificPlayer(self.lootWindow.player) or nil
        local inventory = self.lootWindow and self.lootWindow.inventoryPane and self.lootWindow.inventoryPane.inventory or
            nil
        local buttonEnabled, tooltip = BoxxyQuickLoot.getLootButtonState(playerObj, inventory)
        BoxxyQuickLoot.applyLootButtonState(control, buttonEnabled, tooltip)
        return control
    end

    function ObjectHandler:perform()
        BoxxyQuickLoot.onAutoLootClicked(self.lootWindow)
    end

    function ObjectHandler:new()
        local o = ISLootWindowObjectControlHandler.new(self)
        o.altColor = false
        return o
    end

    ISLootWindowFloorControlHandler_BoxxyQuickLoot = ISLootWindowFloorControlHandler:derive(
        "ISLootWindowFloorControlHandler_BoxxyQuickLoot")
    local FloorHandler = ISLootWindowFloorControlHandler_BoxxyQuickLoot

    function FloorHandler:shouldBeVisible()
        return BoxxyQuickLoot.shouldShowLootActionForPage(self.lootWindow)
    end

    function FloorHandler:getControl()
        local control = self:getButtonControl("Quick Loot")
        local playerObj = self.lootWindow and getSpecificPlayer(self.lootWindow.player) or nil
        local inventory = self.lootWindow and self.lootWindow.inventoryPane and self.lootWindow.inventoryPane.inventory or
            nil
        local buttonEnabled, tooltip = BoxxyQuickLoot.getLootButtonState(playerObj, inventory)
        BoxxyQuickLoot.applyLootButtonState(control, buttonEnabled, tooltip)
        return control
    end

    function FloorHandler:perform()
        BoxxyQuickLoot.onAutoLootClicked(self.lootWindow)
    end

    function FloorHandler:new()
        return ISLootWindowFloorControlHandler.new(self)
    end

    ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_BoxxyQuickLoot)
    ISLootWindowContainerControls.AddFloorHandler(ISLootWindowFloorControlHandler_BoxxyQuickLoot)
    BoxxyQuickLoot.cleanUIHandlerRegistered = true
end

function BoxxyQuickLoot.isButtonControl(control)
    return type(control) == "table" and control.Type == "ISButton" and control.getRight ~= nil and
        control.getY ~= nil and control.getHeight ~= nil
end

function BoxxyQuickLoot.getLootAllControl(page)
    if not page then
        return nil
    end

    local directControl = rawget(page, "lootAll")
    if BoxxyQuickLoot.isButtonControl(directControl) then
        return directControl
    end

    local expectedTitle = getText("IGUI_invpage_Loot_all")
    for _, child in ipairs(page.children or {}) do
        if BoxxyQuickLoot.isButtonControl(child) then
            local title = child.getTitle and child:getTitle() or child.title
            if title == expectedTitle or (child.onclick == ISInventoryPage.lootAll and child.target == page) then
                return child
            end
        end
    end

    return nil
end

function BoxxyQuickLoot.attachLootButton(page)
    if not page or page.onCharacter or page.BoxxyQuickLootButton or BoxxyQuickLoot.hasCleanUILootControls() then
        return
    end

    local lootAllControl = BoxxyQuickLoot.getLootAllControl(page)
    if not lootAllControl then
        return
    end

    local button = ISButton:new(lootAllControl:getRight() + 6, lootAllControl:getY(), 80, lootAllControl:getHeight(),
        "Quick Loot", page, BoxxyQuickLoot.onAutoLootClicked)
    button:initialise()
    button.borderColor.a = 0.0
    button.backgroundColor.a = 0.0
    button.backgroundColorMouseOver.a = 0.7
    button:setVisible(false)
    button:setWidthToTitle()
    page:addChild(button)
    page.BoxxyQuickLootButton = button
end

function BoxxyQuickLoot.updateLootButton(page)
    if BoxxyQuickLoot.hasCleanUILootControls() then
        return
    end

    if not page or page.onCharacter or not page.BoxxyQuickLootButton then
        return
    end

    local lootAllControl = BoxxyQuickLoot.getLootAllControl(page)
    if not lootAllControl then
        page.BoxxyQuickLootButton:setVisible(false)
        return
    end

    local playerObj = getSpecificPlayer(page.player)
    local inventory = page.inventoryPane and page.inventoryPane.inventory or nil
    local shouldShow = lootAllControl:getIsVisible() and inventory ~= nil and inventory:getItems() and
        not inventory:getItems():isEmpty()

    page.BoxxyQuickLootButton:setVisible(shouldShow)
    if not shouldShow then
        return
    end

    page.BoxxyQuickLootButton:setX(lootAllControl:getRight() + 6)
    page.BoxxyQuickLootButton:setY(lootAllControl:getY())
    page.BoxxyQuickLootButton:setHeight(lootAllControl:getHeight())
    page.BoxxyQuickLootButton:setWidthToTitle()
    local buttonEnabled, tooltip = BoxxyQuickLoot.getLootButtonState(playerObj, inventory)
    BoxxyQuickLoot.applyLootButtonState(page.BoxxyQuickLootButton, buttonEnabled, tooltip)
end

function BoxxyQuickLoot.drawTrackedHighlights(pane, doDragged)
    if doDragged or not pane or not pane.inventoryPage or pane.inventoryPage.onCharacter then
        return
    end

    local playerObj = getSpecificPlayer(pane.player)
    if not playerObj or not BoxxyQuickLoot.hasTrackedItems(playerObj) or type(pane.items) ~= "table" then
        return
    end

    if pane.getYScroll == nil or pane.getWidth == nil or pane.getHeight == nil or pane.drawRect == nil or
        pane.drawRectBorder == nil or pane.isVScrollBarVisible == nil then
        return
    end

    local yScroll = pane:getYScroll()
    local rowWidth = pane:getWidth() - pane.column2 - (pane:isVScrollBarVisible() and 14 or 2)

    for index, rowEntry in ipairs(pane.items) do
        local item = BoxxyQuickLoot.getListRowItem(rowEntry)
        local colorDef = BoxxyQuickLoot.getItemHighlightColorDefinition(playerObj, item)
        if colorDef then
            local top = (index - 1) * pane.itemHgt + pane.headerHgt
            local scrolledTop = top + yScroll
            if scrolledTop + pane.itemHgt >= 0 and scrolledTop <= pane:getHeight() then
                pane:drawRect(pane.column2, top, rowWidth, pane.itemHgt, colorDef.fill.a, colorDef.fill.r,
                    colorDef.fill.g, colorDef.fill.b)
                pane:drawRect(1, top, 4, pane.itemHgt, colorDef.marker.a, colorDef.marker.r, colorDef.marker.g,
                    colorDef.marker.b)
                pane:drawRectBorder(pane.column2, top, rowWidth, pane.itemHgt, colorDef.border.a,
                    colorDef.border.r, colorDef.border.g, colorDef.border.b)
            end
        end
    end
end

function BoxxyQuickLoot.getEntryItem(entry)
    if type(entry) ~= "table" or type(entry.items) ~= "table" then
        return nil
    end

    for _, item in ipairs(entry.items) do
        if instanceof(item, "InventoryItem") then
            return item
        end
    end

    return nil
end

function BoxxyQuickLoot.reorderTrackedEntries(pane)
    if not pane or not pane.inventoryPage or pane.inventoryPage.onCharacter or type(pane.itemslist) ~= "table" then
        return
    end

    local playerObj = getSpecificPlayer(pane.player)
    if not playerObj or not BoxxyQuickLoot.hasTrackedItems(playerObj) then
        return
    end

    local searchMatches = {}
    local trackedEntries = {}
    local otherEntries = {}

    for index, entry in ipairs(pane.itemslist) do
        entry.__boxxyOriginalIndex = index
        local item = BoxxyQuickLoot.getEntryItem(entry)
        local isTracked = BoxxyQuickLoot.isTracked(playerObj, item)

        if entry.matchesSearch then
            table.insert(searchMatches, entry)
        elseif isTracked then
            table.insert(trackedEntries, entry)
        else
            table.insert(otherEntries, entry)
        end
    end

    BoxxyQuickLoot.sortPaneEntriesByColorPriority(playerObj, searchMatches)
    BoxxyQuickLoot.sortPaneEntriesByColorPriority(playerObj, trackedEntries)

    BoxxyQuickLoot.clearIndexedTable(pane.itemslist)

    for _, entry in ipairs(searchMatches) do
        entry.__boxxyOriginalIndex = nil
        table.insert(pane.itemslist, entry)
    end

    for _, entry in ipairs(trackedEntries) do
        entry.__boxxyOriginalIndex = nil
        table.insert(pane.itemslist, entry)
    end

    for _, entry in ipairs(otherEntries) do
        entry.__boxxyOriginalIndex = nil
        table.insert(pane.itemslist, entry)
    end
end

function BoxxyQuickLoot.patchInventoryUi()
    if BoxxyQuickLoot.isPatched then
        return
    end

    BoxxyQuickLoot.isPatched = true
    BoxxyQuickLoot.emptyContextMenu = BoxxyQuickLoot.emptyContextMenu or {
        isAnyVisible = function()
            return false
        end,
    }

    if not BoxxyQuickLoot.originalGetPlayerContextMenu and type(getPlayerContextMenu) == "function" then
        BoxxyQuickLoot.originalGetPlayerContextMenu = getPlayerContextMenu
        function getPlayerContextMenu(playerNum)
            local contextMenu = BoxxyQuickLoot.originalGetPlayerContextMenu(playerNum)
            if contextMenu ~= nil then
                return contextMenu
            end

            return BoxxyQuickLoot.emptyContextMenu
        end
    end

    BoxxyQuickLoot.originalCreateChildren = ISInventoryPage.createChildren
    BoxxyQuickLoot.originalPageUpdate = ISInventoryPage.update
    BoxxyQuickLoot.originalRefreshContainer = ISInventoryPane.refreshContainer
    BoxxyQuickLoot.originalRenderDetails = ISInventoryPane.renderdetails

    function ISInventoryPage:createChildren()
        BoxxyQuickLoot.originalCreateChildren(self)
        BoxxyQuickLoot.attachLootButton(self)
    end

    function ISInventoryPage:update()
        BoxxyQuickLoot.originalPageUpdate(self)
        BoxxyQuickLoot.updateLootButton(self)
    end

    function ISInventoryPane:refreshContainer()
        BoxxyQuickLoot.originalRefreshContainer(self)
        BoxxyQuickLoot.reorderTrackedEntries(self)
    end

    function ISInventoryPane:renderdetails(doDragged)
        BoxxyQuickLoot.originalRenderDetails(self, doDragged)
        BoxxyQuickLoot.drawTrackedHighlights(self, doDragged)
    end
end

function BoxxyQuickLoot.attachExistingLootPages()
    BoxxyQuickLoot.registerCleanUIHandler()

    for playerNum = 0, 3 do
        local lootPage = getPlayerLoot(playerNum)
        if lootPage then
            BoxxyQuickLoot.attachLootButton(lootPage)
            BoxxyQuickLoot.updateLootButton(lootPage)
        end
    end
end

function BoxxyQuickLoot.getListButtonPositions(listbox)
    local removeX = listbox:getWidth() - BoxxyQuickLootWindow.removeButtonWidth - BoxxyQuickLootWindow
        .actionRightPadding
    local toggleX = removeX - BoxxyQuickLootWindow.toggleButtonWidth - BoxxyQuickLootWindow.actionButtonGap
    local colorX = toggleX - BoxxyQuickLootWindow.colorButtonWidth - BoxxyQuickLootWindow.actionButtonGap
    return colorX, toggleX, removeX
end

function BoxxyQuickLoot.getRowButtonColors(buttonType, isHovered, isDisabledAction)
    if buttonType == "color" then
        if isHovered then
            return 0.96, 0.2, 0.22, 0.22, 0.98, 0.58, 0.58, 0.58
        end
        return 0.92, 0.12, 0.14, 0.14, 0.94, 0.42, 0.42, 0.42
    end

    if buttonType == "remove" then
        if isHovered then
            return 0.96, 0.4, 0.18, 0.18, 0.98, 0.88, 0.5, 0.5
        end
        return 0.92, 0.26, 0.12, 0.12, 0.94, 0.74, 0.34, 0.34
    end

    if isDisabledAction then
        if isHovered then
            return 0.92, 0.28, 0.28, 0.28, 0.96, 0.52, 0.52, 0.52
        end
        return 0.88, 0.2, 0.2, 0.2, 0.92, 0.4, 0.4, 0.4
    end

    if isHovered then
        return 0.94, 0.32, 0.4, 0.32, 0.98, 0.62, 0.76, 0.62
    end

    return 0.9, 0.24, 0.3, 0.24, 0.94, 0.52, 0.66, 0.52
end

BoxxyQuickLootColorPickerWindow = ISPanel:derive("BoxxyQuickLootColorPickerWindow")

function BoxxyQuickLootColorPickerWindow:titleBarHeight()
    return self.headerHeight or 34
end

function BoxxyQuickLootColorPickerWindow:getCloseIconBounds()
    local iconSize = 20
    local iconX = self.width - iconSize - 10
    local iconY = 7
    return iconX, iconY, iconSize, iconSize
end

function BoxxyQuickLootColorPickerWindow:close()
    if self.parentWindow and self.parentWindow.colorPickerWindow == self then
        self.parentWindow.colorPickerWindow = nil
    end

    self:removeFromUIManager()
end

function BoxxyQuickLootColorPickerWindow:onMouseDown(x, y)
    local closeX, closeY, closeW, closeH = self:getCloseIconBounds()
    if x >= closeX and x <= (closeX + closeW) and y >= closeY and y <= (closeY + closeH) then
        self:close()
        return true
    end

    if y <= self:titleBarHeight() then
        self.moveWithMouse = true
        return true
    end

    return ISPanel.onMouseDown(self, x, y)
end

function BoxxyQuickLootColorPickerWindow:onMouseMove(dx, dy)
    if self.moveWithMouse then
        self:setX(self:getX() + dx)
        self:setY(self:getY() + dy)
        return true
    end

    return ISPanel.onMouseMove(self, dx, dy)
end

function BoxxyQuickLootColorPickerWindow:onMouseMoveOutside(dx, dy)
    if self.moveWithMouse then
        self:setX(self:getX() + dx)
        self:setY(self:getY() + dy)
        return true
    end

    return ISPanel.onMouseMoveOutside(self, dx, dy)
end

function BoxxyQuickLootColorPickerWindow:onMouseUp(x, y)
    self.moveWithMouse = false
    return ISPanel.onMouseUp(self, x, y)
end

function BoxxyQuickLootColorPickerWindow:onMouseUpOutside(x, y)
    self.moveWithMouse = false
    return ISPanel.onMouseUpOutside(self, x, y)
end

function BoxxyQuickLootColorPickerWindow:prerender()
    ISPanel.prerender(self)

    local titleBarHeight = self:titleBarHeight()
    local swatchY = titleBarHeight + FONT_HGT_SMALL + 22
    local arrowY = swatchY + 34 + 6
    local checkboxY = arrowY + 16 + 8
    local footerY = checkboxY + 26
    self:drawRect(0, 0, self.width, self.height, 0.96, 0.05, 0.05, 0.06)
    self:drawRectBorder(0, 0, self.width, self.height, 1.0, 0.32, 0.28, 0.16)
    self:drawRect(1, 1, self.width - 2, titleBarHeight, 0.94, 0.11, 0.11, 0.13)
    self:drawRectBorder(1, 1, self.width - 2, titleBarHeight, 0.45, 0.36, 0.32, 0.2)
    self:drawText("Highlight Colors", 10, math.floor((titleBarHeight - FONT_HGT_MEDIUM) / 2) + 1, 0.99, 0.96,
        0.88, 1.0, UIFont.Medium)
    self:drawText("Pick a color, set priority, and choose Quick Loot colors.", 10, titleBarHeight + 10, 0.82, 0.82,
        0.78, 1.0,
        UIFont.Small)
    self:drawText("Checked colors can be looted by the Quick Loot hotkey.", 10, footerY, 0.72,
        0.72, 0.68, 1.0, UIFont.Small)
    self:drawText("Leftmost colors appear first in the loot window.", 10, footerY + FONT_HGT_SMALL, 0.72,
        0.72, 0.68, 1.0, UIFont.Small)
end

function BoxxyQuickLootColorPickerWindow:render()
    ISPanel.render(self)

    local mouseX = getMouseX() - self:getAbsoluteX()
    local mouseY = getMouseY() - self:getAbsoluteY()
    local closeX, closeY, closeW, closeH = self:getCloseIconBounds()
    local isCloseHovered = mouseX >= closeX and mouseX <= (closeX + closeW) and mouseY >= closeY and mouseY <=
        (closeY + closeH)

    if isCloseHovered and CLOSE_ICON_HOVER then
        self:drawTextureScaled(CLOSE_ICON_HOVER, closeX, closeY, closeW, closeH, 1, 1, 1, 1)
    elseif CLOSE_ICON then
        self:drawTextureScaled(CLOSE_ICON, closeX, closeY, closeW, closeH, 1, 1, 1, 1)
    end

    self:drawPriorityArrowButtons(mouseX, mouseY)
    self:drawAutoLootCheckboxes(mouseX, mouseY)
end

function BoxxyQuickLootColorPickerWindow:drawPriorityArrowButtons(mouseX, mouseY)
    if not SORT_PRIORITY_ICON then
        return
    end

    for _, priorityButtons in pairs(self.priorityButtons or {}) do
        for _, button in ipairs({ priorityButtons.left, priorityButtons.right }) do
            if button then
                local iconPadding = 3
                local isEnabled = button.boxxyEnabled == true
                local iconAlpha = isEnabled and 0.96 or 0.28
                local isHovered = mouseX >= button:getX() and mouseX <= (button:getX() + button:getWidth()) and
                    mouseY >= button:getY() and mouseY <= (button:getY() + button:getHeight())

                if isEnabled and isHovered then
                    iconAlpha = 1.0
                end

                if button.moveOffset == -1 then
                    self:drawTextureScaled(SORT_PRIORITY_ICON, button:getX() + iconPadding, button:getY() + iconPadding,
                        button:getWidth() - (iconPadding * 2), button:getHeight() - (iconPadding * 2), iconAlpha, 1, 1,
                        1)
                else
                    self:drawTextureScaled(SORT_PRIORITY_ICON,
                        button:getX() + button:getWidth() - iconPadding,
                        button:getY() + iconPadding,
                        -(button:getWidth() - (iconPadding * 2)), button:getHeight() - (iconPadding * 2), iconAlpha, 1,
                        1, 1)
                end
            end
        end
    end
end

function BoxxyQuickLootColorPickerWindow:drawAutoLootCheckboxes(mouseX, mouseY)
    for colorId, button in pairs(self.autoLootCheckboxButtons or {}) do
        local isChecked = self.autoLootColorStates and self.autoLootColorStates[colorId] ~= false
        local isHovered = mouseX >= button:getX() and mouseX <= (button:getX() + button:getWidth()) and
            mouseY >= button:getY() and mouseY <= (button:getY() + button:getHeight())
        local borderAlpha = isHovered and 0.95 or 0.76
        local colorDef = BoxxyQuickLoot.getHighlightColorDefinition(colorId)

        self:drawRect(button:getX(), button:getY(), button:getWidth(), button:getHeight(), isChecked and 0.9 or 0.32,
            0.08, 0.09, 0.08)
        self:drawRectBorder(button:getX(), button:getY(), button:getWidth(), button:getHeight(), borderAlpha,
            isChecked and colorDef.marker.r or 0.42,
            isChecked and colorDef.marker.g or 0.42,
            isChecked and colorDef.marker.b or 0.42)

        if isChecked then
            self:drawTextCentre("x", button:getX() + (button:getWidth() / 2),
                button:getY() + math.floor((button:getHeight() - FONT_HGT_SMALL) / 2) - 1,
                0.95, 0.95, 0.95, 1.0, UIFont.Small)
        end
    end
end

function BoxxyQuickLootColorPickerWindow:layoutSwatchControls()
    local swatchSize = 34
    local swatchGap = 10
    local arrowSize = 16
    local arrowGap = 2
    local checkboxSize = 16
    local swatchY = self:titleBarHeight() + FONT_HGT_SMALL + 22
    local arrowY = swatchY + swatchSize + 6
    local checkboxY = arrowY + arrowSize + 8
    local totalWidth = (#self.colorPriorityIds * swatchSize) + ((#self.colorPriorityIds - 1) * swatchGap)
    local swatchX = math.floor((self.width - totalWidth) / 2)

    for index, colorId in ipairs(self.colorPriorityIds) do
        local cellX = swatchX + ((index - 1) * (swatchSize + swatchGap))
        local swatchButton = self.swatchButtons[colorId]
        local priorityButtons = self.priorityButtons[colorId]
        local autoLootCheckboxButton = self.autoLootCheckboxButtons[colorId]

        swatchButton:setX(cellX)
        swatchButton:setY(swatchY)

        priorityButtons.left:setX(cellX)
        priorityButtons.left:setY(arrowY)
        priorityButtons.right:setX(cellX + arrowSize + arrowGap)
        priorityButtons.right:setY(arrowY)

        autoLootCheckboxButton:setX(cellX + math.floor((swatchSize - checkboxSize) / 2))
        autoLootCheckboxButton:setY(checkboxY)
    end
end

function BoxxyQuickLootColorPickerWindow:updateSwatchButtons()
    self:layoutSwatchControls()

    for index, colorId in ipairs(self.colorPriorityIds or {}) do
        local button = self.swatchButtons[colorId]
        local priorityButtons = self.priorityButtons[colorId]
        local colorDef = BoxxyQuickLoot.getHighlightColorDefinition(colorId)
        local isSelected = self.entryColorId == colorDef.id

        button.backgroundColor = button.backgroundColor or {}
        button.backgroundColorMouseOver = button.backgroundColorMouseOver or {}
        button.borderColor = button.borderColor or {}

        BoxxyQuickLoot.copyColor(button.backgroundColor, colorDef.preview)
        BoxxyQuickLoot.copyColor(button.backgroundColorMouseOver, colorDef.preview)

        if isSelected then
            button.borderColor.r = 0.98
            button.borderColor.g = 0.96
            button.borderColor.b = 0.9
            button.borderColor.a = 1.0
        else
            button.borderColor.r = 0.26
            button.borderColor.g = 0.24
            button.borderColor.b = 0.2
            button.borderColor.a = 0.95
        end

        for _, priorityButton in ipairs({ priorityButtons.left, priorityButtons.right }) do
            priorityButton.backgroundColor = priorityButton.backgroundColor or {}
            priorityButton.backgroundColorMouseOver = priorityButton.backgroundColorMouseOver or {}
            priorityButton.borderColor = priorityButton.borderColor or {}
            priorityButton.textColor = priorityButton.textColor or {}

            local isEnabled = (priorityButton.moveOffset == -1 and index > 1) or
                (priorityButton.moveOffset == 1 and index < #self.colorPriorityIds)
            priorityButton.boxxyEnabled = isEnabled
            priorityButton:setEnable(isEnabled)

            priorityButton.backgroundColor.r = 0.1
            priorityButton.backgroundColor.g = 0.1
            priorityButton.backgroundColor.b = 0.11
            priorityButton.backgroundColor.a = isEnabled and 0.76 or 0.42
            priorityButton.backgroundColorMouseOver.r = 0.16
            priorityButton.backgroundColorMouseOver.g = 0.16
            priorityButton.backgroundColorMouseOver.b = 0.18
            priorityButton.backgroundColorMouseOver.a = isEnabled and 0.9 or 0.42
            priorityButton.borderColor.r = isEnabled and 0.42 or 0.26
            priorityButton.borderColor.g = isEnabled and 0.42 or 0.26
            priorityButton.borderColor.b = isEnabled and 0.38 or 0.26
            priorityButton.borderColor.a = isEnabled and 0.88 or 0.56
            priorityButton.textColor.r = 1.0
            priorityButton.textColor.g = 1.0
            priorityButton.textColor.b = 1.0
            priorityButton.textColor.a = isEnabled and 1.0 or 0.28
        end

        local autoLootCheckboxButton = self.autoLootCheckboxButtons[colorId]
        autoLootCheckboxButton.backgroundColor = autoLootCheckboxButton.backgroundColor or {}
        autoLootCheckboxButton.backgroundColorMouseOver = autoLootCheckboxButton.backgroundColorMouseOver or {}
        autoLootCheckboxButton.borderColor = autoLootCheckboxButton.borderColor or {}

        autoLootCheckboxButton.backgroundColor.r = 0.1
        autoLootCheckboxButton.backgroundColor.g = 0.1
        autoLootCheckboxButton.backgroundColor.b = 0.11
        autoLootCheckboxButton.backgroundColor.a = 0.72
        autoLootCheckboxButton.backgroundColorMouseOver.r = 0.16
        autoLootCheckboxButton.backgroundColorMouseOver.g = 0.16
        autoLootCheckboxButton.backgroundColorMouseOver.b = 0.18
        autoLootCheckboxButton.backgroundColorMouseOver.a = 0.88
        autoLootCheckboxButton.borderColor.r = 0.42
        autoLootCheckboxButton.borderColor.g = 0.42
        autoLootCheckboxButton.borderColor.b = 0.42
        autoLootCheckboxButton.borderColor.a = 0.78
    end
end

function BoxxyQuickLootColorPickerWindow:onSwatchClicked(button)
    if not self.targetEntry then
        return
    end

    BoxxyQuickLoot.setEntryColor(self.parentWindow.playerObj, self.targetEntry, button.colorId)
    self.entryColorId = button.colorId
    self.parentWindow:refreshList()
    self:close()
end

function BoxxyQuickLootColorPickerWindow:onAutoLootCheckboxClicked(button)
    self.autoLootColorStates = BoxxyQuickLoot.normalizeAutoLootColorStates(self.autoLootColorStates)
    self.autoLootColorStates[button.colorId] = not (self.autoLootColorStates[button.colorId] ~= false)
    BoxxyQuickLoot.saveAutoLootColorStates(self.parentWindow.playerObj, self.autoLootColorStates)
    self.autoLootColorStates = BoxxyQuickLoot.getSavedAutoLootColorStates(self.parentWindow.playerObj)
    self:updateSwatchButtons()
end

function BoxxyQuickLootColorPickerWindow:onPriorityMoveClicked(button)
    local currentIndex = nil

    for index, colorId in ipairs(self.colorPriorityIds) do
        if colorId == button.colorId then
            currentIndex = index
            break
        end
    end

    if not currentIndex then
        return
    end

    local nextIndex = currentIndex + button.moveOffset
    if nextIndex < 1 or nextIndex > #self.colorPriorityIds then
        return
    end

    self.colorPriorityIds[currentIndex], self.colorPriorityIds[nextIndex] =
        self.colorPriorityIds[nextIndex], self.colorPriorityIds[currentIndex]

    BoxxyQuickLoot.saveColorPriorityIds(self.parentWindow.playerObj, self.colorPriorityIds)
    self.colorPriorityIds = BoxxyQuickLoot.getSavedColorPriorityIds(self.parentWindow.playerObj)
    self:updateSwatchButtons()
end

function BoxxyQuickLootColorPickerWindow:createChildren()
    ISPanel.createChildren(self)

    local swatchSize = 34
    local arrowSize = 16
    local checkboxSize = 16

    self.swatchButtons = {}
    self.priorityButtons = {}
    self.autoLootCheckboxButtons = {}

    for index, colorDef in ipairs(BoxxyQuickLoot.highlightColors) do
        local button = ISButton:new(0, 0, swatchSize, swatchSize,
            "", self, BoxxyQuickLootColorPickerWindow.onSwatchClicked)
        button:initialise()
        button:instantiate()
        button:setAnchorTop(true)
        button:setAnchorLeft(true)
        button.colorId = colorDef.id
        button.tooltip = colorDef.label
        self:addChild(button)

        local leftButton = ISButton:new(0, 0, arrowSize, arrowSize, "", self,
            BoxxyQuickLootColorPickerWindow.onPriorityMoveClicked)
        leftButton:initialise()
        leftButton:instantiate()
        leftButton:setAnchorTop(true)
        leftButton:setAnchorLeft(true)
        leftButton.colorId = colorDef.id
        leftButton.moveOffset = -1
        leftButton.tooltip = "Move higher priority"
        self:addChild(leftButton)

        local rightButton = ISButton:new(0, 0, arrowSize, arrowSize, "", self,
            BoxxyQuickLootColorPickerWindow.onPriorityMoveClicked)
        rightButton:initialise()
        rightButton:instantiate()
        rightButton:setAnchorTop(true)
        rightButton:setAnchorLeft(true)
        rightButton.colorId = colorDef.id
        rightButton.moveOffset = 1
        rightButton.tooltip = "Move lower priority"
        self:addChild(rightButton)

        local autoLootCheckboxButton = ISButton:new(0, 0, checkboxSize, checkboxSize, "", self,
            BoxxyQuickLootColorPickerWindow.onAutoLootCheckboxClicked)
        autoLootCheckboxButton:initialise()
        autoLootCheckboxButton:instantiate()
        autoLootCheckboxButton:setAnchorTop(true)
        autoLootCheckboxButton:setAnchorLeft(true)
        autoLootCheckboxButton.colorId = colorDef.id
        autoLootCheckboxButton.tooltip = "Quick Loot enabled for " .. colorDef.label
        self:addChild(autoLootCheckboxButton)

        self.swatchButtons[colorDef.id] = button
        self.priorityButtons[colorDef.id] = {
            left = leftButton,
            right = rightButton,
        }
        self.autoLootCheckboxButtons[colorDef.id] = autoLootCheckboxButton
    end

    self:updateSwatchButtons()
end

function BoxxyQuickLootColorPickerWindow:new(parentWindow, entry)
    local width = parentWindow and parentWindow.getWidth and parentWindow:getWidth() or 300
    local height = 242
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    local x = parentWindow:getAbsoluteX() + math.floor((parentWindow:getWidth() - width) / 2)
    local y = parentWindow:getAbsoluteY() + parentWindow:getHeight() + 8
    x = math.max(0, math.min(x, screenWidth - width))
    y = math.max(0, math.min(y, screenHeight - height))
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.parentWindow = parentWindow
    o.targetEntry = entry and {
        entryType = entry.entryType,
        fullType = entry.fullType,
        term = entry.term,
    } or nil
    o.entryColorId = entry and BoxxyQuickLoot.getHighlightColorDefinition(entry.colorId).id or nil
    o.colorPriorityIds = BoxxyQuickLoot.getSavedColorPriorityIds(parentWindow.playerObj)
    o.autoLootColorStates = BoxxyQuickLoot.getSavedAutoLootColorStates(parentWindow.playerObj)
    o.headerHeight = 34
    o.moveWithMouse = false
    o.backgroundColor = { r = 0.05, g = 0.05, b = 0.06, a = 0.96 }
    o.borderColor = { r = 0.32, g = 0.28, b = 0.16, a = 1.0 }

    return o
end

function BoxxyQuickLootWindow:updateAddTermButtonStyle(isEnabled)
    if not self.addTermButton then
        return
    end

    local button = self.addTermButton
    if isEnabled then
        button.backgroundColor.r = 0.08
        button.backgroundColor.g = 0.18
        button.backgroundColor.b = 0.08
        button.backgroundColor.a = 0.95
        button.backgroundColorMouseOver.r = 0.12
        button.backgroundColorMouseOver.g = 0.26
        button.backgroundColorMouseOver.b = 0.12
        button.backgroundColorMouseOver.a = 0.98
        button.borderColor.r = 0.3
        button.borderColor.g = 0.6
        button.borderColor.b = 0.3
        button.borderColor.a = 0.9
    else
        button.backgroundColor.r = 0.08
        button.backgroundColor.g = 0.09
        button.backgroundColor.b = 0.09
        button.backgroundColor.a = 0.72
        button.backgroundColorMouseOver.r = 0.08
        button.backgroundColorMouseOver.g = 0.09
        button.backgroundColorMouseOver.b = 0.09
        button.backgroundColorMouseOver.a = 0.72
        button.borderColor.r = 0.2
        button.borderColor.g = 0.24
        button.borderColor.b = 0.22
        button.borderColor.a = 0.65
    end
end

function BoxxyQuickLootWindow:getSortModeIndex(sortMode)
    if sortMode == "type" then
        return 2
    end
    if sortMode == "priority" then
        return 3
    end
    return 1
end

function BoxxyQuickLootWindow:getSortModeFromIndex(selectedIndex)
    if selectedIndex == 2 then
        return "type"
    end
    if selectedIndex == 3 then
        return "priority"
    end
    return "alphabetical"
end

function BoxxyQuickLootWindow:updateSortButtonStyles()
    if not self.sortModeDropdown or not self.sortDirectionButton then
        return
    end

    local activeBackground = { r = 0.18, g = 0.18, b = 0.18, a = 0.94 }
    local activeHover = { r = 0.22, g = 0.22, b = 0.22, a = 0.98 }
    local activeBorder = { r = 0.46, g = 0.46, b = 0.46, a = 0.94 }
    local textColor = { r = 0.96, g = 0.94, b = 0.9, a = 1.0 }

    BoxxyQuickLoot.applyButtonPalette(
        self.sortDirectionButton,
        activeBackground,
        activeHover,
        activeBorder,
        textColor
    )

    self.sortModeDropdown.backgroundColor = self.sortModeDropdown.backgroundColor or {}
    self.sortModeDropdown.borderColor = self.sortModeDropdown.borderColor or {}
    self.sortModeDropdown.textColor = self.sortModeDropdown.textColor or {}
    BoxxyQuickLoot.copyColor(self.sortModeDropdown.backgroundColor, activeBackground)
    BoxxyQuickLoot.copyColor(self.sortModeDropdown.borderColor, activeBorder)
    BoxxyQuickLoot.copyColor(self.sortModeDropdown.textColor, textColor)
    self.sortModeDropdown.selected = self:getSortModeIndex(self.sortMode)

    if self.colorSettingsButton then
        BoxxyQuickLoot.applyButtonPalette(
            self.colorSettingsButton,
            activeBackground,
            activeHover,
            activeBorder,
            textColor
        )
    end

    -- Direction button uses icon, no text
    if self.sortDirectionButton.setTitle then
        self.sortDirectionButton:setTitle("")
    else
        self.sortDirectionButton.title = ""
    end
    self.sortDirectionButton.sortDirection = self.sortDirection
end

function BoxxyQuickLootWindow:updateDisabledLastCheckboxStyle()
    if not self.disabledLastCheckboxButton then
        return
    end

    local button = self.disabledLastCheckboxButton
    button.backgroundColor = button.backgroundColor or {}
    button.backgroundColorMouseOver = button.backgroundColorMouseOver or {}
    button.borderColor = button.borderColor or {}

    if self.disabledItemsLast then
        button.backgroundColor.r = 0.14
        button.backgroundColor.g = 0.18
        button.backgroundColor.b = 0.12
        button.backgroundColor.a = 0.76
        button.backgroundColorMouseOver.r = 0.18
        button.backgroundColorMouseOver.g = 0.22
        button.backgroundColorMouseOver.b = 0.15
        button.backgroundColorMouseOver.a = 0.88
        button.borderColor.r = 0.42
        button.borderColor.g = 0.56
        button.borderColor.b = 0.34
        button.borderColor.a = 0.88
    else
        button.backgroundColor.r = 0.1
        button.backgroundColor.g = 0.1
        button.backgroundColor.b = 0.11
        button.backgroundColor.a = 0.68
        button.backgroundColorMouseOver.r = 0.14
        button.backgroundColorMouseOver.g = 0.14
        button.backgroundColorMouseOver.b = 0.15
        button.backgroundColorMouseOver.a = 0.82
        button.borderColor.r = 0.28
        button.borderColor.g = 0.3
        button.borderColor.b = 0.28
        button.borderColor.a = 0.74
    end
end

function BoxxyQuickLootWindow:toggleSortDirection()
    if self.sortDirection == "desc" then
        self.sortDirection = "asc"
    else
        self.sortDirection = "desc"
    end

    BoxxyQuickLoot.saveWindowSettings(self.playerObj, self.sortMode, self.sortDirection, self.disabledItemsLast)
    self:updateSortButtonStyles()
    self:refreshList()
end

function BoxxyQuickLootWindow:onSortModeChanged()
    local nextSortMode = self:getSortModeFromIndex(self.sortModeDropdown.selected)
    if self.sortMode == nextSortMode then
        self:updateSortButtonStyles()
        return
    end

    self.sortMode = nextSortMode
    BoxxyQuickLoot.saveWindowSettings(self.playerObj, self.sortMode, self.sortDirection, self.disabledItemsLast)
    self:updateSortButtonStyles()
    self:refreshList()
end

function BoxxyQuickLootWindow:onSortDirectionClicked()
    self:toggleSortDirection()
end

function BoxxyQuickLootWindow:onDisabledLastClicked()
    self.disabledItemsLast = not self.disabledItemsLast
    BoxxyQuickLoot.saveWindowSettings(self.playerObj, self.sortMode, self.sortDirection, self.disabledItemsLast)
    self:updateDisabledLastCheckboxStyle()
    self:refreshList()
end

function BoxxyQuickLootWindow:onColorSettingsClicked()
    self:openColorSettingsWindow()
end

function BoxxyQuickLootWindow:titleBarHeight()
    return self.headerHeight or 38
end

function BoxxyQuickLootWindow:getCloseIconBounds()
    local iconX = self.width - CLOSE_ICON_SIZE - 12
    local iconY = 10
    return iconX, iconY, CLOSE_ICON_SIZE, CLOSE_ICON_SIZE
end

function BoxxyQuickLootWindow:getHelpIconBounds()
    local closeX = self.width - CLOSE_ICON_SIZE - 12
    local iconX = closeX - HELP_ICON_SIZE - 10
    local iconY = 12
    return iconX, iconY, HELP_ICON_SIZE, HELP_ICON_SIZE
end

function BoxxyQuickLootWindow:hideHelpTooltip()
    if self.helpTooltip and self.helpTooltip:getIsVisible() then
        self.helpTooltip:setVisible(false)
        self.helpTooltip:removeFromUIManager()
    end
end

function BoxxyQuickLootWindow:updateHelpTooltip()
    local helpX, helpY, helpW, helpH = self:getHelpIconBounds()
    local mouseX = getMouseX() - self:getAbsoluteX()
    local mouseY = getMouseY() - self:getAbsoluteY()
    local isHoveringHelp = mouseX >= helpX and mouseX <= (helpX + helpW) and mouseY >= helpY and
        mouseY <= (helpY + helpH)

    if not isHoveringHelp then
        self:hideHelpTooltip()
        return
    end

    if not self.helpTooltip then
        self.helpTooltip = ISToolTip:new()
        self.helpTooltip:setOwner(self)
        self.helpTooltip:setVisible(false)
        self.helpTooltip:setAlwaysOnTop(true)
        self.helpTooltip.maxLineWidth = 400
    end

    if not self.helpTooltip:getIsVisible() then
        self.helpTooltip:addToUIManager()
        self.helpTooltip:setVisible(true)
    end

    self.helpTooltip.description = BoxxyQuickLoot.getMatchSyntaxTooltip()
    self.helpTooltip:setX(getMouseX() + 18)
    self.helpTooltip:setY(getMouseY() + 18)
end

function BoxxyQuickLootWindow:applyWindowSkin()
    BoxxyQuickLoot.copyColor(self.backgroundColor, BoxxyQuickLootWindow.frameBackground)
    BoxxyQuickLoot.copyColor(self.borderColor, BoxxyQuickLootWindow.frameBorder)

    if self.termEntry then
        self.termEntry.backgroundColor = self.termEntry.backgroundColor or {}
        self.termEntry.borderColor = self.termEntry.borderColor or {}
        self.termEntry.textColor = self.termEntry.textColor or {}
        BoxxyQuickLoot.copyColor(self.termEntry.backgroundColor, BoxxyQuickLootWindow.surfaceBackground)
        BoxxyQuickLoot.copyColor(self.termEntry.borderColor, BoxxyQuickLootWindow.surfaceBorder)
        BoxxyQuickLoot.copyColor(self.termEntry.textColor, BoxxyQuickLootWindow.titleText)
    end

    if self.listbox then
        self.listbox.backgroundColor = self.listbox.backgroundColor or {}
        self.listbox.borderColor = self.listbox.borderColor or {}
        BoxxyQuickLoot.copyColor(self.listbox.backgroundColor, BoxxyQuickLootWindow.surfaceBackground)
        BoxxyQuickLoot.copyColor(self.listbox.borderColor, BoxxyQuickLootWindow.surfaceBorder)

        if self.listbox.vscroll then
            self.listbox.vscroll.backgroundColor = self.listbox.vscroll.backgroundColor or {}
            self.listbox.vscroll.borderColor = self.listbox.vscroll.borderColor or {}
            BoxxyQuickLoot.copyColor(self.listbox.vscroll.backgroundColor, BoxxyQuickLootWindow.scrollbarBackground)
            BoxxyQuickLoot.copyColor(self.listbox.vscroll.borderColor, BoxxyQuickLootWindow.scrollbarBorder)
        end
    end
end

function BoxxyQuickLootWindow:prerender()
    ISPanel.prerender(self)

    local titleBarHeight = self:titleBarHeight()
    local contentX = 12
    local contentY = titleBarHeight + 8
    local contentW = self.width - 24
    local contentH = self.height - contentY - 12

    self:drawRect(0, 0, self.width, self.height,
        BoxxyQuickLootWindow.frameBackground.a,
        BoxxyQuickLootWindow.frameBackground.r,
        BoxxyQuickLootWindow.frameBackground.g,
        BoxxyQuickLootWindow.frameBackground.b)
    self:drawRectBorder(0, 0, self.width, self.height,
        BoxxyQuickLootWindow.frameBorder.a,
        BoxxyQuickLootWindow.frameBorder.r,
        BoxxyQuickLootWindow.frameBorder.g,
        BoxxyQuickLootWindow.frameBorder.b)
    self:drawRect(1, 1, self.width - 2, titleBarHeight,
        BoxxyQuickLootWindow.titleBarBackground.a,
        BoxxyQuickLootWindow.titleBarBackground.r,
        BoxxyQuickLootWindow.titleBarBackground.g,
        BoxxyQuickLootWindow.titleBarBackground.b)
    self:drawRectBorder(1, 1, self.width - 2, titleBarHeight,
        BoxxyQuickLootWindow.titleBarBorder.a,
        BoxxyQuickLootWindow.titleBarBorder.r,
        BoxxyQuickLootWindow.titleBarBorder.g,
        BoxxyQuickLootWindow.titleBarBorder.b)
    self:drawRect(contentX, contentY, contentW, contentH, 0.16, 0.1, 0.1, 0.12)
    self:drawRectBorder(contentX, contentY, contentW, contentH, 0.2, 0.36, 0.32, 0.2)
    self:drawText(self.title or BoxxyQuickLoot.windowTitle, 10,
        math.floor((titleBarHeight - FONT_HGT_MEDIUM) / 2) + 1,
        BoxxyQuickLootWindow.titleText.r,
        BoxxyQuickLootWindow.titleText.g,
        BoxxyQuickLootWindow.titleText.b,
        BoxxyQuickLootWindow.titleText.a,
        UIFont.Medium)
    self:drawText("Loot Matches", contentX + 8, contentY + 4,
        BoxxyQuickLootWindow.sectionText.r,
        BoxxyQuickLootWindow.sectionText.g,
        BoxxyQuickLootWindow.sectionText.b,
        BoxxyQuickLootWindow.sectionText.a,
        UIFont.Small)
    self:drawRect(contentX + 8, contentY + 22, contentW - 16, 1, 0.16, 0.38, 0.34, 0.2)
end

function BoxxyQuickLootWindow:render()
    ISPanel.render(self)

    local mouseX = getMouseX() - self:getAbsoluteX()
    local mouseY = getMouseY() - self:getAbsoluteY()
    local helpX, helpY, helpW, helpH = self:getHelpIconBounds()
    local isHelpHovered = mouseX >= helpX and mouseX <= (helpX + helpW) and mouseY >= helpY and mouseY <=
        (helpY + helpH)
    local closeX, closeY, closeW, closeH = self:getCloseIconBounds()
    local isCloseHovered = mouseX >= closeX and mouseX <= (closeX + closeW) and mouseY >= closeY and mouseY <=
        (closeY + closeH)

    if HELP_ICON then
        self:drawTextureScaled(HELP_ICON, helpX, helpY, helpW, helpH, isHelpHovered and 1 or 0.88, 1, 1, 1)
    else
        self:drawText("?", helpX + 4, helpY - 1, 0.95, 0.9, 0.88, isHelpHovered and 1 or 0.88, UIFont.Medium)
    end

    if isCloseHovered and CLOSE_ICON_HOVER then
        self:drawTextureScaled(CLOSE_ICON_HOVER, closeX, closeY, closeW, closeH, 1, 1, 1, 1)
    elseif CLOSE_ICON then
        self:drawTextureScaled(CLOSE_ICON, closeX, closeY, closeW, closeH, 1, 1, 1, 1)
    else
        self:drawText("X", closeX + 4, closeY - 1, 0.95, 0.9, 0.88, 1, UIFont.Medium)
    end

    self:drawSortDirectionIcon()

    if self.disabledLastCheckboxButton then
        local button = self.disabledLastCheckboxButton
        local checkboxSize = math.min(button:getHeight() - 8, 16)
        local checkboxX = button:getX() + 8
        local checkboxY = button:getY() + math.floor((button:getHeight() - checkboxSize) / 2)
        local isHovered = mouseX >= button:getX() and mouseX <= (button:getX() + button:getWidth()) and
            mouseY >= button:getY() and
            mouseY <= (button:getY() + button:getHeight())
        local borderAlpha = isHovered and 0.95 or 0.78
        local borderColor = self.disabledItemsLast and { r = 0.72, g = 0.88, b = 0.48 } or
            { r = 0.58, g = 0.58, b = 0.56 }
        local fillAlpha = self.disabledItemsLast and 0.92 or 0.38

        self:drawRect(checkboxX, checkboxY, checkboxSize, checkboxSize, fillAlpha, 0.08, 0.09, 0.08)
        self:drawRectBorder(checkboxX, checkboxY, checkboxSize, checkboxSize, borderAlpha, borderColor.r, borderColor.g,
            borderColor.b)
        if self.disabledItemsLast then
            self:drawTextCentre("x", checkboxX + (checkboxSize / 2),
                checkboxY + math.floor((checkboxSize - FONT_HGT_SMALL) / 2) - 1,
                0.95, 0.95, 0.95, 1.0, UIFont.Small)
        end

        self:drawText("Disabled to bottom", checkboxX + checkboxSize + 8,
            button:getY() + math.floor((button:getHeight() - FONT_HGT_SMALL) / 2),
            0.92, 0.9, 0.84, 1.0, UIFont.Small)
    end

    local gripSize = 12
    local x = self.width - gripSize - 3
    local y = self.height - gripSize - 3
    self:drawRectBorder(x, y, gripSize, gripSize, 0.9, 0.45, 0.45, 0.45)
    self:drawRect(x + 3, y + 8, 2, 2, 0.7, 0.72, 0.72, 0.72)
    self:drawRect(x + 6, y + 5, 2, 2, 0.58, 0.62, 0.62, 0.62)
    self:drawRect(x + 9, y + 2, 2, 2, 0.5, 0.56, 0.56, 0.56)
end

function BoxxyQuickLootWindow:drawSortDirectionIcon()
    if not self.sortDirectionButton or not SORT_DIRECTION_ICON then
        return
    end

    local button = self.sortDirectionButton
    local btnX = button:getX()
    local btnY = button:getY()
    local btnW = button:getWidth()
    local btnH = button:getHeight()

    -- Center the icon in the button
    local iconSize = math.min(btnW - 4, btnH - 4)
    local iconX = btnX + (btnW - iconSize) / 2
    local iconY = btnY + (btnH - iconSize) / 2

    -- Draw icon, flipped if descending
    if self.sortDirection == "desc" then
        -- Draw upside down by flipping vertically
        self:drawTextureScaled(SORT_DIRECTION_ICON, iconX, iconY + iconSize, iconSize, -iconSize, 1, 1, 1, 1)
    else
        self:drawTextureScaled(SORT_DIRECTION_ICON, iconX, iconY, iconSize, iconSize, 1, 1, 1, 1)
    end
end

function BoxxyQuickLootWindow:onCustomCloseButtonClicked()
    self:close()
end

function BoxxyQuickLootWindow:isOnResizeGrip(x, y)
    local gripSize = 16
    return x >= self.width - gripSize and y >= self.height - gripSize
end

function BoxxyQuickLootWindow:onMouseDown(x, y)
    local closeX, closeY, closeW, closeH = self:getCloseIconBounds()
    if x >= closeX and x <= (closeX + closeW) and y >= closeY and y <= (closeY + closeH) then
        self:onCustomCloseButtonClicked()
        return true
    end

    if self:isOnResizeGrip(x, y) then
        self.isResizingCustom = true
        return true
    end

    if y <= self:titleBarHeight() then
        self.moveWithMouse = true
        self.dragStartX = x
        self.dragStartY = y
        return true
    end

    return ISPanel.onMouseDown(self, x, y)
end

function BoxxyQuickLootWindow:onMouseMove(dx, dy)
    if self.isResizingCustom then
        local minWidth = 520
        local minHeight = 300
        self:setWidth(math.max(minWidth, self.width + dx))
        self:setHeight(math.max(minHeight, self.height + dy))
        return true
    end

    if self.moveWithMouse then
        self:setX(self:getX() + dx)
        self:setY(self:getY() + dy)
        return true
    end

    return ISPanel.onMouseMove(self, dx, dy)
end

function BoxxyQuickLootWindow:onMouseMoveOutside(dx, dy)
    if self.isResizingCustom then
        local minWidth = 520
        local minHeight = 300
        self:setWidth(math.max(minWidth, self.width + dx))
        self:setHeight(math.max(minHeight, self.height + dy))
        return true
    end

    if self.moveWithMouse then
        self:setX(self:getX() + dx)
        self:setY(self:getY() + dy)
        return true
    end

    return ISPanel.onMouseMoveOutside(self, dx, dy)
end

function BoxxyQuickLootWindow:onMouseUp(x, y)
    self.moveWithMouse = false
    if self.isResizingCustom then
        self.isResizingCustom = false
        return true
    end
    return ISPanel.onMouseUp(self, x, y)
end

function BoxxyQuickLootWindow:onMouseUpOutside(x, y)
    self.moveWithMouse = false
    if self.isResizingCustom then
        self.isResizingCustom = false
        return true
    end
    return ISPanel.onMouseUpOutside(self, x, y)
end

function BoxxyQuickLootWindow:refreshList()
    self.listbox:clear()
    self.listbox:setScrollHeight(0)

    local entries = BoxxyQuickLoot.getSortedEntries(self.playerObj, self.sortMode, self.sortDirection,
        self.disabledItemsLast)
    if #entries == 0 then
        self.listbox:addItem("No items in the auto loot list.", { empty = true })
        return
    end

    -- If there's a highlighted term, move it to the front
    if self.highlightedTerm then
        local highlightedIndex = nil
        for index, entry in ipairs(entries) do
            if entry.entryType == "term" and entry.term == self.highlightedTerm then
                highlightedIndex = index
                break
            end
        end

        if highlightedIndex then
            local highlightedEntry = table.remove(entries, highlightedIndex)
            table.insert(entries, 1, highlightedEntry)
        end
    end

    for index, entry in ipairs(entries) do
        entry.rowIndex = index
        self.listbox:addItem(entry.name, entry)
    end
end

function BoxxyQuickLootWindow:onListMouseDown(x, y)
    if #self.items == 0 then
        return
    end

    local row = self:rowAt(x, y)
    if row < 1 or row > #self.items then
        return
    end

    local entry = self.items[row].item
    if entry and not entry.empty then
        local colorX, toggleX, removeX = BoxxyQuickLoot.getListButtonPositions(self)
        if x >= colorX and x <= colorX + BoxxyQuickLootWindow.colorButtonWidth then
            self.parentWindow:openColorPicker(entry)
            return
        end

        if x >= toggleX and x <= toggleX + BoxxyQuickLootWindow.toggleButtonWidth then
            BoxxyQuickLoot.toggleEntryEnabled(self.parentWindow.playerObj, entry)
            return
        end

        if x >= removeX and x <= removeX + BoxxyQuickLootWindow.removeButtonWidth then
            if entry.entryType == "term" then
                BoxxyQuickLoot.removeSearchTerm(self.parentWindow.playerObj, entry.term)
            else
                BoxxyQuickLoot.removeFullType(self.parentWindow.playerObj, entry.fullType)
            end
            return
        end
    end

    return ISScrollingListBox.onMouseDown(self, x, y)
end

function BoxxyQuickLootWindow:onListMouseMove(dx, dy)
    self.hoverX = self:getMouseX()
    self.hoverY = self:getMouseY()
    return ISScrollingListBox.onMouseMove(self, dx, dy)
end

function BoxxyQuickLootWindow:onListMouseMoveOutside(dx, dy)
    self.hoverX = nil
    self.hoverY = nil
    return ISScrollingListBox.onMouseMoveOutside(self, dx, dy)
end

function BoxxyQuickLootWindow:doDrawItem(y, item, alt)
    local entry = item.item
    local isHoveringRow = self.hoverY ~= nil and self.hoverY >= y and self.hoverY <= y + item.height
    local isHighlighted = entry and entry.entryType == "term" and self.parentWindow.highlightedTerm == entry.term
    local isStripedRow = entry and entry.rowIndex and entry.rowIndex % 2 == 0
    local entryColorDef = entry and BoxxyQuickLoot.getHighlightColorDefinition(entry.colorId) or
        BoxxyQuickLoot.getHighlightColorDefinition(BoxxyQuickLoot.highlightColorIdDefault)
    if isStripedRow then
        self:drawRect(0, y, self:getWidth(), item.height, 0.1, 0.15, 0.15, 0.17)
    else
        self:drawRect(0, y, self:getWidth(), item.height, 0.06, 0.11, 0.11, 0.13)
    end

    if isHighlighted then
        self:drawRect(0, y, self:getWidth(), item.height, 0.14, entryColorDef.preview.r, entryColorDef.preview.g,
            entryColorDef.preview.b)
        self:drawRectBorder(0, y, self:getWidth(), item.height, 0.32, entryColorDef.marker.r,
            entryColorDef.marker.g, entryColorDef.marker.b)
    elseif isHoveringRow then
        self:drawRect(0, y, self:getWidth(), item.height, 0.08, 1, 1, 1)
        self:drawRectBorder(0, y, self:getWidth(), item.height, 0.2, 0.88, 0.88, 0.88)
    end

    if entry and entry.empty then
        self:drawText(entry.text or item.text, 10, y + (item.height - FONT_HGT_SMALL) / 2, 0.6, 0.58, 0.5, 1.0,
            UIFont.Small)
        return y + item.height
    end

    local colorX, toggleX, buttonX = BoxxyQuickLoot.getListButtonPositions(self)
    local buttonY = y + 4
    local buttonH = item.height - 8
    local toggleLabel = entry.enabled == false and "Enable" or "Disable"
    local textAlpha = entry.enabled == false and 0.45 or 0.9
    local statusText = entry.enabled == false and " (Disabled)" or ""
    local textX = 10
    local isHoveringColor = isHoveringRow and self.hoverX ~= nil and self.hoverX >= colorX and self.hoverX <= colorX +
        BoxxyQuickLootWindow.colorButtonWidth
    local isHoveringToggle = isHoveringRow and self.hoverX ~= nil and self.hoverX >= toggleX and self.hoverX <= toggleX +
        BoxxyQuickLootWindow.toggleButtonWidth
    local isHoveringRemove = isHoveringRow and self.hoverX ~= nil and self.hoverX >= buttonX and self.hoverX <= buttonX +
        BoxxyQuickLootWindow.removeButtonWidth
    local toggleBackgroundA, toggleBackgroundR, toggleBackgroundG, toggleBackgroundB, toggleBorderA, toggleBorderR,
    toggleBorderG, toggleBorderB = BoxxyQuickLoot.getRowButtonColors("toggle", isHoveringToggle, entry.enabled == false)
    local removeBackgroundA, removeBackgroundR, removeBackgroundG, removeBackgroundB, removeBorderA, removeBorderR,
    removeBorderG, removeBorderB = BoxxyQuickLoot.getRowButtonColors("remove", isHoveringRemove, false)
    local swatchInset = isHoveringColor and 3 or 6

    self:drawRectBorder(0, y, self:getWidth(), item.height, 0.18, 0.38, 0.34, 0.18)

    if entry.entryType == "item" then
        local iconTexture = BoxxyQuickLoot.getTextureFromPath(entry.icon)
        if iconTexture and self.drawTextureScaledAspect2 then
            local iconSize = math.min(item.height - 6, 20)
            local iconY = y + math.floor((item.height - iconSize) / 2)
            self:drawTextureScaledAspect2(iconTexture, textX, iconY, iconSize, iconSize, 1.0, 1.0, 1.0, textAlpha)
            textX = textX + iconSize + 6
        end
    end

    self:drawText(item.text .. statusText, textX, y + (item.height - FONT_HGT_SMALL) / 2, textAlpha, textAlpha,
        textAlpha,
        1.0, UIFont.Small)
    if isHoveringColor then
        self:drawRect(colorX + 1, buttonY + 1, BoxxyQuickLootWindow.colorButtonWidth - 2, buttonH - 2,
            math.min(entryColorDef.fill.a + 0.08, 0.22), entryColorDef.fill.r, entryColorDef.fill.g,
            entryColorDef.fill.b)
        self:drawRectBorder(colorX + 1, buttonY + 1, BoxxyQuickLootWindow.colorButtonWidth - 2, buttonH - 2,
            math.min(entryColorDef.marker.a + 0.15, 0.95), entryColorDef.marker.r, entryColorDef.marker.g,
            entryColorDef.marker.b)
    end
    self:drawRect(colorX + swatchInset, buttonY + 4, BoxxyQuickLootWindow.colorButtonWidth - (swatchInset * 2),
        buttonH - 8,
        entryColorDef.preview.a, entryColorDef.preview.r, entryColorDef.preview.g, entryColorDef.preview.b)
    self:drawRectBorder(colorX + swatchInset, buttonY + 4,
        BoxxyQuickLootWindow.colorButtonWidth - (swatchInset * 2), buttonH - 8,
        isHoveringColor and math.min(entryColorDef.marker.a + 0.18, 1.0) or 0.72,
        isHoveringColor and entryColorDef.marker.r or 0.95,
        isHoveringColor and entryColorDef.marker.g or 0.95,
        isHoveringColor and entryColorDef.marker.b or 0.95)
    self:drawRect(toggleX, buttonY, BoxxyQuickLootWindow.toggleButtonWidth, buttonH,
        toggleBackgroundA, toggleBackgroundR, toggleBackgroundG, toggleBackgroundB)
    self:drawRectBorder(toggleX, buttonY, BoxxyQuickLootWindow.toggleButtonWidth, buttonH, toggleBorderA, toggleBorderR,
        toggleBorderG, toggleBorderB)
    self:drawTextCentre(toggleLabel, toggleX + BoxxyQuickLootWindow.toggleButtonWidth / 2,
        y + (item.height - FONT_HGT_SMALL) / 2, 1.0, 0.9, 0.9, 0.9, UIFont.Small)
    self:drawRect(buttonX, buttonY, BoxxyQuickLootWindow.removeButtonWidth, buttonH, removeBackgroundA, removeBackgroundR,
        removeBackgroundG, removeBackgroundB)
    if isHoveringRemove and CLOSE_ICON_HOVER then
        self:drawTextureScaled(CLOSE_ICON_HOVER, buttonX + 4, buttonY + 3, BoxxyQuickLootWindow.removeButtonWidth - 8,
            buttonH - 6, 1, 1, 1, 1)
    elseif CLOSE_ICON then
        self:drawTextureScaled(CLOSE_ICON, buttonX + 4, buttonY + 3, BoxxyQuickLootWindow.removeButtonWidth - 8,
            buttonH - 6, 1, 1, 1, 1)
    else
        self:drawTextCentre("X", buttonX + BoxxyQuickLootWindow.removeButtonWidth / 2,
            y + (item.height - FONT_HGT_SMALL) / 2, 1.0, 0.92, 0.92, 0.92, UIFont.Small)
    end

    return y + item.height
end

function BoxxyQuickLootWindow:update()
    ISPanel.update(self)

    if not self.playerObj then
        self:hideHelpTooltip()
        self:close()
        return
    end

    self:updateHelpTooltip()

    if self.addTermButton and self.termEntry and self.termEntry.getInternalText then
        local hasText = BoxxyQuickLoot.normalizeSearchTerm(self.termEntry:getInternalText()) ~= nil
        self.addTermButton:setEnable(hasText)
        self:updateAddTermButtonStyle(hasText)
    end
end

function BoxxyQuickLootWindow:close()
    self:hideHelpTooltip()
    self.highlightedTerm = nil
    if self.colorPickerWindow then
        self.colorPickerWindow:close()
        self.colorPickerWindow = nil
    end
    if BoxxyQuickLoot.windows then
        BoxxyQuickLoot.windows[self.playerNum] = nil
    end
    self:removeFromUIManager()
end

function BoxxyQuickLootWindow:openColorPicker(entry)
    if not entry or entry.empty then
        return
    end

    self:openColorSettingsWindow(entry)
end

function BoxxyQuickLootWindow:openColorSettingsWindow(entry)
    if entry and entry.empty then
        return
    end

    if self.colorPickerWindow then
        self.colorPickerWindow:close()
    end

    self.colorPickerWindow = BoxxyQuickLootColorPickerWindow:new(self, entry)
    self.colorPickerWindow:initialise()
    self.colorPickerWindow:instantiate()
    if #self.colorPickerWindow.children == 0 then
        self.colorPickerWindow:createChildren()
    end
    self.colorPickerWindow:addToUIManager()
    self.colorPickerWindow:setVisible(true)
    self.colorPickerWindow:bringToTop()
end

function BoxxyQuickLootWindow:addSearchTermFromInput()
    local term = self.termEntry and self.termEntry:getInternalText() or nil
    if BoxxyQuickLoot.addSearchTerm(self.playerObj, term) then
        self.termEntry:setText("")
        self.termEntry:focus()
        self:refreshList()
    end
end

function BoxxyQuickLootWindow:onHelpButtonClicked()
end

function BoxxyQuickLootWindow:initialise()
    ISPanel.initialise(self)
end

function BoxxyQuickLootWindow:createChildren()
    ISPanel.createChildren(self)

    local padding = 10
    local titleBarHeight = self:titleBarHeight()
    local inputHeight = FONT_HGT_SMALL + 12
    local buttonWidth = BoxxyQuickLootWindow.addTermButtonWidth
    local sortButtonGap = 6
    local sortRowY = titleBarHeight + padding + inputHeight + padding
    local sortRowX = padding

    self.termEntry = ISTextEntryBox:new("", padding, titleBarHeight + padding,
        self.width - padding * 3 - buttonWidth, inputHeight)
    self.termEntry:initialise()
    self.termEntry:instantiate()
    self.termEntry:setAnchorLeft(true)
    self.termEntry:setAnchorRight(true)
    self.termEntry:setAnchorTop(true)
    self.termEntry:setOnlyNumbers(false)
    self.termEntry:setMaxLines(1)
    self.termEntry:setPlaceholderText('Add match, e.g. "chips" or "baseball -bat"')
    self.termEntry.onCommandEntered = function(entry)
        entry.parentWindow:addSearchTermFromInput()
    end
    self.termEntry.parentWindow = self
    self:addChild(self.termEntry)

    self.addTermButton = ISButton:new(self.termEntry:getRight() + padding, self.termEntry.y, buttonWidth, inputHeight,
        "Add Match", self, BoxxyQuickLootWindow.addSearchTermFromInput)
    self.addTermButton:initialise()
    self.addTermButton:instantiate()
    self.addTermButton:setAnchorLeft(false)
    self.addTermButton:setAnchorRight(true)
    self.addTermButton:setAnchorTop(true)
    self:addChild(self.addTermButton)
    self:updateAddTermButtonStyle(false)

    self.sortModeDropdown = ISComboBox:new(sortRowX, sortRowY, BoxxyQuickLootWindow.sortModeButtonWidth, inputHeight,
        self, BoxxyQuickLootWindow.onSortModeChanged)
    self.sortModeDropdown:initialise()
    self.sortModeDropdown:instantiate()
    self.sortModeDropdown:setAnchorLeft(true)
    self.sortModeDropdown:setAnchorRight(false)
    self.sortModeDropdown:setAnchorTop(true)
    self.sortModeDropdown:addOption("Alphabetical")
    self.sortModeDropdown:addOption("Type")
    self.sortModeDropdown:addOption("Priority")
    self:addChild(self.sortModeDropdown)

    self.sortDirectionButton = ISButton:new(self.sortModeDropdown:getRight() + sortButtonGap, sortRowY,
        BoxxyQuickLootWindow.sortDirectionButtonWidth, inputHeight, "▲", self,
        BoxxyQuickLootWindow.onSortDirectionClicked)
    self.sortDirectionButton:initialise()
    self.sortDirectionButton:instantiate()
    self.sortDirectionButton:setAnchorLeft(true)
    self.sortDirectionButton:setAnchorRight(false)
    self.sortDirectionButton:setAnchorTop(true)
    self:addChild(self.sortDirectionButton)

    self.disabledLastCheckboxButton = ISButton:new(self.sortDirectionButton:getRight() + sortButtonGap, sortRowY,
        BoxxyQuickLootWindow.disabledLastCheckboxWidth, inputHeight, "", self,
        BoxxyQuickLootWindow.onDisabledLastClicked)
    self.disabledLastCheckboxButton:initialise()
    self.disabledLastCheckboxButton:instantiate()
    self.disabledLastCheckboxButton:setAnchorLeft(true)
    self.disabledLastCheckboxButton:setAnchorRight(false)
    self.disabledLastCheckboxButton:setAnchorTop(true)
    self:addChild(self.disabledLastCheckboxButton)

    self.colorSettingsButton = ISButton:new(self.width - padding - BoxxyQuickLootWindow.colorSettingsButtonWidth,
        sortRowY,
        BoxxyQuickLootWindow.colorSettingsButtonWidth, inputHeight, "Colors", self,
        BoxxyQuickLootWindow.onColorSettingsClicked)
    self.colorSettingsButton:initialise()
    self.colorSettingsButton:instantiate()
    self.colorSettingsButton:setAnchorLeft(false)
    self.colorSettingsButton:setAnchorRight(true)
    self.colorSettingsButton:setAnchorTop(true)
    self:addChild(self.colorSettingsButton)

    self:updateSortButtonStyles()
    self:updateDisabledLastCheckboxStyle()

    self.listbox = ISScrollingListBox:new(padding, self.sortModeDropdown:getBottom() + padding,
        self.width - padding * 2,
        self.height - titleBarHeight - padding * 4 - inputHeight * 2)
    self.listbox:initialise()
    self.listbox:instantiate()
    self.listbox:setAnchorLeft(true)
    self.listbox:setAnchorRight(true)
    self.listbox:setAnchorTop(true)
    self.listbox:setAnchorBottom(true)
    self.listbox.itemheight = FONT_HGT_SMALL + 12
    self.listbox.doDrawItem = BoxxyQuickLootWindow.doDrawItem
    self.listbox.onMouseDown = BoxxyQuickLootWindow.onListMouseDown
    self.listbox.onMouseMove = BoxxyQuickLootWindow.onListMouseMove
    self.listbox.onMouseMoveOutside = BoxxyQuickLootWindow.onListMouseMoveOutside
    self.listbox.parentWindow = self
    self:addChild(self.listbox)

    self:applyWindowSkin()

    self:refreshList()
end

function BoxxyQuickLootWindow:new(playerObj)
    local width = 580
    local height = 390
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local sortMode, sortDirection, disabledItemsLast = BoxxyQuickLoot.getSavedWindowSettings(playerObj)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.playerObj = playerObj
    o.playerNum = playerObj:getPlayerNum()
    o.title = BoxxyQuickLoot.windowTitle
    o.headerHeight = 38
    o.resizable = false
    o.moveWithMouse = false
    o.sortMode = sortMode
    o.sortDirection = sortDirection
    o.disabledItemsLast = disabledItemsLast
    o.highlightedTerm = nil
    o.colorPickerWindow = nil
    o.backgroundColor = { r = 0.12, g = 0.12, b = 0.12, a = 0.96 }
    o.borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 }

    return o
end

BoxxyQuickLoot.patchInventoryUi()
BoxxyQuickLoot.registerCleanUIHandler()
Events.OnFillInventoryObjectContextMenu.Add(BoxxyQuickLoot.onFillInventoryObjectContextMenu)
Events.OnGameBoot.Add(BoxxyQuickLoot.registerCleanUIHandler)
Events.OnGameStart.Add(BoxxyQuickLoot.attachExistingLootPages)
Events.OnKeyPressed.Add(BoxxyQuickLoot.onAutoLootKeyPressed)
