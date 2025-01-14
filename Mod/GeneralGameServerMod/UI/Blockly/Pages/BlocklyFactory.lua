

local BlockManager = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/Blocks/BlockManager.lua");
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");

BlockManager.SetCurrentCategoryAndBlockPath();

local Blockly = nil;
local BlocklyEditor = nil;
local BlocklyPreview = nil;
local BlocklyToolBox = nil;
local BlockOption = {};
LangOptions = {{"定制世界图块", "CustomWorldBlock"}, {"系统 NPL 图块", "SystemNplBlock"}, {"系统 GI 图块", "SystemGIBlock"}, {"系统 UI 图块", "SystemUIBlock"}, {"系统 Lua 图块", "SystemLuaBlock"}};
CurrentLang = "CustomWorldBlock";
TabIndex = "block";
ContentType = "block"; -- block blockly
BlocklyCode = "";
BlockType = "";
BlockDefineCode = "";
ToolBoxXmlText = "";
ToolBoxBlockList = {};
ToolBoxCategoryList = {};
CategoryOptions = {};
CategoryName = "";
AllCategoryList, AllBlockList = {}, {};
SearchCategoryOptions = {{"全部", ""}};
SearchCategoryName = "";
SearchBlockType = "";

function SelectSearchCategory()
    OnChange();
end

function OnSearchBlockTypeChange(value)
    SearchBlockType = value;
    OnChange();
end

function OnSelectLang()
    BlockManager.SetCurrentLanguage(CurrentLang);
    OnChange();
end

function ClickUpdateToolBoxXmlText()
    BlockManager.ParseToolBoxXmlText(ToolBoxXmlText);
    ToolBoxXmlText = BlockManager.GetToolBoxXmlText();
    GameLogic.AddBBS("Blockly", "工具栏更新成功");
end 

local function GetCategory(categoryName)
    local AllCategoryList = BlockManager.GetLanguageCategoryList();
    for _, categoryItem in ipairs(AllCategoryList) do
        if (categoryItem.name == categoryName) then
            return categoryItem;
        end
    end
end

local function GetToolBoxBlockList()
    local AllCategoryList = BlockManager.GetLanguageCategoryList();
    local blocklist = {};
    for _, category in ipairs(AllCategoryList) do
        if (category.name == CategoryName) then
            for index, block in ipairs(category) do 
                table.insert(blocklist, {blockType = block.blocktype, categoryName = category.name, hideInToolbox = block.hideInToolbox, order = index, index = index});
            end
            break;
        end
    end
    return blocklist;
end

function OnSelectCategoryName()
    ToolBoxBlockList = GetToolBoxBlockList();
end

function OnToolBoxBlockOrderChange(block)
    local value = tonumber(block.order);
    if (not value or value == block.index) then return end
    local category = GetCategory(block.categoryName)
    if (not category) then return end
    local maxValue = #category;
    value = math.max(1, math.min(value, maxValue));
    if (value == block.index) then return end 
    local blockItem = category[block.index];
    table.remove(category, block.index);
    table.insert(category, value, blockItem);
    OnToolBoxChange();
    BlockManager.SaveCategoryAndBlock();
end

function SwitchToolBoxBlockVisible(block)
    local category = GetCategory(block.categoryName)
    if (not category) then return end
    block.hideInToolbox = not block.hideInToolbox;
    category[block.index].hideInToolbox = block.hideInToolbox;
    OnToolBoxChange();
    BlockManager.SaveCategoryAndBlock();
end

local function GetToolBoxCategoryList()
    local AllCategoryList = BlockManager.GetLanguageCategoryList();
    local categories = {};
    local options = {};
    for index, category in ipairs(AllCategoryList) do
        table.insert(categories, {name = category.name, color = category.color, hideInToolbox = category.hideInToolbox, index = index, order = index});
        table.insert(options, #options + 1, category.name);
    end
    CategoryOptions = options;
    return categories;
end

function SwitchToolBoxCategoryVisible(data)
    local category = GetCategory(data.name);
    if (not category) then return end
    data.hideInToolbox = not data.hideInToolbox;
    category.hideInToolbox = data.hideInToolbox;
    OnToolBoxChange();
    BlockManager.SaveCategoryAndBlock();
end

function OnToolBoxCategoryColorChange(data)
    local category = GetCategory(data.name);
    if (not category) then return end
    category.color = data.color;
    OnToolBoxChange();
    BlockManager.SaveCategoryAndBlock();
end

function OnToolBoxCategoryOrderChange(data)
    local AllCategoryList = BlockManager.GetLanguageCategoryList();
    local value = tonumber(data.order);
    if (not value or value == data.index) then return end
    local maxValue = #AllCategoryList;
    value = math.max(1, math.min(value, maxValue));
    if (value == data.index) then return end 
    local categoryItem = AllCategoryList[data.index];
    table.remove(AllCategoryList, data.index);
    table.insert(AllCategoryList, value, categoryItem);
    OnToolBoxChange();
    BlockManager.SaveCategoryAndBlock();
end

function ClickTabNavItemBtn(tabindex)
    TabIndex = tabindex;
    OnChange();
end 

function GetTabNavItemStyle(tabindex)
    return TabIndex == tabindex and "color: #ffffff;" or "";
end

function GetCategoryColorStyle(category)
    return string.format([[width: 20px; height: 20px; background-color: %s; border-radius: 10px; margin-top: 4px; margin-left: 8px;]], category.color);
end


function OnToolBoxChange()
    if (ContentType ~= "toolbox") then return end
    ToolBoxCategoryList = GetToolBoxCategoryList();
    ToolBoxBlockList = GetToolBoxBlockList();
    BlocklyToolBox:OnAttrValueChange("language");
end

function OnBlockChange()
    if (ContentType ~= "block") then return end
    OnBlockListChange();
    OnCategoryListChange();
    OnToolBoxXmlTextChange();
    OnBlockDefineCodeChange();
end

function SetContentType(contentType)
    ContentType = contentType;
    if (ContentType == "blockly" and Blockly) then
        Blockly:OnAttrValueChange("language");
    elseif (ContentType == "block") then 
        OnBlockChange();
    elseif (ContentType == "toolbox") then
        OnToolBoxChange();
    end
end

function GetHeaderBtnStyle(contentType)
    if (ContentType == contentType) then return "border-bottom: 1px solid #ffffff" end
    return "";
end

local function EditBlock(blockType)
    if (BlockType == blockType) then return end
    BlockType = blockType;
    local AllBlockMap = BlockManager.GetLanguageBlockMap();
    LoadBlockXmlText(AllBlockMap[BlockType]);
    OnBlocklyEditorChange();
end 

function SelectBlock(blockType)
    EditBlock(blockType);
end 

function ClickSaveBlockBtn()
    BlockOption.xml_text = BlocklyEditor:SaveToXmlNodeText();
    if (BlockType == "") then return end
    local isExist = false;
    for i, opt in ipairs(AllBlockList) do
        if (opt.type == BlockType) then
            isExist = true;
            break;
        end
    end 
    if (not isExist) then
        table.insert(AllBlockList, {type = BlockOption.type, category = BlockOption.category});
    end

    BlockManager.NewBlock(BlockOption);
    OnChange();
end

function ClickDeleteBlockBtn(blocktype)
    blocktype = blocktype or BlockType;
    if (blocktype == "") then return end
    for i, block in ipairs(AllBlockList) do 
        if (block.type == blocktype) then
            table.remove(AllBlockList, i);
            break;
        end
    end
    BlockManager.DeleteBlock(blocktype);
    OnToolBoxXmlTextChange();
    if (blocktype == BlockType) then
        BlockType = "";
        BlocklyEditor:Reset();
        OnBlocklyEditorChange();
    end
end

function ClickEditBlockBtn(blockType)
    EditBlock(blockType);
end

function LoadBlockXmlText(block)
    if (not block or not block.xml_text) then return end
    BlocklyEditor:LoadFromXmlNodeText(block.xml_text);
end

function GenerateBlockOption()
    local rawcode, prettycode = BlocklyEditor:GetCode();
    local prettycode = string.gsub(prettycode, "\t", "    ");
    local G = {message = "", arg = {}, field_count = 0, type="", category = "图块", color = "#2E9BEF", output = false, previousStatement = true, nextStatement = true, connections = {}};
    local func, errmsg = loadstring(prettycode);
    -- print(prettycode);
    if (not func) then
        print("============================loadstring error==========================", errmsg);
        print(prettycode)
        return nil;
    end
    setfenv(func, G);
    local isError = false;
    xpcall(function()
        func();
    end, function(errinfo) 
        print("ERROR:", errinfo);
        DebugStack();
        isError = true;
    end);
    if (isError) then return nil end 

    -- echo(G, true)
    G.message = string.gsub(G.message, "^ ", "");
    
    local connections = G.connections;
    G.connections = nil;
    if (connections.output and connections.output ~= "") then G.output = connections.output end
    if (connections.previousStatement and connections.previousStatement ~= "") then G.previousStatement = connections.previousStatement end
    if (connections.nextStatement and connections.nextStatement ~= "") then G.nextStatement = connections.nextStatement end
    for _, arg in ipairs(G.arg) do
        if (arg.type == "input_value" or arg.type == "input_statement") then
            local argname = arg.name;
            if (connections[argname] and connections[argname] ~= "") then 
                arg.check = connections[argname];
            end
        end
    end 

    return G;
end

function PreviewBlockOption(blockOption)
    BlocklyPreview:DefineBlock(commonlib.deepcopy(blockOption));
    local block = BlocklyPreview:GetBlockInstanceByType(blockOption.type);
    BlocklyPreview:ClearBlocks();
    block:SetLeftTopUnitCount(10, 10);
    block:UpdateLayout();
    BlocklyPreview:AddBlock(block);
end

function OnBlocklyEditorChange()
    local option = GenerateBlockOption();
    if (not option) then return end
    BlockOption = option;
    PreviewBlockOption(BlockOption);
    OnBlockDefineCodeChange();

    local AllBlockMap = BlockManager.GetLanguageBlockMap();
    if (BlockOption.type ~= BlockType) then
        BlockType = BlockOption.type;
        if (AllBlockMap[BlockOption.type]) then
            Page.ShowMessageBoxPage({
                text = string.format("图块 %s 已经存在, 是否加载已有信息?", BlockOption.type),
                confirm = function()
                    LoadBlockXmlText(AllBlockMap[BlockOption.type]);
                end,
            });
        end
    end
end

function OnBlocklyChange()
    if (not Blockly) then return end
    local rawcode, prettycode = Blockly:GetCode();
    local language = Blockly:GetLanguage();
    if (language == "SystemNplBlock") then
        BlocklyCode = string.gsub(prettycode, "\t", "    ");
    else
        BlocklyCode = rawcode;
    end
end


function OnToolBoxXmlTextChange()
    if (Blockly) then
        Blockly:OnAttrValueChange("language");
    end
    if (TabIndex ~= "toolbox" or ContentType ~= "block") then return end
    ToolBoxXmlText = BlockManager.GetToolBoxXmlText();
    ToolBoxBlockList = GetToolBoxBlockList();
end

function GenerateBlockDefineCode(option)
    local code_description = option.code_description or "";
    code_description = string.gsub(code_description, "\n+$", "");
    code_description = string.gsub(code_description, "^\n+", "");
    local block_define_code = string.format([==[
{
    type = "%s",
    category = "%s",
    color = "%s",
    output = %s,
    previousStatement = %s, 
    nextStatement = %s,
    message = "%s",
    code_description = [[%s]],
    %s,
}]==], option.type, option.category, option.color, option.output, option.previousStatement, option.nextStatement, option.message, code_description, commonlib.dump(option.arg, "arg", false, 2));

    return block_define_code;
end

function OnBlockDefineCodeChange()
    if (TabIndex ~= "code" or ContentType ~= "block") then return end
    BlockDefineCode = GenerateBlockDefineCode(BlockOption);
end

function OnChange()
    OnBlockChange();
    OnToolBoxChange();
end

function OnBlockListChange()
    if (TabIndex ~= "block" or ContentType ~= "block") then return end
    local AllBlockMap = BlockManager.GetLanguageBlockMap();
    local allBlockList = {};
    for _, block in pairs(AllBlockMap) do
        if (SearchCategoryName == "" or SearchCategoryName == block.category) then
            local blocktype = string.lower(block.type);
            if (SearchBlockType == "" or (string.find(blocktype, SearchBlockType, 1, true))) then
                table.insert(allBlockList, {type = block.type, category = block.category});
            end
        end
    end
    table.sort(allBlockList, function(block1, block2)
        return block1.category == block2.category and (block1.type < block2.type) or (block1.category < block2.category);
    end);
    AllBlockList = allBlockList;

    local AllCategoryMap = BlockManager.GetLanguageCategoryMap();
    SearchCategoryOptions = {{"全部", ""}};
    for _, category in pairs(AllCategoryMap) do
        table.insert(SearchCategoryOptions, {category.text or category.name, category.name});
    end
end

function OnCategoryListChange()
    if (TabIndex ~= "category" or ContentType ~= "block") then return end
    local AllCategoryMap = BlockManager.GetLanguageCategoryMap();
    AllCategoryList = {};
    for _, category in pairs(AllCategoryMap) do
        table.insert(AllCategoryList, {name = category.name, text = category.text, color = category.color or "#ffffff"});
    end
end

function OnReady()
    OnSelectLang();
    Blockly = GetRef("Blockly");
    BlocklyEditor = GetRef("BlocklyEditor");
    BlocklyPreview = GetRef("BlocklyPreview");
    BlocklyToolBox = GetRef("BlocklyToolBox");
    OnBlocklyEditorChange();
end