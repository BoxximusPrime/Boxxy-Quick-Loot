---@diagnostic disable: undefined-global

require "ISUI/ISButton"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISInventoryPage"
require "ISUI/ISInventoryPane"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"

BoxxyQuickLoot = BoxxyQuickLoot or {}
BoxxyQuickLoot.modDataKey = "BoxxyQuickLoot"
BoxxyQuickLoot.windowTitle = "Quick Loot List"
BoxxyQuickLoot.windows = BoxxyQuickLoot.windows or {}

if not BoxxyQuickLoot.options and PZAPI and PZAPI.ModOptions then
    BoxxyQuickLoot.options = PZAPI.ModOptions:create("BoxxyQuickLoot", "Boxxy Quick Loot")
    BoxxyQuickLoot.autoLootKeyOption = BoxxyQuickLoot.options:addKeyBind(
        "BoxxyQuickLoot_triggerAutoLoot",
        "Quick Loot",
        Keyboard.KEY_NONE,
        "Trigger Quick Loot on the active loot window."
    )
end

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

BoxxyQuickLootWindow = ISCollapsableWindow:derive("BoxxyQuickLootWindow")
BoxxyQuickLootWindow.removeButtonWidth = 72
BoxxyQuickLootWindow.toggleButtonWidth = 72
BoxxyQuickLootWindow.addTermButtonWidth = 110
BoxxyQuickLootWindow.actionButtonGap = 8
BoxxyQuickLootWindow.actionRightPadding = 28
BoxxyQuickLootWindow.helpButtonSize = 18
BoxxyQuickLootWindow.frameBackground = { r = 0.12, g = 0.12, b = 0.12, a = 0.96 }
BoxxyQuickLootWindow.frameBorder = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 }
BoxxyQuickLootWindow.titleBarBackground = { r = 0.16, g = 0.16, b = 0.16, a = 0.98 }
BoxxyQuickLootWindow.titleBarBorder = { r = 0.34, g = 0.34, b = 0.34, a = 0.9 }
BoxxyQuickLootWindow.titleText = { r = 0.9, g = 0.9, b = 0.9, a = 1.0 }
BoxxyQuickLootWindow.surfaceBackground = { r = 0.15, g = 0.15, b = 0.15, a = 0.92 }
BoxxyQuickLootWindow.surfaceBorder = { r = 0.32, g = 0.32, b = 0.32, a = 0.86 }
BoxxyQuickLootWindow.scrollbarBackground = { r = 0.18, g = 0.18, b = 0.18, a = 0.92 }
BoxxyQuickLootWindow.scrollbarBorder = { r = 0.36, g = 0.36, b = 0.36, a = 0.9 }

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

function BoxxyQuickLoot.saveList(playerObj)
    if not playerObj then
        return
    end

    if isClient() and playerObj.transmitModData then
        playerObj:transmitModData()
    end

    BoxxyQuickLoot.refreshWindow(playerObj)
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

    if type(value) == "table" then
        name = value.name or value.label or fallbackName
        enabled = value.enabled ~= false
        icon = value.icon
    elseif type(value) == "string" then
        name = value
    elseif value == false then
        enabled = false
    end

    return name, enabled, icon
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

    local name, _, icon = BoxxyQuickLoot.getStoredEntryInfo(store[fullType], BoxxyQuickLoot.getDisplayName(fullType))
    store[fullType] = {
        name = name,
        enabled = enabled ~= false,
        icon = icon,
    }
    BoxxyQuickLoot.saveList(playerObj)
end

function BoxxyQuickLoot.setSearchTermEnabled(playerObj, term, enabled)
    local normalizedTerm = BoxxyQuickLoot.normalizeSearchTerm(term)
    local terms = BoxxyQuickLoot.getTermStore(playerObj)
    if not normalizedTerm or not terms or terms[normalizedTerm] == nil then
        return
    end

    local label = BoxxyQuickLoot.getStoredEntryInfo(terms[normalizedTerm], normalizedTerm)
    terms[normalizedTerm] = {
        label = label,
        enabled = enabled ~= false,
    }
    BoxxyQuickLoot.saveList(playerObj)
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

function BoxxyQuickLoot.getSortedEntries(playerObj)
    local store = BoxxyQuickLoot.getListStore(playerObj)
    local terms = BoxxyQuickLoot.getTermStore(playerObj)
    local entries = {}

    if not store and not terms then
        return entries
    end

    if store then
        for fullType, value in pairs(store) do
            local name, enabled, icon = BoxxyQuickLoot.getStoredEntryInfo(value, BoxxyQuickLoot.getDisplayName(fullType))
            table.insert(entries, {
                entryType = "item",
                fullType = fullType,
                name = name or BoxxyQuickLoot.getDisplayName(fullType),
                enabled = enabled,
                icon = icon,
            })
        end
    end

    if terms then
        for term, value in pairs(terms) do
            local label, enabled = BoxxyQuickLoot.getStoredEntryInfo(value, term)
            table.insert(entries, {
                entryType = "term",
                term = term,
                name = BoxxyQuickLoot.getTermLabel(label or term),
                rawName = label or term,
                enabled = enabled,
            })
        end
    end

    table.sort(entries, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
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
        if BoxxyQuickLoot.isTracked(playerObj, item) then
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
        if BoxxyQuickLoot.isTracked(playerObj, item) then
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

    for _, item in ipairs(actualItems) do
        if BoxxyQuickLoot.isExactTracked(playerObj, item) then
            anyTracked = true
        else
            anyUntracked = true
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
        if BoxxyQuickLoot.isTracked(playerObj, item) then
            local top = (index - 1) * pane.itemHgt + pane.headerHgt
            local scrolledTop = top + yScroll
            if scrolledTop + pane.itemHgt >= 0 and scrolledTop <= pane:getHeight() then
                pane:drawRect(pane.column2, top, rowWidth, pane.itemHgt, 0.08, 0.18, 0.75, 0.18)
                pane:drawRect(1, top, 4, pane.itemHgt, 0.65, 0.18, 0.9, 0.18)
                pane:drawRectBorder(pane.column2, top, rowWidth, pane.itemHgt, 0.25, 0.18, 0.9, 0.18)
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

    for _, entry in ipairs(pane.itemslist) do
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

    table.wipe(pane.itemslist)

    for _, entry in ipairs(searchMatches) do
        table.insert(pane.itemslist, entry)
    end

    for _, entry in ipairs(trackedEntries) do
        table.insert(pane.itemslist, entry)
    end

    for _, entry in ipairs(otherEntries) do
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
    local buttonX = listbox:getWidth() - BoxxyQuickLootWindow.removeButtonWidth - BoxxyQuickLootWindow
        .actionRightPadding
    local toggleX = buttonX - BoxxyQuickLootWindow.toggleButtonWidth - BoxxyQuickLootWindow.actionButtonGap
    return toggleX, buttonX
end

function BoxxyQuickLoot.getRowButtonColors(buttonType, isHovered, isDisabledAction)
    if buttonType == "remove" then
        if isHovered then
            return 0.94, 0.45, 0.2, 0.2, 0.98, 0.85, 0.5, 0.5
        end
        return 0.9, 0.35, 0.16, 0.16, 0.94, 0.7, 0.35, 0.35
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

function BoxxyQuickLootWindow:updateAddTermButtonStyle(isEnabled)
    if not self.addTermButton then
        return
    end

    local button = self.addTermButton
    if isEnabled then
        button.backgroundColor.r = 0.24
        button.backgroundColor.g = 0.35
        button.backgroundColor.b = 0.24
        button.backgroundColor.a = 0.94
        button.backgroundColorMouseOver.r = 0.3
        button.backgroundColorMouseOver.g = 0.44
        button.backgroundColorMouseOver.b = 0.3
        button.backgroundColorMouseOver.a = 0.98
        button.borderColor.r = 0.52
        button.borderColor.g = 0.68
        button.borderColor.b = 0.52
        button.borderColor.a = 0.9
    else
        button.backgroundColor.r = 0.18
        button.backgroundColor.g = 0.18
        button.backgroundColor.b = 0.18
        button.backgroundColor.a = 0.85
        button.backgroundColorMouseOver.r = 0.18
        button.backgroundColorMouseOver.g = 0.18
        button.backgroundColorMouseOver.b = 0.18
        button.backgroundColorMouseOver.a = 0.85
        button.borderColor.r = 0.36
        button.borderColor.g = 0.36
        button.borderColor.b = 0.36
        button.borderColor.a = 0.9
    end
end

function BoxxyQuickLootWindow:applyWindowSkin()
    BoxxyQuickLoot.copyColor(self.backgroundColor, BoxxyQuickLootWindow.frameBackground)
    BoxxyQuickLoot.copyColor(self.borderColor, BoxxyQuickLootWindow.frameBorder)

    if self.titlebarbkgcolor then
        BoxxyQuickLoot.copyColor(self.titlebarbkgcolor, BoxxyQuickLootWindow.titleBarBackground)
    end

    if self.titlebarfgcolor then
        BoxxyQuickLoot.copyColor(self.titlebarfgcolor, BoxxyQuickLootWindow.titleText)
    end

    if self.helpButton then
        BoxxyQuickLoot.applyButtonPalette(self.helpButton,
            { r = 0.24, g = 0.24, b = 0.24, a = 0.92 },
            { r = 0.34, g = 0.34, b = 0.34, a = 0.98 },
            { r = 0.5, g = 0.5, b = 0.5, a = 0.9 },
            BoxxyQuickLootWindow.titleText)
    end

    if self.customCloseButton then
        BoxxyQuickLoot.applyButtonPalette(self.customCloseButton,
            { r = 0.32, g = 0.17, b = 0.17, a = 0.95 },
            { r = 0.45, g = 0.22, b = 0.22, a = 1.0 },
            { r = 0.72, g = 0.4, b = 0.4, a = 0.95 },
            BoxxyQuickLootWindow.titleText)
    end

    if self.closeButton then
        self.closeButton:setVisible(false)
        self.closeButton:setEnable(false)
    end

    if self.pinButton then
        self.pinButton:setVisible(false)
        self.pinButton:setEnable(false)
    end

    self.pin = true

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
    self:drawText(self.title or BoxxyQuickLoot.windowTitle, 10,
        math.floor((titleBarHeight - FONT_HGT_MEDIUM) / 2) + 1,
        BoxxyQuickLootWindow.titleText.r,
        BoxxyQuickLootWindow.titleText.g,
        BoxxyQuickLootWindow.titleText.b,
        BoxxyQuickLootWindow.titleText.a,
        UIFont.Medium)
end

function BoxxyQuickLootWindow:render()
    local superRender = ISCollapsableWindow.render or ISPanel.render
    if superRender then
        superRender(self)
    end
    local gripSize = 12
    local x = self.width - gripSize - 3
    local y = self.height - gripSize - 3
    self:drawRectBorder(x, y, gripSize, gripSize, 0.9, 0.45, 0.45, 0.45)
    self:drawRect(x + 3, y + 8, 2, 2, 0.7, 0.72, 0.72, 0.72)
    self:drawRect(x + 6, y + 5, 2, 2, 0.58, 0.62, 0.62, 0.62)
    self:drawRect(x + 9, y + 2, 2, 2, 0.5, 0.56, 0.56, 0.56)
end

function BoxxyQuickLootWindow:onCustomCloseButtonClicked()
    self:close()
end

function BoxxyQuickLootWindow:isOnResizeGrip(x, y)
    local gripSize = 16
    return x >= self.width - gripSize and y >= self.height - gripSize
end

function BoxxyQuickLootWindow:onMouseDown(x, y)
    if self:isOnResizeGrip(x, y) then
        self.isResizingCustom = true
        return true
    end
    return ISCollapsableWindow.onMouseDown(self, x, y)
end

function BoxxyQuickLootWindow:onMouseMove(dx, dy)
    if self.isResizingCustom then
        local minWidth = 520
        local minHeight = 300
        self:setWidth(math.max(minWidth, self.width + dx))
        self:setHeight(math.max(minHeight, self.height + dy))
        return true
    end
    return ISCollapsableWindow.onMouseMove(self, dx, dy)
end

function BoxxyQuickLootWindow:onMouseMoveOutside(dx, dy)
    if self.isResizingCustom then
        local minWidth = 520
        local minHeight = 300
        self:setWidth(math.max(minWidth, self.width + dx))
        self:setHeight(math.max(minHeight, self.height + dy))
        return true
    end
    return ISCollapsableWindow.onMouseMoveOutside(self, dx, dy)
end

function BoxxyQuickLootWindow:onMouseUp(x, y)
    if self.isResizingCustom then
        self.isResizingCustom = false
        return true
    end
    return ISCollapsableWindow.onMouseUp(self, x, y)
end

function BoxxyQuickLootWindow:onMouseUpOutside(x, y)
    if self.isResizingCustom then
        self.isResizingCustom = false
        return true
    end
    return ISCollapsableWindow.onMouseUpOutside(self, x, y)
end

function BoxxyQuickLootWindow:refreshList()
    self.listbox:clear()
    self.listbox:setScrollHeight(0)

    local entries = BoxxyQuickLoot.getSortedEntries(self.playerObj)
    if #entries == 0 then
        self.listbox:addItem("No items in the auto loot list.", { empty = true })
        return
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
        local toggleX, removeX = BoxxyQuickLoot.getListButtonPositions(self)
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
    local isStripedRow = entry and entry.rowIndex and entry.rowIndex % 2 == 0
    if isStripedRow then
        self:drawRect(0, y, self:getWidth(), item.height, 0.9, 0.09, 0.1, 0.12)
    else
        self:drawRect(0, y, self:getWidth(), item.height, 0.9, 0.13, 0.14, 0.17)
    end

    if self.items[self.selected] == item then
        self:drawRect(0, y, self:getWidth(), item.height, 0.2, 0.88, 0.82, 0.56)
    end

    if entry and entry.empty then
        self:drawText(entry.text or item.text, 10, y + (item.height - FONT_HGT_SMALL) / 2, 0.6, 0.6, 0.6, 1.0,
            UIFont.Small)
        return y + item.height
    end

    local toggleX, buttonX = BoxxyQuickLoot.getListButtonPositions(self)
    local buttonY = y + 4
    local buttonH = item.height - 8
    local toggleLabel = entry.enabled == false and "Enable" or "Disable"
    local textAlpha = entry.enabled == false and 0.45 or 0.9
    local statusText = entry.enabled == false and " (Disabled)" or ""
    local textX = 10
    local isHoveringRow = self.hoverY ~= nil and self.hoverY >= y and self.hoverY <= y + item.height
    local isHoveringToggle = isHoveringRow and self.hoverX ~= nil and self.hoverX >= toggleX and self.hoverX <= toggleX +
        BoxxyQuickLootWindow.toggleButtonWidth
    local isHoveringRemove = isHoveringRow and self.hoverX ~= nil and self.hoverX >= buttonX and self.hoverX <= buttonX +
        BoxxyQuickLootWindow.removeButtonWidth
    local toggleBackgroundA, toggleBackgroundR, toggleBackgroundG, toggleBackgroundB, toggleBorderA, toggleBorderR,
    toggleBorderG, toggleBorderB = BoxxyQuickLoot.getRowButtonColors("toggle", isHoveringToggle, entry.enabled == false)
    local removeBackgroundA, removeBackgroundR, removeBackgroundG, removeBackgroundB, removeBorderA, removeBorderR,
    removeBorderG, removeBorderB = BoxxyQuickLoot.getRowButtonColors("remove", isHoveringRemove, false)

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
    self:drawRect(toggleX, buttonY, BoxxyQuickLootWindow.toggleButtonWidth, buttonH,
        toggleBackgroundA, toggleBackgroundR, toggleBackgroundG, toggleBackgroundB)
    self:drawRectBorder(toggleX, buttonY, BoxxyQuickLootWindow.toggleButtonWidth, buttonH, toggleBorderA, toggleBorderR,
        toggleBorderG, toggleBorderB)
    self:drawTextCentre(toggleLabel, toggleX + BoxxyQuickLootWindow.toggleButtonWidth / 2,
        y + (item.height - FONT_HGT_SMALL) / 2, 1.0, 0.9, 0.9, 0.9, UIFont.Small)
    self:drawRect(buttonX, buttonY, BoxxyQuickLootWindow.removeButtonWidth, buttonH, removeBackgroundA, removeBackgroundR,
        removeBackgroundG, removeBackgroundB)
    self:drawRectBorder(buttonX, buttonY, BoxxyQuickLootWindow.removeButtonWidth, buttonH, removeBorderA, removeBorderR,
        removeBorderG, removeBorderB)
    self:drawTextCentre("Remove", buttonX + BoxxyQuickLootWindow.removeButtonWidth / 2,
        y + (item.height - FONT_HGT_SMALL) / 2, 1.0, 0.9, 0.9, 0.9, UIFont.Small)

    return y + item.height
end

function BoxxyQuickLootWindow:update()
    ISCollapsableWindow.update(self)

    if not self.playerObj then
        self:close()
        return
    end

    if self.addTermButton and self.termEntry and self.termEntry.getInternalText then
        local hasText = BoxxyQuickLoot.normalizeSearchTerm(self.termEntry:getInternalText()) ~= nil
        self.addTermButton:setEnable(hasText)
        self:updateAddTermButtonStyle(hasText)
    end
end

function BoxxyQuickLootWindow:close()
    if BoxxyQuickLoot.windows then
        BoxxyQuickLoot.windows[self.playerNum] = nil
    end
    ISCollapsableWindow.close(self)
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
    ISCollapsableWindow.initialise(self)

    local padding = 10
    local titleBarHeight = self:titleBarHeight()
    local inputHeight = FONT_HGT_SMALL + 12
    local buttonWidth = BoxxyQuickLootWindow.addTermButtonWidth
    local helpButtonSize = BoxxyQuickLootWindow.helpButtonSize

    self.customCloseButton = ISButton:new(self.width - 26, 1, helpButtonSize, titleBarHeight - 2, "X", self,
        BoxxyQuickLootWindow.onCustomCloseButtonClicked)
    self.customCloseButton:initialise()
    self.customCloseButton:setAnchorRight(true)
    self.customCloseButton:setAnchorTop(true)
    self:addChild(self.customCloseButton)

    self.helpButton = ISButton:new(self.width - 48, 1, helpButtonSize, titleBarHeight - 2, "?", self,
        BoxxyQuickLootWindow.onHelpButtonClicked)
    self.helpButton:initialise()
    self.helpButton:setAnchorRight(true)
    self.helpButton:setAnchorTop(true)
    self.helpButton.tooltip = BoxxyQuickLoot.getMatchSyntaxTooltip()
    self.helpButton.borderColor.a = 0.35
    self:addChild(self.helpButton)

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
    self.addTermButton:setAnchorRight(true)
    self.addTermButton:setAnchorTop(true)
    self:addChild(self.addTermButton)
    self:updateAddTermButtonStyle(false)

    self.listbox = ISScrollingListBox:new(padding, self.termEntry:getBottom() + padding, self.width - padding * 2,
        self.height - titleBarHeight - padding * 3 - inputHeight)
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
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.playerObj = playerObj
    o.playerNum = playerObj:getPlayerNum()
    o.title = BoxxyQuickLoot.windowTitle
    o.resizable = false
    o.pin = true
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
