

local BlockManager = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/Blocks/BlockManager.lua");
local __ToolBoxXmlText__ = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/Blocks/ToolBoxXmlText.lua");
local Helper = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/Helper.lua");

_G.Language = _G.Language == "npl" and "SystemNplBlock" or _G.Language;
_G.IsCustomLanguage = BlockManager.IsCustomLanguage(_G.Language);
BlockManager.SetCurrentLanguage(_G.Language);

-- print(_G.Language, _G.IsCustomLanguage)
-- print(__ToolBoxXmlText__.GetXmlText(_G.Language))

local DefaultToolBoxXmlText = _G.IsCustomLanguage and BlockManager.GenerateToolBoxXmlText(nil) or __ToolBoxXmlText__.GetXmlText(_G.Language);
ContentType = "xmltext"; -- block category
ToolBoxXmlText = (_G.XmlText and _G.XmlText ~= "") and _G.XmlText  or DefaultToolBoxXmlText;
ToolBoxBlockList = {};
ToolBoxCategoryList = {};
CategoryOptions = {};
CategoryName = "";
AllBlockDisabledMode = false;
local AllCategoryList, AllCategoryMap, AllBlockMap = {}, {}, {};
-- local AllCategoryList = commonlib.deepcopy(BlockManager.GetLanguageCategoryList());
-- local AllCategoryMap = commonlib.deepcopy(BlockManager.GetLanguageCategoryMap());
-- local AllBlockMap = commonlib.deepcopy(BlockManager.GetLanguageBlockMap());

local function GetToolBoxBlockList()
    local blocklist = {};
    local category = AllCategoryMap[CategoryName] or {};
    for index, block in ipairs(category) do 
        table.insert(blocklist, {blockType = block.blocktype, categoryName = category.name, hideInToolbox = block.hideInToolbox, order = index, index = index});
    end
    return blocklist;
end

local function GetToolBoxCategoryList()
    local categories = {};
    for index, category in ipairs(AllCategoryList) do
        table.insert(categories, {name = category.name, color = category.color, hideInToolbox = category.hideInToolbox, index = index, order = index, blockCount = category.blockCount});
    end
    return categories;
end

local function ParseToolBoxXmlText()
    local xmlNode = ParaXML.LuaXML_ParseString(ToolBoxXmlText);
    local toolboxNode = xmlNode and commonlib.XPath.selectNode(xmlNode, "//toolbox");
    local categorylist, categorymap, allblockmap = {}, {}, {};

    if (not toolboxNode) then return {}, {} end
    local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap();

    for _, categoryNode in ipairs(toolboxNode) do
        if (categoryNode.attr and categoryNode.attr.name) then
            local category_attr = categoryNode.attr;
            local default_category = CategoryAndBlockMap.AllCategoryMap[category_attr.name] or {};
            local category = categorymap[category_attr.name] or {};
            category.name = category.name or category_attr.name or default_category.name;
            category.text = category.text or category_attr.text or default_category.text;
            category.color = category.color or category_attr.color or default_category.color;
            -- local hideInToolbox = if_else(category_attr.hideInToolbox ~= nil, category_attr.hideInToolbox == "true", default_category.hideInToolbox and true or false);
            category.hideInToolbox = category_attr.hideInToolbox == "true";
            if (not categorymap[category.name]) then
                table.insert(categorylist, #categorylist + 1, category);
                categorymap[category.name] = category;
            end            
            for _, blockTypeNode in ipairs(categoryNode) do
                if (blockTypeNode.attr and blockTypeNode.attr.type) then
                    local blocktype = blockTypeNode.attr.type;
                    local hideInToolbox = blockTypeNode.attr.hideInToolbox == "true";
                    local disabled = blockTypeNode.attr.disabled == "true";
                    if (CategoryAndBlockMap.AllBlockMap[blocktype]) then
                        local block_opt = {blocktype = blocktype, hideInToolbox = hideInToolbox, disabled = disabled};
                        table.insert(category, block_opt);
                        allblockmap[blocktype] = block_opt;
                    end
                end
            end
        end
    end

    local categoryoptions = {};
    for categoryName in pairs(categorymap) do
        table.insert(categoryoptions, #categoryoptions + 1, categoryName);
    end
    CategoryOptions = categoryoptions;
    CategoryName = categoryoptions[1] or "";

    return categorylist, categorymap, allblockmap;
end

local function GenerateToolBoxXmlText()
    local toolbox = {name = "toolbox"};
    for _, categoryItem in ipairs(AllCategoryList) do
        local category = {
            name = "category",
            attr = {name = categoryItem.name, color = categoryItem.color, text = categoryItem.text, hideInToolbox = categoryItem.hideInToolbox and "true" or nil},
        }
        table.insert(toolbox, #toolbox + 1, category);
        for _, blockItem in ipairs(categoryItem) do 
            if (AllBlockDisabledMode or not blockItem.disabled) then
                table.insert(category, #category + 1, {
                    name = "block", 
                    attr = {
                        type = blockItem.blocktype, 
                        hideInToolbox = blockItem.hideInToolbox and "true" or nil,
                        disabled = AllBlockDisabledMode and (blockItem.disabled and "true" or "false") or nil,
                    },
                });
            end
        end
    end
    local xmlText = Helper.Lua2XmlString(toolbox, true);
    return xmlText;
end

function ClickResetXmlText()
    ToolBoxXmlText = DefaultToolBoxXmlText;
end

function ClickDisabledModeXmlText()
    AllBlockDisabledMode = not AllBlockDisabledMode;
    AllCategoryList, AllCategoryMap, AllBlockMap = ParseToolBoxXmlText();

    if (AllBlockDisabledMode) then
        ToolBoxXmlText = DefaultToolBoxXmlText;
        AllCategoryList, AllCategoryMap = ParseToolBoxXmlText();
        for _, category in ipairs(AllCategoryList) do
            for _, block in ipairs(category) do
                local blocktype = block.blocktype;
                local custom_block = AllBlockMap[blocktype];
                if (not custom_block) then
                    block.disabled = true;
                else
                    block.disabled = custom_block.disabled;
                end
            end
        end
    end
    
    ToolBoxXmlText = GenerateToolBoxXmlText();
end

function OnToolBoxCategoryOrderChange(category)
    category.order = tonumber(category.order) or category.index;
    category.order = math.max(1, math.min(#ToolBoxCategoryList, category.order));
    if (category.order == category.index) then return end
    local order, index = category.order, category.index;
    table.remove(ToolBoxCategoryList, index);
    table.insert(ToolBoxCategoryList, order, category);
    for index, category in ipairs(ToolBoxCategoryList) do
        category.order, category.index = index, index;
    end
    category = AllCategoryList[index];
    table.remove(AllCategoryList, index);
    table.insert(AllCategoryList, order, category);
end

function OnToolBoxCategoryColorChange(category)
    AllCategoryMap[category.name].color = category.color;
end

function SwitchToolBoxCategoryVisible(category)
    category.hideInToolbox = not category.hideInToolbox;
    AllCategoryMap[category.name].hideInToolbox = category.hideInToolbox;
end

function OnSelectCategoryName()
    ToolBoxBlockList = GetToolBoxBlockList();
end


function OnToolBoxBlockOrderChange(block)
    block.order = tonumber(block.order) or block.index;
    block.order = math.max(1, math.min(#ToolBoxBlockList, block.order));
    if (block.order == block.index) then return end
    local order, index = block.order, block.index;
    table.remove(ToolBoxBlockList, index);
    table.insert(ToolBoxBlockList, order, block);
    for index, block in ipairs(ToolBoxBlockList) do
        block.order, block.index = index, index;
    end
    local category = AllCategoryMap[CategoryName];
    block = category[index];
    table.remove(category, index);
    table.insert(category, order, block);
end

function SwitchToolBoxBlockVisible(block)
    block.hideInToolbox = not block.hideInToolbox;
    local category = AllCategoryMap[CategoryName];
    category[block.index].hideInToolbox = block.hideInToolbox;
end

function ClickConfirm()
    if (ContentType ~= "xmltext") then
        ToolBoxXmlText = GenerateToolBoxXmlText();
    end
    if (type(_G.OnConfirm) == "function") then 
        _G.OnConfirm(ToolBoxXmlText);
    end 
    CloseWindow();
end

function OnReady()
end

function SetContentType(contentType)
    if (ContentType == "xmltext" and contentType ~= "xmltext") then
        AllCategoryList, AllCategoryMap = ParseToolBoxXmlText();
        ToolBoxBlockList = GetToolBoxBlockList();
        ToolBoxCategoryList = GetToolBoxCategoryList();
    end
    if (ContentType ~= "xmltext" and contentType == "xmltext") then
        ToolBoxXmlText = GenerateToolBoxXmlText();
    end
    ContentType = contentType;
end

function GetHeaderBtnStyle(contentType)
    if (ContentType == contentType) then return "border-bottom: 1px solid #ffffff" end
    return "";
end

function GetCategoryColorStyle(category)
    return string.format([[width: 20px; height: 20px; background-color: %s; border-radius: 10px; margin-top: 4px; margin-left: 8px;]], (not category.color or category.color == "") and "#ffffff" or category.color);
end
