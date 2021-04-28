--[[
Title: BlockManager
Author(s): wxa
Date: 2020/6/30
Desc: 文件管理器
use the lib:
-------------------------------------------------------
local BlockManager = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/BlockManager.lua");
-------------------------------------------------------
]]


local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local Helper = NPL.load("../Helper.lua");

local NplBlockManager = NPL.load("./NplBlockManager.lua", IsDevEnv);
local BlockBlockManager = NPL.load("./BlockBlockManager.lua", IsDevEnv);

local LanguagePathMap = {
    ["SystemLuaBlock"] = "Mod/GeneralGameServerMod/UI/Blockly/Blocks/SystemLuaBlock",
    ["SystemNplBlock"] = "Mod/GeneralGameServerMod/UI/Blockly/Blocks/SystemNplBlock",
}

local WorldCategoryAndBlockPath = "";
local CurrentCategoryAndBlockPath = "";
local AllCategoryAndBlockMap = {};

local BlockManager = NPL.export();

local inited = false;

function BlockManager.LoadCategoryAndBlock(filename)
    filename = filename or CurrentCategoryAndBlockPath;

    if (AllCategoryAndBlockMap[filename]) then return AllCategoryAndBlockMap[filename] end
    
    local io = ParaIO.open(filename, "r");
    if(not io:IsValid()) then return nil end 
    local text = io:GetText();
    io:close();
    local CategoryBlockMap = NPL.LoadTableFromString(text);

    local CategoryMap = CategoryBlockMap.AllCategoryMap or {};
    local BlockMap = CategoryBlockMap.AllBlockMap or {};

    local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap(filename);
    local LangCategoryMap, LangBlockMap = CategoryAndBlockMap.AllCategoryMap, CategoryAndBlockMap.AllBlockMap;
    for categoryName, category in pairs(CategoryMap) do
        LangCategoryMap[categoryName] = LangCategoryMap[categoryName] or {name = categoryName};
        commonlib.partialcopy(LangCategoryMap[categoryName], category);
    end
    for blockType, block in pairs(BlockMap) do
        LangBlockMap[blockType] = block;  -- 直接覆盖
        LangCategoryMap[block.category] = LangCategoryMap[block.category] or {name = block.category};
    end

    CategoryAndBlockMap.AllCategoryList = CategoryBlockMap.AllCategoryList or CategoryAndBlockMap.AllCategoryList;
    CategoryAndBlockMap.ToolBoxXmlText = CategoryBlockMap.ToolBoxXmlText or CategoryAndBlockMap.ToolBoxXmlText or BlockManager.GenerateToolBoxXmlText(filename);

    return CategoryAndBlockMap;
end

function BlockManager.SaveCategoryAndBlock(filename)
    filename = filename or CurrentCategoryAndBlockPath;
    local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap(filename);
    CategoryAndBlockMap.ToolBoxXmlText = BlockManager.GenerateToolBoxXmlText(filename);
    
    local text = commonlib.serialize_compact(CategoryAndBlockMap);
    local io = ParaIO.open(filename, "w");
	io:WriteString(text);
    io:close();
end

function BlockManager.GetCategoryAndBlockMap(path)
    path = path or CurrentCategoryAndBlockPath;
    path = LanguagePathMap[path] or path;
    AllCategoryAndBlockMap[path] = AllCategoryAndBlockMap[path] or {
        AllCategoryList = {},
        AllCategoryMap = {},
        AllBlockMap = {},
    };
    return AllCategoryAndBlockMap[path]; 
end

function BlockManager.SetCurrentCategoryAndBlockPath(path)
    CurrentCategoryAndBlockPath = path or WorldCategoryAndBlockPath;
end

function BlockManager.SetCurrentLanguage(lang)
    BlockManager.SetCurrentCategoryAndBlockPath(LanguagePathMap[lang]);
end

function BlockManager.NewBlock(block)
    if (not block.type) then return end
    local allBlockMap = BlockManager.GetLanguageBlockMap();
    allBlockMap[block.type] = {
        type = block.type,
        category = block.category,
        color = block.color,
        output = block.output,
        previousStatement = block.previousStatement,
        nextStatement = block.nextStatement,
        message = block.message,
        arg = block.arg,
        -- func_description = block.func_description,
        code_description = block.code_description,
        xml_text = block.xml_text,
    };
    BlockManager.SaveCategoryAndBlock();
end

function BlockManager.DeleteBlock(blockType)
    local allBlockMap = BlockManager.GetLanguageBlockMap();
    allBlockMap[blockType] = nil;
    BlockManager.SaveCategoryAndBlock();
end

function BlockManager.GetLanguageCategoryMap(path)
    return BlockManager.GetCategoryAndBlockMap(path).AllCategoryMap;
end

function BlockManager.GetLanguageBlockMap(path)
    return BlockManager.GetCategoryAndBlockMap(path).AllBlockMap;
end

local function OnWorldLoaded()
    local directory = CommonLib.ToCanonicalFilePath(ParaIO.GetCurDirectory(0) .. ParaWorld.GetWorldDirectory() .. "/blockly/");
    local filename = CommonLib.ToCanonicalFilePath(directory .. "/CustomBlock");
    if (filename == WorldCategoryAndBlockPath) then return end
    WorldCategoryAndBlockPath = filename;
    CurrentCategoryAndBlockPath = WorldCategoryAndBlockPath;
    -- 确保目存在
    ParaIO.CreateDirectory(directory);
    --加载数据
    BlockManager.LoadCategoryAndBlock();
end

local function OnWorldUnloaded()
end

function BlockManager.StaticInit()
    if (inited) then return BlockManager end
    inited = true;

    for _, path in pairs(LanguagePathMap) do
        BlockManager.LoadCategoryAndBlock(path);
    end

    GameLogic:Connect("WorldLoaded", nil, OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", nil, OnWorldUnloaded, "UniqueConnection");
    
    OnWorldLoaded();

    return BlockManager;
end

function BlockManager.GetToolBoxXmlText(path)
    return BlockManager.GetCategoryAndBlockMap(path).ToolBoxXmlText;
end

function BlockManager.GenerateToolBoxXmlText(path)
    local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap(path);
    local AllCategoryList, AllCategoryMap, AllBlockMap = CategoryAndBlockMap.AllCategoryList, CategoryAndBlockMap.AllCategoryMap, CategoryAndBlockMap.AllBlockMap;
    local blockTypeMap, categoryMap = {}, {};
    for _, category in ipairs(AllCategoryList) do
        categoryMap[category.name] = category;
        category.blocktypes = category.blocktypes or {};
        local blocktypes = {};
        for index, blocktype in ipairs(category.blocktypes) do
            if (AllBlockMap[blocktype]) then
                blockTypeMap[blocktype] = true;
                table.insert(blocktypes, #blocktypes + 1, blocktype);
            end
        end
        category.blocktypes = blocktypes;
    end

    local isChange = false;
    for blocktype, block in pairs(AllBlockMap) do
        if (not blockTypeMap[blocktype] and not block.hideInToolbox) then
            -- 分类不存在则添加分类
            if (not categoryMap[block.category]) then
                categoryMap[block.category] = AllCategoryMap[block.category] or {name = block.category};
                categoryMap[block.category].blocktypes = categoryMap[block.category].blocktypes or {};
                table.insert(AllCategoryList, categoryMap[block.category]);
            end
            -- 添加块
            local blocktypes = categoryMap[block.category].blocktypes;
            table.insert(blocktypes, #blocktypes + 1, blocktype);
            isChange = true;
        end
    end
    local toolbox = {name = "toolbox"};
    for _, categoryItem in ipairs(AllCategoryList) do
        local category = {
            name = "category",
            attr = {name = categoryItem.name, color = categoryItem.color, text = categoryItem.text},
        }
        table.insert(toolbox, #toolbox + 1, category);
        for _, blocktype in ipairs(categoryItem.blocktypes) do 
            table.insert(category, #category + 1, {name = "block", attr = {type = blocktype}});
        end
    end
    local xmlText = Helper.Lua2XmlString(toolbox, true);

    return xmlText;
end

function BlockManager.ParseToolBoxXmlText(path, xmlText)
    local xmlNode = ParaXML.LuaXML_ParseString(xmlText);
    local toolboxNode = xmlNode and commonlib.XPath.selectNode(xmlNode, "//toolbox");
    if (not toolboxNode) then return end
    local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap(path);
    
    local AllCategoryList = {};
    for _, categoryNode in ipairs(toolboxNode) do
        if (categoryNode.attr and categoryNode.attr.name) then
            local category_attr = categoryNode.attr;
            local category = {
                name = category_attr.name,
                text = category_attr.text,
                color = category_attr.color,
                blocktypes = {},
            }
            table.insert(AllCategoryList, #AllCategoryList + 1, category);
            local blocktypes = category.blocktypes;
            for _, blockTypeNode in ipairs(categoryNode) do
                if (blockTypeNode.attr and blockTypeNode.attr.type) then
                    local blocktype = blockTypeNode.attr.type;
                    if (AllBlockMap[blocktype]) then
                        table.insert(blocktypes, #blocktypes + 1, blocktype);
                    end
                end
            end
        end
    end
    CategoryAndBlockMap.AllCategoryList = AllCategoryList;
    BlockManager.SaveCategoryAndBlock(path);
    return AllCategoryList;
end

function BlockManager.GetLanguageCategoryListAndMap(path)
    local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap(path);
    if (#CategoryAndBlockMap.AllCategoryList > 0) then
        return CategoryAndBlockMap.AllCategoryList, CategoryAndBlockMap.AllCategoryMap;
    end

    local allCategoryMap, allBlockMap = CategoryAndBlockMap.AllCategoryMap, CategoryAndBlockMap.AllBlockMap;
    local categoryList = {};
    local categoryMap = {};
    for _, category in pairs(allCategoryMap) do
        local data = {
            name = category.name,
            text = category.text,
            color = category.color,
            blocktypes = {},
        }
        categoryMap[data.name] = data;
        table.insert(categoryList, data);
    end
    for block_type, block in pairs(allBlockMap) do 
        if (block_type ~= "") then
            local categoryName = block.category;
            local category = categoryMap[categoryName];
            if (not category) then
                category = {name = categoryName, blocktypes = {}}
                categoryMap[categoryName] = category;
                table.insert(categoryList, category);
            end
            table.insert(category.blocktypes, #(category.blocktypes) + 1, block_type);
        end
    end
    for _, category in ipairs(categoryList) do
        table.sort(category.blocktypes);
    end
    return categoryList, categoryMap;
end

function BlockManager.GetBlockOption(blockType, lang)
    local BlockMap = BlockManager.GetBlockMap(lang);
    if (BlockMap and BlockMap[blockType]) then return BlockMap[blockType] end
    
    for _, path in pairs(LanguagePathMap) do
        local BlockMap = BlockManager.GetLanguageBlockMap(path);
        if (BlockMap and BlockMap[blockType]) then return BlockMap[blockType] end
    end

    return nil;
end

function BlockManager.GetBlockMap(lang)
    if (lang == "npl") then 
        if (NplBlockManager.IsUseSystemNplBlock()) then
            return BlockManager.GetLanguageBlockMap(LanguagePathMap["SystemNplBlock"]);
        else
            return NplBlockManager.GetBlockMap(); 
        end
    end
    if (lang == "block") then return BlockBlockManager.GetBlockMap() end
    if (LanguagePathMap[lang]) then return BlockManager.GetLanguageBlockMap(LanguagePathMap[lang]) end

    return BlockManager.GetLanguageBlockMap(WorldCategoryAndBlockPath);
end

function BlockManager.GetCategoryListAndMap(lang)
    if (lang == "npl") then 
        if (NplBlockManager.IsUseSystemNplBlock()) then
            return BlockManager.GetLanguageCategoryListAndMap(LanguagePathMap["SystemNplBlock"]);
        else
            return NplBlockManager.GetCategoryListAndMap();
        end
    end
    if (lang == "block") then return BlockBlockManager.GetCategoryListAndMap() end
    if (LanguagePathMap[lang]) then return BlockManager.GetLanguageCategoryListAndMap(LanguagePathMap[lang]) end

    return BlockManager.GetLanguageCategoryListAndMap(WorldCategoryAndBlockPath);
end

BlockManager.StaticInit();
