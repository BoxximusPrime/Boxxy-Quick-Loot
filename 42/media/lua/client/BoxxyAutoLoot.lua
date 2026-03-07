---@diagnostic disable: undefined-global

require "ISUI/ISButton"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISInventoryPage"
require "ISUI/ISInventoryPane"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"

BoxxyAutoLoot = BoxxyAutoLoot or {}
BoxxyAutoLoot.modDataKey = "BoxxyAutoLoot"
BoxxyAutoLoot.windowTitle = "Quick Loot List"
BoxxyAutoLoot.windows = BoxxyAutoLoot.windows or {}

if not BoxxyAutoLoot.options and PZAPI and PZAPI.ModOptions then
    BoxxyAutoLoot.options = PZAPI.ModOptions:create("BoxxyAutoLoot", "Boxxy Quick Loot")
    BoxxyAutoLoot.autoLootKeyOption = BoxxyAutoLoot.options:addKeyBind(
        "BoxxyAutoLoot_triggerAutoLoot",
        "Quick Loot",
        Keyboard.KEY_NONE,
        "Trigger quick loot on the active loot window."
    )
end

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

BoxxyAutoLootWindow = ISCollapsableWindow:derive("BoxxyAutoLootWindow")
BoxxyAutoLootWindow.removeButtonWidth = 72
BoxxyAutoLootWindow.toggleButtonWidth = 72
BoxxyAutoLootWindow.addTermButtonWidth = 110

function BoxxyAutoLoot.getPlayerObject(playerRef)
    if type(playerRef) == "number" then
        return getSpecificPlayer(playerRef)
    end
    return playerRef
end

function BoxxyAutoLoot.getPlayerNumber(playerRef)
    if type(playerRef) == "number" then
        return playerRef
    end
    if playerRef and playerRef.getPlayerNum then
        return playerRef:getPlayerNum()
    end
    return 0
end

function BoxxyAutoLoot.getListStore(playerObj)
    if not playerObj then
        return nil
    end

    local modData = playerObj:getModData()
    modData[BoxxyAutoLoot.modDataKey] = modData[BoxxyAutoLoot.modDataKey] or {}
    modData[BoxxyAutoLoot.modDataKey].items = modData[BoxxyAutoLoot.modDataKey].items or {}
    return modData[BoxxyAutoLoot.modDataKey].items
end

function BoxxyAutoLoot.getTermStore(playerObj)
    if not playerObj then
        return nil
    end

    local modData = playerObj:getModData()
    modData[BoxxyAutoLoot.modDataKey] = modData[BoxxyAutoLoot.modDataKey] or {}
    modData[BoxxyAutoLoot.modDataKey].terms = modData[BoxxyAutoLoot.modDataKey].terms or {}
    return modData[BoxxyAutoLoot.modDataKey].terms
end

function BoxxyAutoLoot.saveList(playerObj)
    if not playerObj then
        return
    end

    if isClient() and playerObj.transmitModData then
        playerObj:transmitModData()
    end

    BoxxyAutoLoot.refreshWindow(playerObj)
end

function BoxxyAutoLoot.getDisplayName(itemOrFullType)
    if type(itemOrFullType) == "string" then
        return getItemNameFromFullType(itemOrFullType) or itemOrFullType
    end

    if not itemOrFullType then
        return "Unknown Item"
    end

    return itemOrFullType:getDisplayName() or itemOrFullType:getName() or itemOrFullType:getFullType()
end

function BoxxyAutoLoot.getStoredEntryInfo(value, fallbackName)
    local name = fallbackName
    local enabled = true

    if type(value) == "table" then
        name = value.name or value.label or fallbackName
        enabled = value.enabled ~= false
    elseif type(value) == "string" then
        name = value
    elseif value == false then
        enabled = false
    end

    return name, enabled
end

function BoxxyAutoLoot.hasAnyStoredEntries(playerObj)
    return BoxxyAutoLoot.tableHasEntries(BoxxyAutoLoot.getListStore(playerObj)) or
        BoxxyAutoLoot.tableHasEntries(BoxxyAutoLoot.getTermStore(playerObj))
end

function BoxxyAutoLoot.normalizeSearchTerm(term)
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

function BoxxyAutoLoot.getDisplaySearchTerm(term)
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

function BoxxyAutoLoot.getTermLabel(term)
    return 'Contains: "' .. term .. '"'
end

function BoxxyAutoLoot.getItemSearchText(item)
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

function BoxxyAutoLoot.matchesSearchTerm(term, item)
    local normalizedTerm = BoxxyAutoLoot.normalizeSearchTerm(term)
    local searchText = BoxxyAutoLoot.getItemSearchText(item)
    return normalizedTerm ~= nil and searchText ~= nil and string.find(searchText, normalizedTerm, 1, true) ~= nil
end

function BoxxyAutoLoot.isExactTracked(playerObj, item)
    local store = BoxxyAutoLoot.getListStore(playerObj)
    local fullType = BoxxyAutoLoot.getItemFullType(item)
    if store == nil or fullType == nil or store[fullType] == nil then
        return false
    end

    local _, enabled = BoxxyAutoLoot.getStoredEntryInfo(store[fullType], BoxxyAutoLoot.getDisplayName(fullType))
    return enabled
end

function BoxxyAutoLoot.findMatchingTerm(playerObj, item)
    local terms = BoxxyAutoLoot.getTermStore(playerObj)
    if type(terms) ~= "table" then
        return nil
    end

    for term, value in pairs(terms) do
        local _, enabled = BoxxyAutoLoot.getStoredEntryInfo(value, term)
        if enabled and BoxxyAutoLoot.matchesSearchTerm(term, item) then
            return term
        end
    end

    return nil
end

function BoxxyAutoLoot.hasTrackedItems(playerObj)
    local store = BoxxyAutoLoot.getListStore(playerObj)
    local terms = BoxxyAutoLoot.getTermStore(playerObj)

    if type(store) == "table" then
        for fullType, value in pairs(store) do
            local _, enabled = BoxxyAutoLoot.getStoredEntryInfo(value, BoxxyAutoLoot.getDisplayName(fullType))
            if enabled then
                return true
            end
        end
    end

    if type(terms) == "table" then
        for term, value in pairs(terms) do
            local _, enabled = BoxxyAutoLoot.getStoredEntryInfo(value, term)
            if enabled then
                return true
            end
        end
    end

    return false
end

function BoxxyAutoLoot.isTracked(playerObj, item)
    return BoxxyAutoLoot.isExactTracked(playerObj, item) or BoxxyAutoLoot.findMatchingTerm(playerObj, item) ~= nil
end

function BoxxyAutoLoot.addItems(playerObj, items)
    local store = BoxxyAutoLoot.getListStore(playerObj)
    if not store then
        return
    end

    for _, item in ipairs(items) do
        if item then
            store[item:getFullType()] = {
                name = BoxxyAutoLoot.getDisplayName(item),
                enabled = true,
            }
        end
    end

    BoxxyAutoLoot.saveList(playerObj)
end

function BoxxyAutoLoot.removeItems(playerObj, items)
    local store = BoxxyAutoLoot.getListStore(playerObj)
    if not store then
        return
    end

    for _, item in ipairs(items) do
        if item then
            store[item:getFullType()] = nil
        end
    end

    BoxxyAutoLoot.saveList(playerObj)
end

function BoxxyAutoLoot.removeFullType(playerObj, fullType)
    local store = BoxxyAutoLoot.getListStore(playerObj)
    if not store then
        return
    end

    store[fullType] = nil
    BoxxyAutoLoot.saveList(playerObj)
end

function BoxxyAutoLoot.addSearchTerm(playerObj, term)
    local normalizedTerm = BoxxyAutoLoot.normalizeSearchTerm(term)
    local displayTerm = BoxxyAutoLoot.getDisplaySearchTerm(term)
    local terms = BoxxyAutoLoot.getTermStore(playerObj)
    if not normalizedTerm or not displayTerm or not terms then
        return false
    end

    terms[normalizedTerm] = {
        label = displayTerm,
        enabled = true,
    }
    BoxxyAutoLoot.saveList(playerObj)
    return true
end

function BoxxyAutoLoot.removeSearchTerm(playerObj, term)
    local normalizedTerm = BoxxyAutoLoot.normalizeSearchTerm(term)
    local terms = BoxxyAutoLoot.getTermStore(playerObj)
    if not normalizedTerm or not terms then
        return
    end

    terms[normalizedTerm] = nil
    BoxxyAutoLoot.saveList(playerObj)
end

function BoxxyAutoLoot.setFullTypeEnabled(playerObj, fullType, enabled)
    local store = BoxxyAutoLoot.getListStore(playerObj)
    if not store or not fullType or store[fullType] == nil then
        return
    end

    local name = BoxxyAutoLoot.getStoredEntryInfo(store[fullType], BoxxyAutoLoot.getDisplayName(fullType))
    store[fullType] = {
        name = name,
        enabled = enabled ~= false,
    }
    BoxxyAutoLoot.saveList(playerObj)
end

function BoxxyAutoLoot.setSearchTermEnabled(playerObj, term, enabled)
    local normalizedTerm = BoxxyAutoLoot.normalizeSearchTerm(term)
    local terms = BoxxyAutoLoot.getTermStore(playerObj)
    if not normalizedTerm or not terms or terms[normalizedTerm] == nil then
        return
    end

    local label = BoxxyAutoLoot.getStoredEntryInfo(terms[normalizedTerm], normalizedTerm)
    terms[normalizedTerm] = {
        label = label,
        enabled = enabled ~= false,
    }
    BoxxyAutoLoot.saveList(playerObj)
end

function BoxxyAutoLoot.toggleEntryEnabled(playerObj, entry)
    if not playerObj or not entry or entry.empty then
        return
    end

    local newEnabled = entry.enabled == false
    if entry.entryType == "term" then
        BoxxyAutoLoot.setSearchTermEnabled(playerObj, entry.term, newEnabled)
    else
        BoxxyAutoLoot.setFullTypeEnabled(playerObj, entry.fullType, newEnabled)
    end
end

function BoxxyAutoLoot.getSortedEntries(playerObj)
    local store = BoxxyAutoLoot.getListStore(playerObj)
    local terms = BoxxyAutoLoot.getTermStore(playerObj)
    local entries = {}

    if not store and not terms then
        return entries
    end

    if store then
        for fullType, value in pairs(store) do
            local name, enabled = BoxxyAutoLoot.getStoredEntryInfo(value, BoxxyAutoLoot.getDisplayName(fullType))
            table.insert(entries, {
                entryType = "item",
                fullType = fullType,
                name = name or BoxxyAutoLoot.getDisplayName(fullType),
                enabled = enabled,
            })
        end
    end

    if terms then
        for term, value in pairs(terms) do
            local label, enabled = BoxxyAutoLoot.getStoredEntryInfo(value, term)
            table.insert(entries, {
                entryType = "term",
                term = term,
                name = BoxxyAutoLoot.getTermLabel(label or term),
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

function BoxxyAutoLoot.getContextItems(items)
    if not items or #items == 0 then
        return {}
    end

    return ISInventoryPane.getActualItems(items)
end

function BoxxyAutoLoot.getListRowItem(rowEntry)
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

function BoxxyAutoLoot.getItemFullType(item)
    if not item or not instanceof(item, "InventoryItem") or item.getFullType == nil then
        return nil
    end

    return item:getFullType()
end

function BoxxyAutoLoot.tableHasEntries(value)
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

function BoxxyAutoLoot.collectTrackedItems(playerObj, inventory)
    local matches = {}
    local heavyItem = nil
    local totalMatches = 0

    if not inventory or not BoxxyAutoLoot.hasTrackedItems(playerObj) then
        return matches, heavyItem, totalMatches
    end

    local items = inventory:getItems()
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if BoxxyAutoLoot.isTracked(playerObj, item) then
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

function BoxxyAutoLoot.containerHasTrackedItems(playerObj, inventory)
    if not inventory or not BoxxyAutoLoot.hasTrackedItems(playerObj) then
        return false
    end

    local items = inventory:getItems()
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if BoxxyAutoLoot.isTracked(playerObj, item) then
            return true
        end
    end

    return false
end

function BoxxyAutoLoot.showListWindow(playerRef)
    local playerObj = BoxxyAutoLoot.getPlayerObject(playerRef)
    if not playerObj then
        return
    end

    BoxxyAutoLoot.windows = BoxxyAutoLoot.windows or {}

    local playerNum = BoxxyAutoLoot.getPlayerNumber(playerObj)
    local window = BoxxyAutoLoot.windows[playerNum]
    if window then
        window:refreshList()
        window:setVisible(true)
        window:addToUIManager()
        window:bringToTop()
        return
    end

    window = BoxxyAutoLootWindow:new(playerObj)
    window:initialise()
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    BoxxyAutoLoot.windows[playerNum] = window
end

function BoxxyAutoLoot.refreshWindow(playerRef)
    local playerNum = BoxxyAutoLoot.getPlayerNumber(playerRef)
    local window = BoxxyAutoLoot.windows and BoxxyAutoLoot.windows[playerNum] or nil
    if window then
        window:refreshList()
    end
end

function BoxxyAutoLoot.onAddToList(playerObj, items)
    BoxxyAutoLoot.addItems(playerObj, items)
end

function BoxxyAutoLoot.onRemoveFromList(playerObj, items)
    BoxxyAutoLoot.removeItems(playerObj, items)
end

function BoxxyAutoLoot.onFillInventoryObjectContextMenu(playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    local actualItems = BoxxyAutoLoot.getContextItems(items)
    if not playerObj or #actualItems == 0 then
        return
    end

    local anyTracked = false
    local anyUntracked = false

    for _, item in ipairs(actualItems) do
        if BoxxyAutoLoot.isExactTracked(playerObj, item) then
            anyTracked = true
        else
            anyUntracked = true
        end
    end

    local option = context:addOption("Quick Loot")
    local subMenu = context:getNew(context)
    context:addSubMenu(option, subMenu)

    if anyUntracked then
        subMenu:addOption("Add to list", playerObj, BoxxyAutoLoot.onAddToList, actualItems)
    end
    if anyTracked then
        subMenu:addOption("Remove from list", playerObj, BoxxyAutoLoot.onRemoveFromList, actualItems)
    end
    subMenu:addOption("Show list", playerNum, BoxxyAutoLoot.showListWindow)
end

function BoxxyAutoLoot.onAutoLootClicked(page)
    local playerObj = getSpecificPlayer(page.player)
    local inventory = page.inventoryPane and page.inventoryPane.inventory or nil
    if not playerObj or not inventory then
        return
    end

    if not luautils.walkToContainer(inventory, page.player) then
        return
    end

    local items, heavyItem, totalMatches = BoxxyAutoLoot.collectTrackedItems(playerObj, inventory)
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

function BoxxyAutoLoot.isVisibleUiElement(uiElement)
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

function BoxxyAutoLoot.canTriggerAutoLoot(page)
    return BoxxyAutoLoot.isVisibleUiElement(page) and BoxxyAutoLoot.shouldShowLootActionForPage(page)
end

function BoxxyAutoLoot.getActiveLootPage()
    for playerNum = 0, 3 do
        local lootPage = getPlayerLoot(playerNum)
        if BoxxyAutoLoot.canTriggerAutoLoot(lootPage) then
            return lootPage
        end
    end

    return nil
end

function BoxxyAutoLoot.onAutoLootKeyPressed(key)
    local keyOption = BoxxyAutoLoot.autoLootKeyOption
    if not getPlayer() or not keyOption then
        return
    end

    local boundKey = keyOption:getValue()
    if not boundKey or boundKey == Keyboard.KEY_NONE or key ~= boundKey then
        return
    end

    local lootPage = BoxxyAutoLoot.getActiveLootPage()
    if lootPage then
        BoxxyAutoLoot.onAutoLootClicked(lootPage)
    end
end

function BoxxyAutoLoot.hasCleanUILootControls()
    return ISLootWindowContainerControls ~= nil and ISLootWindowContainerControls.AddHandler ~= nil and
        ISLootWindowObjectControlHandler ~= nil and ISLootWindowFloorControlHandler ~= nil
end

function BoxxyAutoLoot.shouldShowLootActionForPage(page)
    if not page or page.onCharacter then
        return false
    end

    local playerObj = getSpecificPlayer(page.player)
    local inventory = page.inventoryPane and page.inventoryPane.inventory or nil
    if not playerObj or not inventory or not inventory.getItems then
        return false
    end

    local items = inventory:getItems()
    return items ~= nil and not items:isEmpty() and BoxxyAutoLoot.hasTrackedItems(playerObj)
end

function BoxxyAutoLoot.registerCleanUIHandler()
    if not BoxxyAutoLoot.hasCleanUILootControls() or BoxxyAutoLoot.cleanUIHandlerRegistered then
        return
    end

    ISLootWindowObjectControlHandler_BoxxyAutoLoot = ISLootWindowObjectControlHandler:derive(
        "ISLootWindowObjectControlHandler_BoxxyAutoLoot")
    local ObjectHandler = ISLootWindowObjectControlHandler_BoxxyAutoLoot

    function ObjectHandler:shouldBeVisible()
        return BoxxyAutoLoot.shouldShowLootActionForPage(self.lootWindow)
    end

    function ObjectHandler:getControl()
        return self:getButtonControl("quick loot")
    end

    function ObjectHandler:perform()
        BoxxyAutoLoot.onAutoLootClicked(self.lootWindow)
    end

    function ObjectHandler:new()
        local o = ISLootWindowObjectControlHandler.new(self)
        o.altColor = false
        return o
    end

    ISLootWindowFloorControlHandler_BoxxyAutoLoot = ISLootWindowFloorControlHandler:derive(
        "ISLootWindowFloorControlHandler_BoxxyAutoLoot")
    local FloorHandler = ISLootWindowFloorControlHandler_BoxxyAutoLoot

    function FloorHandler:shouldBeVisible()
        return BoxxyAutoLoot.shouldShowLootActionForPage(self.lootWindow)
    end

    function FloorHandler:getControl()
        return self:getButtonControl("quick loot")
    end

    function FloorHandler:perform()
        BoxxyAutoLoot.onAutoLootClicked(self.lootWindow)
    end

    function FloorHandler:new()
        return ISLootWindowFloorControlHandler.new(self)
    end

    ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_BoxxyAutoLoot)
    ISLootWindowContainerControls.AddFloorHandler(ISLootWindowFloorControlHandler_BoxxyAutoLoot)
    BoxxyAutoLoot.cleanUIHandlerRegistered = true
end

function BoxxyAutoLoot.isButtonControl(control)
    return type(control) == "table" and control.Type == "ISButton" and control.getRight ~= nil and
        control.getY ~= nil and control.getHeight ~= nil
end

function BoxxyAutoLoot.getLootAllControl(page)
    if not page then
        return nil
    end

    local directControl = rawget(page, "lootAll")
    if BoxxyAutoLoot.isButtonControl(directControl) then
        return directControl
    end

    local expectedTitle = getText("IGUI_invpage_Loot_all")
    for _, child in ipairs(page.children or {}) do
        if BoxxyAutoLoot.isButtonControl(child) then
            local title = child.getTitle and child:getTitle() or child.title
            if title == expectedTitle or (child.onclick == ISInventoryPage.lootAll and child.target == page) then
                return child
            end
        end
    end

    return nil
end

function BoxxyAutoLoot.attachLootButton(page)
    if not page or page.onCharacter or page.boxxyAutoLootButton or BoxxyAutoLoot.hasCleanUILootControls() then
        return
    end

    local lootAllControl = BoxxyAutoLoot.getLootAllControl(page)
    if not lootAllControl then
        return
    end

    local button = ISButton:new(lootAllControl:getRight() + 6, lootAllControl:getY(), 80, lootAllControl:getHeight(),
        "quick loot", page, BoxxyAutoLoot.onAutoLootClicked)
    button:initialise()
    button.borderColor.a = 0.0
    button.backgroundColor.a = 0.0
    button.backgroundColorMouseOver.a = 0.7
    button:setVisible(false)
    button:setWidthToTitle()
    page:addChild(button)
    page.boxxyAutoLootButton = button
end

function BoxxyAutoLoot.updateLootButton(page)
    if BoxxyAutoLoot.hasCleanUILootControls() then
        return
    end

    if not page or page.onCharacter or not page.boxxyAutoLootButton then
        return
    end

    local lootAllControl = BoxxyAutoLoot.getLootAllControl(page)
    if not lootAllControl then
        page.boxxyAutoLootButton:setVisible(false)
        return
    end

    local playerObj = getSpecificPlayer(page.player)
    local inventory = page.inventoryPane and page.inventoryPane.inventory or nil
    local shouldShow = lootAllControl:getIsVisible() and inventory ~= nil and inventory:getItems() and
        not inventory:getItems():isEmpty()

    page.boxxyAutoLootButton:setVisible(shouldShow)
    if not shouldShow then
        return
    end

    page.boxxyAutoLootButton:setX(lootAllControl:getRight() + 6)
    page.boxxyAutoLootButton:setY(lootAllControl:getY())
    page.boxxyAutoLootButton:setHeight(lootAllControl:getHeight())
    page.boxxyAutoLootButton:setWidthToTitle()
    page.boxxyAutoLootButton:setEnable(BoxxyAutoLoot.hasTrackedItems(playerObj))
    page.boxxyAutoLootButton.tooltip = BoxxyAutoLoot.hasTrackedItems(playerObj) and nil or
        (BoxxyAutoLoot.hasAnyStoredEntries(playerObj) and "Enable auto loot entries first." or
            "Add items to the auto loot list first.")
end

function BoxxyAutoLoot.drawTrackedHighlights(pane, doDragged)
    if doDragged or not pane or not pane.inventoryPage or pane.inventoryPage.onCharacter then
        return
    end

    local playerObj = getSpecificPlayer(pane.player)
    if not playerObj or not BoxxyAutoLoot.hasTrackedItems(playerObj) or type(pane.items) ~= "table" then
        return
    end

    if pane.getYScroll == nil or pane.getWidth == nil or pane.getHeight == nil or pane.drawRect == nil or
        pane.drawRectBorder == nil or pane.isVScrollBarVisible == nil then
        return
    end

    local yScroll = pane:getYScroll()
    local rowWidth = pane:getWidth() - pane.column2 - (pane:isVScrollBarVisible() and 14 or 2)

    for index, rowEntry in ipairs(pane.items) do
        local item = BoxxyAutoLoot.getListRowItem(rowEntry)
        if BoxxyAutoLoot.isTracked(playerObj, item) then
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

function BoxxyAutoLoot.getEntryItem(entry)
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

function BoxxyAutoLoot.reorderTrackedEntries(pane)
    if not pane or not pane.inventoryPage or pane.inventoryPage.onCharacter or type(pane.itemslist) ~= "table" then
        return
    end

    local playerObj = getSpecificPlayer(pane.player)
    if not playerObj or not BoxxyAutoLoot.hasTrackedItems(playerObj) then
        return
    end

    local searchMatches = {}
    local trackedEntries = {}
    local otherEntries = {}

    for _, entry in ipairs(pane.itemslist) do
        local item = BoxxyAutoLoot.getEntryItem(entry)
        local isTracked = BoxxyAutoLoot.isTracked(playerObj, item)

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

function BoxxyAutoLoot.patchInventoryUi()
    if BoxxyAutoLoot.isPatched then
        return
    end

    BoxxyAutoLoot.isPatched = true
    BoxxyAutoLoot.emptyContextMenu = BoxxyAutoLoot.emptyContextMenu or {
        isAnyVisible = function()
            return false
        end,
    }

    if not BoxxyAutoLoot.originalGetPlayerContextMenu and type(getPlayerContextMenu) == "function" then
        BoxxyAutoLoot.originalGetPlayerContextMenu = getPlayerContextMenu
        function getPlayerContextMenu(playerNum)
            local contextMenu = BoxxyAutoLoot.originalGetPlayerContextMenu(playerNum)
            if contextMenu ~= nil then
                return contextMenu
            end

            return BoxxyAutoLoot.emptyContextMenu
        end
    end

    BoxxyAutoLoot.originalCreateChildren = ISInventoryPage.createChildren
    BoxxyAutoLoot.originalPageUpdate = ISInventoryPage.update
    BoxxyAutoLoot.originalRefreshContainer = ISInventoryPane.refreshContainer
    BoxxyAutoLoot.originalRenderDetails = ISInventoryPane.renderdetails

    function ISInventoryPage:createChildren()
        BoxxyAutoLoot.originalCreateChildren(self)
        BoxxyAutoLoot.attachLootButton(self)
    end

    function ISInventoryPage:update()
        BoxxyAutoLoot.originalPageUpdate(self)
        BoxxyAutoLoot.updateLootButton(self)
    end

    function ISInventoryPane:refreshContainer()
        BoxxyAutoLoot.originalRefreshContainer(self)
        BoxxyAutoLoot.reorderTrackedEntries(self)
    end

    function ISInventoryPane:renderdetails(doDragged)
        BoxxyAutoLoot.originalRenderDetails(self, doDragged)
        BoxxyAutoLoot.drawTrackedHighlights(self, doDragged)
    end
end

function BoxxyAutoLoot.attachExistingLootPages()
    BoxxyAutoLoot.registerCleanUIHandler()

    for playerNum = 0, 3 do
        local lootPage = getPlayerLoot(playerNum)
        if lootPage then
            BoxxyAutoLoot.attachLootButton(lootPage)
            BoxxyAutoLoot.updateLootButton(lootPage)
        end
    end
end

function BoxxyAutoLootWindow:refreshList()
    self.listbox:clear()
    self.listbox:setScrollHeight(0)

    local entries = BoxxyAutoLoot.getSortedEntries(self.playerObj)
    if #entries == 0 then
        self.listbox:addItem("No items in the auto loot list.", { empty = true })
        return
    end

    for _, entry in ipairs(entries) do
        self.listbox:addItem(entry.name, entry)
    end
end

function BoxxyAutoLootWindow:onListMouseDown(x, y)
    if #self.items == 0 then
        return
    end

    local row = self:rowAt(x, y)
    if row < 1 or row > #self.items then
        return
    end

    local entry = self.items[row].item
    if entry and not entry.empty then
        local toggleX = self:getWidth() - BoxxyAutoLootWindow.removeButtonWidth - BoxxyAutoLootWindow.toggleButtonWidth - 20
        local removeX = self:getWidth() - BoxxyAutoLootWindow.removeButtonWidth - 12
        if x >= toggleX and x <= toggleX + BoxxyAutoLootWindow.toggleButtonWidth then
            BoxxyAutoLoot.toggleEntryEnabled(self.parentWindow.playerObj, entry)
            return
        end

        if x >= removeX and x <= removeX + BoxxyAutoLootWindow.removeButtonWidth then
            if entry.entryType == "term" then
                BoxxyAutoLoot.removeSearchTerm(self.parentWindow.playerObj, entry.term)
            else
                BoxxyAutoLoot.removeFullType(self.parentWindow.playerObj, entry.fullType)
            end
            return
        end
    end

    return ISScrollingListBox.onMouseDown(self, x, y)
end

function BoxxyAutoLootWindow:doDrawItem(y, item, alt)
    local entry = item.item
    local backgroundAlpha = alt and 0.08 or 0.16
    self:drawRect(0, y, self:getWidth(), item.height, backgroundAlpha, 0.0, 0.0, 0.0)

    if self.items[self.selected] == item then
        self:drawRect(0, y, self:getWidth(), item.height, 0.12, 1.0, 1.0, 1.0)
    end

    if entry and entry.empty then
        self:drawText(entry.text or item.text, 10, y + (item.height - FONT_HGT_SMALL) / 2, 0.6, 0.6, 0.6, 1.0,
            UIFont.Small)
        return y + item.height
    end

    local toggleX = self:getWidth() - BoxxyAutoLootWindow.removeButtonWidth - BoxxyAutoLootWindow.toggleButtonWidth - 20
    local buttonX = self:getWidth() - BoxxyAutoLootWindow.removeButtonWidth - 12
    local buttonY = y + 4
    local buttonH = item.height - 8
    local toggleLabel = entry.enabled == false and "Enable" or "Disable"
    local textAlpha = entry.enabled == false and 0.45 or 0.9
    local statusText = entry.enabled == false and " (Disabled)" or ""

    self:drawText(item.text .. statusText, 10, y + (item.height - FONT_HGT_SMALL) / 2, textAlpha, textAlpha, textAlpha,
        1.0, UIFont.Small)
    self:drawRect(toggleX, buttonY, BoxxyAutoLootWindow.toggleButtonWidth, buttonH,
        0.20,
        entry.enabled == false and 0.12 or 0.45,
        entry.enabled == false and 0.45 or 0.25,
        entry.enabled == false and 0.12 or 0.15)
    self:drawRectBorder(toggleX, buttonY, BoxxyAutoLootWindow.toggleButtonWidth, buttonH, 0.45, 0.7, 0.7, 0.7)
    self:drawTextCentre(toggleLabel, toggleX + BoxxyAutoLootWindow.toggleButtonWidth / 2,
        y + (item.height - FONT_HGT_SMALL) / 2, 1.0, 0.9, 0.9, 0.9, UIFont.Small)
    self:drawRect(buttonX, buttonY, BoxxyAutoLootWindow.removeButtonWidth, buttonH, 0.25, 0.55, 0.15, 0.15)
    self:drawRectBorder(buttonX, buttonY, BoxxyAutoLootWindow.removeButtonWidth, buttonH, 0.45, 0.8, 0.25, 0.25)
    self:drawTextCentre("Remove", buttonX + BoxxyAutoLootWindow.removeButtonWidth / 2,
        y + (item.height - FONT_HGT_SMALL) / 2, 1.0, 0.9, 0.9, 0.9, UIFont.Small)

    return y + item.height
end

function BoxxyAutoLootWindow:update()
    ISCollapsableWindow.update(self)

    if not self.playerObj then
        self:close()
        return
    end

    if self.addTermButton and self.termEntry and self.termEntry.getInternalText then
        local hasText = BoxxyAutoLoot.normalizeSearchTerm(self.termEntry:getInternalText()) ~= nil
        self.addTermButton:setEnable(hasText)
    end
end

function BoxxyAutoLootWindow:close()
    if BoxxyAutoLoot.windows then
        BoxxyAutoLoot.windows[self.playerNum] = nil
    end
    ISCollapsableWindow.close(self)
end

function BoxxyAutoLootWindow:addSearchTermFromInput()
    local term = self.termEntry and self.termEntry:getInternalText() or nil
    if BoxxyAutoLoot.addSearchTerm(self.playerObj, term) then
        self.termEntry:setText("")
        self.termEntry:focus()
        self:refreshList()
    end
end

function BoxxyAutoLootWindow:initialise()
    ISCollapsableWindow.initialise(self)

    local padding = 10
    local titleBarHeight = self:titleBarHeight()
    local inputHeight = FONT_HGT_SMALL + 12
    local buttonWidth = BoxxyAutoLootWindow.addTermButtonWidth

    self.termEntry = ISTextEntryBox:new("", padding, titleBarHeight + padding,
        self.width - padding * 3 - buttonWidth, inputHeight)
    self.termEntry:initialise()
    self.termEntry:instantiate()
    self.termEntry:setAnchorLeft(true)
    self.termEntry:setAnchorRight(true)
    self.termEntry:setAnchorTop(true)
    self.termEntry:setOnlyNumbers(false)
    self.termEntry:setMaxLines(1)
    self.termEntry:setPlaceholderText('Add fuzzy match, e.g. "chips"')
    self.termEntry.onCommandEntered = function(entry)
        entry.parentWindow:addSearchTermFromInput()
    end
    self.termEntry.parentWindow = self
    self:addChild(self.termEntry)

    self.addTermButton = ISButton:new(self.termEntry:getRight() + padding, self.termEntry.y, buttonWidth, inputHeight,
        "Add Match", self, BoxxyAutoLootWindow.addSearchTermFromInput)
    self.addTermButton:initialise()
    self.addTermButton:setAnchorRight(true)
    self.addTermButton:setAnchorTop(true)
    self:addChild(self.addTermButton)

    self.listbox = ISScrollingListBox:new(padding, self.termEntry:getBottom() + padding, self.width - padding * 2,
        self.height - titleBarHeight - padding * 3 - inputHeight)
    self.listbox:initialise()
    self.listbox:instantiate()
    self.listbox:setAnchorLeft(true)
    self.listbox:setAnchorRight(true)
    self.listbox:setAnchorTop(true)
    self.listbox:setAnchorBottom(true)
    self.listbox.itemheight = FONT_HGT_SMALL + 12
    self.listbox.doDrawItem = BoxxyAutoLootWindow.doDrawItem
    self.listbox.onMouseDown = BoxxyAutoLootWindow.onListMouseDown
    self.listbox.parentWindow = self
    self:addChild(self.listbox)

    self:refreshList()
end

function BoxxyAutoLootWindow:new(playerObj)
    local width = 520
    local height = 390
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.playerObj = playerObj
    o.playerNum = playerObj:getPlayerNum()
    o.title = BoxxyAutoLoot.windowTitle
    o.resizable = true
    o.pin = true

    return o
end

BoxxyAutoLoot.patchInventoryUi()
BoxxyAutoLoot.registerCleanUIHandler()
Events.OnFillInventoryObjectContextMenu.Add(BoxxyAutoLoot.onFillInventoryObjectContextMenu)
Events.OnGameBoot.Add(BoxxyAutoLoot.registerCleanUIHandler)
Events.OnGameStart.Add(BoxxyAutoLoot.attachExistingLootPages)
Events.OnKeyPressed.Add(BoxxyAutoLoot.onAutoLootKeyPressed)
