-----------------------------------------------------------------------------------------------
-- Client Lua Script for Dressing
-- Copyright (c) NCsoft. All rights reserved
-- Autor : Laurent Indermühle - Honiix
-----------------------------------------------------------------------------------------------
 
require "Apollo"
require "Window"
require "GameLib"
require "Item"
 
-----------------------------------------------------------------------------------------------
-- Dressing Module Definition
-----------------------------------------------------------------------------------------------
local Dressing = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

-- Si un jour on doit effacer les données sauvegardées, il suffit d'incrémenter cette constante
knVersion = 1

-- Defini la taille des boutons qui représentent les armures dans la fenêtre principale.
local knBtnSize = {
    ["small"]   = 35,
    ["big"]     = 50
}

-- Code couleur de qualité des objets. Pour tracer les bordures autour des armures
local ktItemQualitySprites = {
    [1] = 'BK3:UI_BK3_ItemQualityGrey',
    [2] = 'BK3:UI_BK3_ItemQualityWhite',
    [3] = 'BK3:UI_BK3_ItemQualityGreen',
    [4] = 'BK3:UI_BK3_ItemQualityBlue',
    [5] = 'BK3:UI_BK3_ItemQualityPurple',
    [6] = 'BK3:UI_BK3_ItemQualityOrange',
    [7] = 'BK3:UI_BK3_ItemQualityMagenta',
}

-- Ordre dans lequel j'ai envie d'afficher mes armures
local ktSortArmorSlots = {
    [1] = 16,   -- Weapon
    [2] = 15,   -- Shield
    [3] = 2,    -- Head
    [4] = 3,    -- Shoulders
    [5] = 0,    -- Chest
    [6] = 5,    -- Hands
    [7] = 1,    -- Legs
    [8] = 4,    -- Feets
    [9] = 7,    -- Augment
    [10] = 8,   -- System
    [11] = 11,  -- Gadget
    [12] = 10   -- Implants
}

-- Ces données servent à dessiner les boutons qui vont contenir les icones des
-- pièces d'armures sélectionnée pour un set.
-- Il est donc facile de choisir ici ce qu'on veut prendre en compte ou non.
-- J'ai volontairement ajouté un niveau au tableau afin de générer des id séquentiel
-- Cela évite que des boucles cassent l'ordre des armures. Je tiens à garder le même que
-- dans le panneau du personnage ingame (arme puis bouclier puis casque etc)
local ktEquippableArmorSlot = {
    {
        ["nArmorSlotId"]        = 16, 
        ["strArmorTypeName"]    = "Weapon", 
        ["strBtnSize"]          = "big",
        ["strSpriteWhenEmpty"]  = "CharacterWindowSprites:btn_Armor_HandsNormal",
        ["nItemId"]             = nil
    },{
        ["nArmorSlotId"]        = 15, 
        ["strArmorTypeName"]    = "Shield", 
        ["strBtnSize"]          = "big",
        ["strSpriteWhenEmpty"]  = "btn_Armor_PowerSourceNormal",
        ["nItemId"]             = nil
    },{
        ["nArmorSlotId"]        = 2, 
        ["strArmorTypeName"]    = "Head", 
        ["strBtnSize"]          = "big",
        ["strSpriteWhenEmpty"]  = "btn_Armor_HeadNormal",
        ["nItemId"]             = nil
    },{
        ["nArmorSlotId"]        = 3, 
        ["strArmorTypeName"]    = "Shoulders", 
        ["strBtnSize"]          = "big",
        ["strSpriteWhenEmpty"]  = "btn_Armor_ShoulderNormal",
        ["nItemId"]             = nil
    },{
        ["nArmorSlotId"]        = 0, 
        ["strArmorTypeName"]    = "Chest", 
        ["strBtnSize"]          = "big",
        ["strSpriteWhenEmpty"]  = "btn_Armor_ChestNormal",
        ["nItemId"]             = nil
    },{
        ["nArmorSlotId"]        = 5, 
        ["strArmorTypeName"]    = "Hands", 
        ["strBtnSize"]          = "big",
        ["strSpriteWhenEmpty"]  = "btn_Armor_HandsNormal",
        ["nItemId"]             = nil
    },{
        ["nArmorSlotId"]        = 1, 
        ["strArmorTypeName"]    = "Legs", 
        ["strBtnSize"]          = "big",
        ["strSpriteWhenEmpty"]  = "btn_Armor_LegsNormal",
        ["nItemId"]             = nil
    },{
        ["nArmorSlotId"]        = 4, 
        ["strArmorTypeName"]    = "Feets", 
        ["strBtnSize"]          = "big",
        ["strSpriteWhenEmpty"]  = "btn_Armor_FeetNormal",
        ["nItemId"]             = nil
    },{
        ["nArmorSlotId"]        = 7, 
        ["strArmorTypeName"]    = "Augment", 
        ["strBtnSize"]          = "small",
        ["strSpriteWhenEmpty"]  = "CharacterWindowSprites:btn_Armor_PowerSourceDisabled",
        ["nItemId"]             = nil 
    },{
        ["nArmorSlotId"]        = 8, 
        ["strArmorTypeName"]    = "System", 
        ["strBtnSize"]          = "small",
        ["strSpriteWhenEmpty"]  = "CharacterWindowSprites:btn_Armor_BucklePressedFlyby",
        ["nItemId"]             = nil
    },{
        ["nArmorSlotId"]        = 11, 
        ["strArmorTypeName"]    = "Gadget", 
        ["strBtnSize"]          = "small",
        ["strSpriteWhenEmpty"]  = "CharacterWindowSprites:btn_Armor_Trinket1Disabled",
        ["nItemId"]             = nil
    },{
        ["nArmorSlotId"]        = 10, 
        ["strArmorTypeName"]    = "Implants", 
        ["strBtnSize"]          = "small",
        ["strSpriteWhenEmpty"]  = "CharacterWindowSprites:btn_Armor_RightRingPressedFlyby",
        ["nItemId"]             = nil
    }
}

-- Table vide qu'on va utiliser pour le premier lancement de l'Addon
local ktArmorSet = {
        ["strName"] = "Give me a name",
        ["tItems"] = ktEquippableArmorSlot
}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Dressing:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
    return o
end

function Dressing:Init()
    local bHasConfigureFunction = true
    local strConfigureButtonText = "Dressing"
    local tDependencies = {
        -- "UnitOrPackageName",
    }
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

-----------------------------------------------------------------------------------------------
-- Save and Restore
-----------------------------------------------------------------------------------------------

function Dressing:OnSave(eType)
    if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

    -- Afin de pouvoir enregistrer la position de la fenêtre principale
    local locWindowLocation = self.wndMain and self.wndMain:GetLocation() or self.locSavedWindowLoc

    -- Il est crutial de vider ce tableau. Quand je reload trop souvent je me retrouvais
    -- avec un fichier de sauvegarde de 519MB
    local tSaved = {}
    tSaved =
    {
        tWindowLocation = locWindowLocation and locWindowLocation:ToTable() or nil,
        nVersion = knVersion,
        tArmorSets = self.tArmorSets
    }
    
    -- On passe la table à sauvegarder
    return tSaved
end

-- Restore Saved User Settings
function Dressing:OnRestore(eType, tSavedData)
    if eType == GameLib.CodeEnumAddonSaveLevel.Character and tSavedData.nVersion == knVersion then 
        if tSavedData.tArmorSets then
            self.tArmorSets = tSavedData.tArmorSets
        else
            -- Si aucun ArmorSet sauvegardé, on créer le premier
            self.tArmorSets = {}
            self.tArmorSets = ktArmorSet
        end

        -- Repositionne la fenêtre principale à son dernier emplacement
        if tSavedData.tWindowLocation then
            self.locSavedWindowLoc  = WindowLocation.new(tSavedData.tWindowLocation)
        end
    end
end 

-----------------------------------------------------------------------------------------------
-- Dressing OnLoad
-----------------------------------------------------------------------------------------------
function Dressing:OnLoad()
    -- load our form file
    self.xmlDoc = XmlDoc.CreateFromFile("Dressing.xml")
    self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

-----------------------------------------------------------------------------------------------
-- Dressing Events
-----------------------------------------------------------------------------------------------
function Dressing:OnDocumentReady()

    if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
        self.wndMain = Apollo.LoadForm(self.xmlDoc, "DressingForm", nil, self)
        if self.wndMain == nil then
            Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
            return
        end

        self.wndMain:Show(false,true)

        -- Repositionne la fenêtre à son emplacement sauvé.
        if self.locSavedWindowLoc then
            self.wndMain:MoveToLocation(self.locSavedWindowLoc)
            self.locSavedWindowLoc = nil
        end

        -- if the xmlDoc is no longer needed, you should set it to nil
        -- self.xmlDoc = nil
        -- J'en ai encore besoin (j'ai des LoadForm un peu partout)
        
        -- Register handlers for events, slash commands and timer, etc.
        -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
        Apollo.RegisterSlashCommand("dressing", "OnDressingToggle", self)

        -- Ajoute Dressing dans le menu interface tout en bas à gauche
        Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
        Apollo.RegisterEventHandler("ToggleDressingWindow", "OnDressingToggle", self)
    end
end

function Dressing:OnDressingToggle()
    if self.wndMain:IsVisible() then
        self.locSavedWindowLoc = self.wndMain:GetLocation()
        self.wndMain:Show(false)
    else
        self:RefreshArmorSets()
        self.wndMain:Show(true)
    end
end

function Dressing:OnConfigure()
    self.wndMain:Invoke() -- Clic dans le menu ESC (puis Dressing dans la colonne de gauche)
end

function Dressing:OnInterfaceMenuListHasLoaded()
    -- Ajoute Dressing dans le menu interface tout en bas à gauche
    Event_FireGenericEvent("InterfaceMenuList_NewAddOn","Dressing", {"ToggleDressingWindow", "", ""})
end

-- when close button is clicked
function Dressing:OnClose()
    self.locSavedWindowLoc = self.wndMain:GetLocation()
    self.wndMain:Close() -- hide the window
end

-- when the AddArmorSet button is clicked
function Dressing:OnAddArmorSet()
    self:CreateArmorSet()
    self:RefreshArmorSets()
end

-- when the Delete ArmorSet button is clicked
function Dressing:OnInvokeDeleteArmorSet(wndControl)
    self.wndDeleteConfirm = Apollo.LoadForm(self.xmlDoc, "ArmorSetDeleteNotice", nil, self)
    self.wndDeleteConfirm:SetData(wndControl:GetData())
    self.wndDeleteConfirm:Show(true)
    self.wndDeleteConfirm:ToFront()
end

-- When the Cancel button is clicked in the Delete Armorset delete notice
function Dressing:OnDeleteCancel()
    self.wndDeleteConfirm:Close()
end

-- when the Delete button is clicked in the Delete Armorset delete notice
function Dressing:OnDeleteConfirm()
    table.remove(self.tArmorSets, self.wndDeleteConfirm:GetData())
    self:OnDeleteCancel()
    self:RefreshArmorSets()
end

-- wndControl = ArmorBtn or ItemBtn
-- wndHandler = ArmorBtnIcon or ItemBtnIcon
function Dressing:OnGenerateFakeTooltip(wndControl, wndHandler, _, _, _)
    local tBtnData = wndControl:GetData()

    if tBtnData.nItemId then
        local tItemData = Item.GetDataFromId(tBtnData.nItemId)
        self:OnGenerateTooltip(wndControl, wndHandler, nil, tItemData)
    end
end

-- Copie de InventoryBag:OnGenerateTooltip
function Dressing:OnGenerateTooltip(wndControl, wndHandler, _, item)
    if wndControl ~= wndHandler then return end
    wndControl:SetTooltipDoc(nil)
    if item ~= nil then
        -- Si on veut comparer l'item à celui qui est équipé, il faut récupérer ça avec la ligne ci-dessous
        -- local itemEquipped = item:GetEquippedItemForItemType()
        -- Et remplacer itemCompare = false par itemCompare = itemEquipped
        Tooltip.GetItemTooltipForm(self, wndControl, item, {bPrimary = true, bSelling = false, itemCompare = false})
    end
end

-- Quand on edit le nom d'un set d'armure
function Dressing:OnArmorSetNameChange(wndControl, wndHandler)
    local nArmorSetId = wndControl:GetData()

    if nArmorSetId then
        -- parcourir self.tArmorSets et y écrire le nouveau nom
        for k,v in ipairs(self.tArmorSets) do
            if k == nArmorSetId then
                v.strName = wndControl:GetText()
                break
            end
        end
    end
end

-- when a armor is cliked in the wndArmorSet
-- Affiche la fenetre popdown
function Dressing:OnArmorBtn(wndHandler, wndControl)
    -- wndHandler est ArmorBtn
    self:DrawItemPopdownFrame(wndHandler)
end

-- when a armor is clicked in the popdown window
-- Valide le choix de l'armure
function Dressing:OnChooseItemBtn(wndHandler, wndControl)
    local tArmorBtnAndItemInfo = wndHandler:GetData()
    -- Pour info : tArmorBtnAndItemInfo.nItemId
    -- Pour info : tArmorBtnAndItemInfo.wndArmorBtn

    local tBtnData = tArmorBtnAndItemInfo.wndArmorBtn:GetData()
    -- Pour info : tBtnData.nArmorSetId
    -- Pour info : tBtnData.nArmorSlotId

    -- parcourir self.tArmorSets et y écrire la variable wndArmorBtn.nItemId
    for k,v in ipairs(self.tArmorSets) do
        if k == tBtnData.nArmorSetId then
            for _,j in ipairs(v.tItems) do
                if j.nArmorSlotId == tBtnData.nArmorSlotId then
                    j.nItemId = tArmorBtnAndItemInfo.nItemId
                    break
                end
            end
        end
    end
    self:RefreshArmorSets()
end

-----------------------------------------------------------------------------------------------
-- Dressing Functions
-----------------------------------------------------------------------------------------------

-- Recupère la liste des objets équipés
function Dressing:GetAllEquippedItems(tPlayer)
    if not tPlayer then return end
    local tAllEquippedItems = {}
    local i = 1
    for _,tEquippedItem in pairs(tPlayer:GetEquippedItems()) do
        tAllEquippedItems[i] = tEquippedItem
        i = i + 1
    end
    return tAllEquippedItems
end

-- Recupère la liste des objets équipable pour ce perso dans les sacs
function Dressing:GetAllItemsInBagThatCanBeEquipped(tPlayer)
    if not tPlayer then return end
    local tAllItemsInBagThatCanBeEquipped = {}
    local i = 12
    for _,tItem in pairs(tPlayer:GetInventoryItems()) do
        if (tItem.itemInBag:CanEquip()) then
            tAllItemsInBagThatCanBeEquipped[i] = tItem.itemInBag
            i = i + 1
        end
    end
    return tAllItemsInBagThatCanBeEquipped
end

-- IDEE D'AMÉLIORATION : Mémoriser les objets en banque.

-- Recupère tous les items, équipé et dans les sacs
function Dressing:GetAllItems()
    local tPlayer = GameLib.GetPlayerUnit()
    local t1, t2 = {}, {}
    t1 = self:GetAllEquippedItems(tPlayer)
    t2 = self:GetAllItemsInBagThatCanBeEquipped(tPlayer)
    if not t1 or not t2 then return end
    return self:MergeTables(t1,t2)
--[[
            ["nItemId"] = tEquippedItem:GetItemId(),
            ["nArmorSlotId"] = tEquippedItem:GetSlot(),
            ["strIcon"] = tEquippedItem:GetIcon(),
            ["nItemQuality"] = tEquippedItem:GetItemQuality()
    ]]--
    
end

-- Récupère la liste des objets pour un slot précis
function Dressing:GetAllItemsForThatSlot(nSlotId)
    if not self.tAllItems then return end
    if not nSlotId then return end

    local tSelectedItems = {}
    local nCount = 1
    local v = nil

    for _,v in pairs(self.tAllItems) do
        if v:GetSlot() == nSlotId then
            tSelectedItems[nCount] = v
            nCount = nCount + 1
        end
    end

    return tSelectedItems
end

-- Merge 2 tables en recréant les indexes
function Dressing:MergeTables(t1,t2)
    if not t1 or not t2 then return end
    nCount = table.getn(t1) + 1
    for _,v in pairs(t2) do 
        t1[nCount] = v 
        nCount = nCount + 1
    end
    return t1
end

-- http://lua-users.org/wiki/CopyTable
function Dressing:DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[self:DeepCopy(orig_key)] = self:DeepCopy(orig_value)
        end
        setmetatable(copy, self:DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Créer un nouveau set d'armure
function Dressing:CreateArmorSet()
    table.insert(self.tArmorSets, self:DeepCopy(ktArmorSet))
end

-- retourne la taille qu'un bouton devrait avoir en pixel
-- Exemple : Big = 50px
function Dressing:GetButtonSize(strSize)
    local k,v = nil, nil
    for k, v in pairs(knBtnSize) do
        if k == strSize then
            return v
        end
    end
end

-- Calcul les attribus d'un set (Brutalité, finessse, ...)
function Dressing:GetArmorSetBudget(tItems)
    local tBudget = {}
    tBudget.nArmor = 0
    tBudget.BasedProperties = {}
    if not tItems then return end
    for _,v in ipairs(tItems) do
        if v.nItemId then
            local tItemData = Item.GetDataFromId(v.nItemId)
            tBudget["nArmor"] = tBudget["nArmor"] + tItemData:GetArmor()
            --Item.GetBaseItemPower
            --Item.GetBasePropertiesKeyed
            --Item.GetDurability -- D'autres addons d'occupent d'indiquer si on doit réparer.
            --Item.GetItemPower
            --Item.GetItemQuality
            --Item.GetMaxDurability -- D'autres addons d'occupent d'indiquer si on doit réparer.
            --Item.GetPowerLevel
            --Item.GetPropertiesKeyed
            --Item.GetPropertiesSequential
            --Item.GetPropertyString --Quelle différence avec Item.GetPropertyName ???
            --Item.GetRequiredItemPower

            -- Parfois ceci retourne nil. Certains objet ne doivent pas avoir de propriétés?
            if tItemData:GetDetailedInfo().tPrimary.arBudgetBasedProperties then
                for _,v2 in ipairs(tItemData:GetDetailedInfo().tPrimary.arBudgetBasedProperties) do
                    
                    if tBudget.BasedProperties[v2.eProperty] == nil then
                        tBudget.BasedProperties[v2.eProperty] = v2.nValue
                    else
                        tBudget.BasedProperties[v2.eProperty] = tBudget.BasedProperties[v2.eProperty] + v2.nValue
                    end
                    -- Pour chaque propriété, stocké sa valeur dans le tableau
                    -- 40 = Vitalité
                    -- 0 = Brutalité
                    -- 4 = Acuité
                    -- J'ai trouvé ça dans ToolTipds.lua : Item.GetPropertyName(tCur.eProperty)
                    -- Idée : Est-ce qu'on garde le nSortOrder pour afficher les stats dans
                    -- l'ordre proposé par Carbin pour chaque classe ?

                    --tBudget.BasedProperties[v2.eProperty] = v2.nValue
                    --Print(v2.eProperty .. " = " .. Item.GetPropertyName(v2.eProperty))
                    --Print(v2.eProperty)
                end
            end
        end
    end
    -- SendVarToRover("tBudget", tBudget)
    return tBudget
end


-----------------------------------------------------------------------------------------------
-- DressingForm Functions
-----------------------------------------------------------------------------------------------

-- ReDessine tous les set d'armures
function Dressing:RefreshArmorSets()
    
    -- Récupération des items équipé et dans les sacs
    -- Je refresh ça ici car j'en ai besoin pour chaque bouton plus loin.
    -- Si je met le refresh dans l'event du bouton, on va executé plein de fois cette méthode lourde
    self.tAllItems = self:GetAllItems() 

    -- Ce test est présent aussi dans OnRestore. Mais OnRestore met du temps à s'executer
    -- Sans ce test la boucle ci-dessous plante car self.TArmorSets n'est pas un tableau, mais nil
    if not self.tArmorSets then
        self.tArmorSets = {}
        self:CreateArmorSet() -- Au premier lancement de l'addon.
    end

    -- Efface tous les set d'armures
    self.wndMain:FindChild("MainContainer"):DestroyChildren()
    for k,v in ipairs(self.tArmorSets) do
        local tBudget = self:GetArmorSetBudget(v.tItems)
        self:DrawArmorSet(k, v, tBudget)
    end
end

-- Dessine un set d'armure 
function Dressing:DrawArmorSet(nArmorSetId, tArmorSet, tBudget)
    -- Dessine le cadre du set et son nom
    local wndMainContainer = self.wndMain:FindChild("MainContainer")
    local wndArmorSet = Apollo.LoadForm(self.xmlDoc, "ArmorSet", wndMainContainer, self)
    wndArmorSet:FindChild("ArmorSetFrame"):FindChild("ArmorSetName"):SetText(tArmorSet.strName)
    
    -- Dessine les boutons d'armures et les alignes horizontalement
    self:DrawArmorBtn(nArmorSetId, tArmorSet, wndArmorSet:FindChild("ArmorSetFrame"):FindChild("ArmorSetContainer"))
    wndArmorSet:FindChild("ArmorSetFrame"):FindChild("ArmorSetContainer"):ArrangeChildrenHorz(0)

    -- Stock le numéro de ce set dans le champs texte "nom du set". On en aura besoin pour changer le nom
    wndArmorSet:FindChild("ArmorSetFrame"):FindChild("ArmorSetName"):SetData(nArmorSetId)   
    
    -- Stock le numéro de ce set dans le bouton Delete. On en aura besoin pour savoir que ce bouton correspond à ce set
    wndArmorSet:FindChild("ArmorSetFrame"):FindChild("DeleteArmorSetButton"):SetData(nArmorSetId)

    -- Affichage de la somme des stats des objets
    -- Armure : tBudget.nArmor
    local k,v = nil, nil
    for k,v in ipairs(tBudget.BasedProperties) do
        -- Nom de la stats : Item.GetPropertyName(k)
        -- Valeur de cette stat : v
    end

    wndMainContainer:ArrangeChildrenVert(0)
    wndArmorSet:Show(true)
end

-- Dessine les boutons de sélection d'armures dans la fenêtre wndArmorSet
-- arg 1 : Numéro du set d'armure
-- arg 2 : Contient le tableau d'un set, donc son nom, puis les items qu'il contient
-- arg 3 : Defini la fenetre dans laquelle dessiner les boutons
function Dressing:DrawArmorBtn(nArmorSetId, tArmorSet, wndParent)
    local k,v = nil,nil
    for k,v in ipairs(tArmorSet.tItems) do
        local wndArmorBtnSpacer = Apollo.LoadForm(self.xmlDoc, "ArmorBtnSpacer", wndParent, self)
        -- On va avoir besoin des offsets afin de redimensionner le bouton
        local nLeft, nTop, nRight, nBottom = wndArmorBtnSpacer:GetAnchorOffsets()
        -- Récupère la taille du bouton
        local strBtnSizeInPixels = self:GetButtonSize(v.strBtnSize)

        -- Pas besoin d'ajouter de marge pour écarter les boutons, j'en ai créé une 
        -- de 7px à gauche artificellement en jouant sur la largeur du bouton par rapport
        -- à la largeur de l'icone. Mais du coup les boutons ne sont plus carré, donc il faut
        -- penser à ajouter les 7px quelque part.
        local nNewRight = strBtnSizeInPixels + 7
        local nNewBottom = strBtnSizeInPixels
        wndArmorBtnSpacer:SetAnchorOffsets(nLeft, nTop, nNewRight, nNewBottom) 

        -- Si un objet avait été sauvegardé
        if v.nItemId then
            local tItem = Item.GetDataFromId(v.nItemId)
            wndArmorBtnSpacer:FindChild("ArmorBtn"):FindChild("ArmorBtnIcon"):SetSprite(tItem:GetIcon())
            wndArmorBtnSpacer:FindChild("ArmorBtn"):FindChild("ArmorBtnBorder"):SetSprite(ktItemQualitySprites[tItem:GetItemQuality()])
        else
            wndArmorBtnSpacer:FindChild("ArmorBtn"):FindChild("ArmorBtnIcon"):SetSprite(v.strSpriteWhenEmpty)
        end

        -- Stock le numéro du set d'armure
        -- et le slot d'armure auquel apartient ce bouton
        local tBtnInfo = {
            ["nArmorSetId"] = nArmorSetId, 
            ["nArmorSlotId"] = v.nArmorSlotId,
            ["nItemId"] = v.nItemId
        }
        wndArmorBtnSpacer:FindChild("ArmorBtn"):SetData(tBtnInfo)
    end
end

-- Dessine la popdown frame
-- A partir de la position du bouton qu'on a cliqué, on va afficher les itemBtn dessous.
-- En commencant par le plus à gauche pile en dessous et les autres qui s'étallent sur la droite.
function Dressing:DrawItemPopdownFrame(wndArmorBtn)
    -- 1e parent est ArmorBtnSpacer
    -- 2e parent est ArmorSetContainer
    -- 3e parent est ArmorSetFrame
    local wndItemPopdownFrame = wndArmorBtn:GetParent():GetParent():GetParent():FindChild("ItemPopdownFrame")
    -- Il y a de fortes chances que la fenetre contenait déjà des boutons alors on la vide
    wndItemPopdownFrame:DestroyChildren()

    local tArmorBtnData = wndArmorBtn:GetData()
    local tAllArmorForThatSlot = self:GetAllItemsForThatSlot(tArmorBtnData.nArmorSlotId)
    if not tAllArmorForThatSlot then return end

    -- Pour définir la largeur de la Popdown, il faut connaître le nombre d'armure à afficher
    local nItemsCount = table.getn(tAllArmorForThatSlot)

    -- Comme le btn est dans un spacer, on doit récupérer la position de ce container
    -- car c'est ce dernier qui a une position relative intéressante
    local nLeftPosClickedBtn, _ = wndArmorBtn:GetParent():GetPos()

    -- Comme le bouton est dessiné dans un spacer, qui possède une marge gauche, il faut récupérer la valeur de cette marge
    local nLeftMargin, _ = wndArmorBtn:GetPos()
    local nLeft = nLeftPosClickedBtn + nLeftMargin

    -- Nous avons besoin de savoir combien de place on dispose. Comme notre frame est collé à gauche et à droite du container on peut faire :
    local nAvailableWidth = wndItemPopdownFrame:GetParent():GetWidth()

    -- Pour l'instant un ItemBtn fait 46 px + 2px de marge mais cela pourrait changer. Je n'arrive pas calculer
    -- la taille du bouton depuis ici car il ne sera pas charger avant l'appel à DrawItemBtn
    local nItemBtnSize = 48

    local nNeededWidth = nItemBtnSize * nItemsCount

    if nNeededWidth > nAvailableWidth then
        print("Time to salvage!")
        -- TODO : Trouver une solution plus élégante. Comme proposer une fenetre avec tous les 
        -- objet de cet "itemSlotId" avec possibilité de salvage.
    elseif nNeededWidth <= nAvailableWidth then
        -- Est-ce que la valeur de la marge gauche va nous faire dépasser à droite ?
        if nLeft + nNeededWidth > nAvailableWidth then
            nLeft = nAvailableWidth - nNeededWidth -- Ceci n'a jamais été testé !
        end

        -- Calcul du right anchor. On a besoin d'une valeur négative pour s'éloigner de la limite droite en direction de la gauche
        nRight = 0 - (nAvailableWidth - (nLeft + nNeededWidth))

        -- ArrangeChildren met une légère marge avant d'afficher le premier objet (je crois)
        -- Ainsi la limite droite de la frame se dessine quelques pixels sous le dernier item affiché.
        -- Donc je rajoute une légère marge pour corriger (nRight étant négatif, j'utilise le signe +)
        nRight = nRight + 7
        
        -- On récupère les AnchorOffsets haut et bas
        local _, nTop, _, nBottom = wndItemPopdownFrame:GetAnchorOffsets()

        -- Et finalement, on positionne notre frame
        wndItemPopdownFrame:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
    end

    -- Dessine un bouton par armure disponible pour ce slot.
    -- Arg 1 dit dans quelle fenetre dessiner les boutons
    -- Arg 2 passe l'objet qui correspond à l'armure de ce set qu'on a cliqué
    -- Dans Data de ArmorBtn on a stocké l'id du type de slot d'armure et l'id du set
    -- Arg 3 passe le tableau contenant les items à afficher
    self:DrawItemBtn(wndItemPopdownFrame, wndArmorBtn, tAllArmorForThatSlot)
    -- Arrange les boutons horizontallement et centré.
    wndItemPopdownFrame:ArrangeChildrenHorz(1)
    wndItemPopdownFrame:Show(true)
end

-- Dessinne les boutons de sélection des armures dans la fenetre popup
function Dressing:DrawItemBtn(wndParent, wndArmorBtn, tAllArmorForThatSlot)
    for _,v in pairs(tAllArmorForThatSlot) do
        -- TODO Afficher une armure "vide" qui permet de choisir de vider l'emplacement
        local wndItemBtnSpacer = Apollo.LoadForm(self.xmlDoc, "ItemBtnSpacer", wndParent, self)
        local wndItemBtn = wndItemBtnSpacer:FindChild("ItemBtn")
        wndItemBtn:FindChild("ItemBtnIcon"):SetSprite(v:GetIcon())
        wndItemBtn:FindChild("ItemBtnBorder"):SetSprite(ktItemQualitySprites[v:GetItemQuality()])

        -- Stock les données du bouton d'amure cliqué
        -- Et aussi le numéro d'id de l'armure (id du jeu donc, utile pour GetDataFromId)
        local tArmorBtnAndItemInfo = {}
        tArmorBtnAndItemInfo = {
            ["wndArmorBtn"] = wndArmorBtn,
            ["nItemId"] = v:GetItemId()
        }
        wndItemBtn:SetData(tArmorBtnAndItemInfo)

        -- TODO Generer la tooltip
        wndItemBtn:Show(true)
    end
end

-----------------------------------------------------------------------------------------------
-- Dressing Instance
-----------------------------------------------------------------------------------------------
local DressingInst = Dressing:new()
DressingInst:Init()
