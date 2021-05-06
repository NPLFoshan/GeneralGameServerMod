--[[
Title: ContextMenu
Author(s): wxa
Date: 2020/6/30
Desc: ContextMenu
use the lib:
-------------------------------------------------------
local ContextMenu = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/ContextMenu.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Window/Element.lua", IsDevEnv);
local Helper = NPL.load("./Helper.lua", IsDevEnv);
local Const = NPL.load("./Const.lua", IsDevEnv);

local ContextMenu = commonlib.inherit(Element, NPL.export());

ContextMenu:Property("Name", "ContextMenu");
ContextMenu:Property("MenuType", "blockly");
ContextMenu:Property("Blockly");

local MenuItemWidth = 120;
local MenuItemHeight = 30;
local block_menus = {
    { text = "复制", cmd = "copy"},
    { text = "删除", cmd = "delete"},
}

local blockly_menus = {
    { text = "撤销", cmd = "undo"},
    { text = "重做", cmd = "redo"},
    { text = "导出工具栏XML", cmd = "export_toolbox_xml_text"},
    { text = "生成宏示教代码", cmd = "export_macro_code"},
}

function ContextMenu:Init(xmlNode, window, parent)
    ContextMenu._super.Init(self, xmlNode, window, parent);

    self.selectedIndex = 0;
    return self;
end

function ContextMenu:GetMenus()
    local menuType = self:GetMenuType();
    if (menuType == "block") then return block_menus end

    return blockly_menus;
end

function ContextMenu:GetMenuItem(index)
    local menus = self:GetMenus();
    return menus[index];
end

function ContextMenu:GetMenuItemCount()
    local menus = self:GetMenus();
    return #menus;
end

function ContextMenu:RenderContent(painter)
    local x, y = self:GetPosition();
    local menus = self:GetMenus();

    painter:SetBrush("#285299")
    painter:DrawRect(x, y + self.selectedIndex * MenuItemHeight, MenuItemWidth, MenuItemHeight);
    painter:SetBrush(self:GetColor());
    for i, menu in ipairs(menus) do
        painter:DrawText(x + 20 , y + (i - 1) * MenuItemHeight + 8, menu.text);
    end
end

function ContextMenu:SelectMenuItem(event)
    local mouseMoveX, mouseMoveY = self:GetRelPoint(event.x, event.y);
    self.selectedIndex = math.floor(mouseMoveY / MenuItemHeight);
    self.selectedIndex = math.min(self.selectedIndex, self:GetMenuItemCount() - 1);
    return self.selectedIndex;
end

function ContextMenu:OnMouseDown(event)
    event:Accept();
    self:Hide();
    local menuitem = self:GetMenuItem(self:SelectMenuItem(event) + 1);
    if (not menuitem) then return end
    local blockly = self:GetBlockly();
    if (menuitem.cmd == "copy") then
        blockly:handlePaste();
    elseif (menuitem.cmd == "delete") then
        blockly:handleDelete();
    elseif (menuitem.cmd == "undo") then
        blockly:Undo();
    elseif (menuitem.cmd == "redo") then
        blockly:Redo();
    elseif (menuitem.cmd == "export_toolbox_xml_text") then
        self:ExportToolboxXmlText();
    elseif (menuitem.cmd == "export_macro_code") then
        self:ExportMacroCode();
    end 
end

function ContextMenu:ExportMacroCode()
    local blockly = self:GetBlockly();
    local toolbox = blockly:GetToolBox();
    local category_list = toolbox:GetCategoryList();
    local blocks = blockly:GetBlocks();
    local params = {};
    local width, height = blockly:GetSize();
    local ToolBoxWidth = blockly.isHideToolBox and 0 or Const.ToolBoxWidth;
    local viewLeft, viewTop = math.floor(width / 5),  math.floor(height / 5);
    local ViewRight, viewBottom = width - viewLeft, height - viewTop;
    local oldOffsetX, oldOffsetY, oldCategoryName = 0, 0, category_list[1] and category_list[1].name or "";
    local function ExportBlockMacroCode(block)
        -- 调整工作区
        local left, top = oldOffsetX + block.left - ToolBoxWidth, oldOffsetY + block.top;
        if (left < viewLeft or left > ViewRight or top < viewTop or top > viewBottom) then
            local newOffsetX, newOffsetY = viewLeft + ToolBoxWidth - block.left, viewTop - block.top;
            params[#params + 1] = {action = "SetBlocklyOffset", oldOffsetX = oldOffsetX, oldOffsetY = oldOffsetY, newOffsetX = newOffsetX, newOffsetY = newOffsetY};
            oldOffsetX, oldOffsetY = newOffsetX, newOffsetY;
        end
        -- 校准分类
        local newCategoryName = block:GetOption().category or "";
        if (oldCategoryName ~= newCategoryName) then
            params[#params + 1] = {action = "SetToolBoxCategory", oldCategoryName = oldCategoryName, newCategoryName = newCategoryName}; 
            oldCategoryName = newCategoryName;
        end
        -- 滚动图块使其可见 TODO: 在拖拽图块中自动实现

        -- 拖拽图块
        local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
        params[#params + 1] = {action = "SetBlockPos", blockType = block:GetType(), leftUnitCount = leftUnitCount, topUnitCount = topUnitCount};

        -- 编辑图块字段
        for _, opt in ipairs(block.inputFieldOptionList) do
            local inputfield = block:GetInputField(opt.name);
            if (inputfield:IsField() and inputfield:GetDefaultValue() ~= inputfield:GetValue()) then
                params[#params + 1] = {action = "SetFieldInput", value = inputfield:GetValue()};
            elseif (inputfield:IsInput() and inputfield:GetInputBlock()) then
                ExportBlockMacroCode(inputfield:GetInputBlock());
            elseif (inputfield:IsInput() and inputfield:GetDefaultValue() ~= inputfield:GetValue()) then
                params[#params + 1] = {action = "SetInputInput", value = inputfield:GetValue()};
            end
        end
    end
    for _, block in ipairs(blocks) do
        local nextBlock = block;
        while (nextBlock) do
            ExportBlockMacroCode(nextBlock);
            nextBlock = nextBlock:GetNextBlock();
        end
    end
    local text = "";
    local windowName = blockly:GetWindow():GetWindowName();
    local blocklyId = blockly:GetAttrStringValue("id");
    for _, param in ipairs(params) do
        param.blocklyId = blocklyId;
        local params_text = commonlib.serialize_compact({
            window_name = windowName,
            simulator_name = "BlocklySimulator",
            virtual_event_params = param,
        });
        text = text .. string.format("UIWindowEventTrigger(%s)\n", params_text);
        text = text .. string.format("UIWindowEvent(%s)\n", params_text);
    end
    ParaMisc.CopyTextToClipboard(text);
end

function ContextMenu:ExportToolboxXmlText()
    local blockTypeMap = {};
    self:GetBlockly():ForEach(function(ui)
        if (ui:IsBlock()) then
            blockTypeMap[ui:GetType()] = true;
        end
    end);
    local categoryList = self:GetBlockly():GetToolBox():GetCategoryList();
    local toolbox = {name = "toolbox"};
    for _, categoryItem in ipairs(categoryList) do
        local category = {
            name = "category",
            attr = {name = categoryItem.name},
        }
        table.insert(toolbox, #toolbox + 1, category);
        for _, blocktype in ipairs(categoryItem.blocktypes) do 
            if (blockTypeMap[blocktype]) then
                table.insert(category, #category + 1, {name = "block", attr = {type = blocktype}});
            end
        end
        if (#category == 0) then table.remove(toolbox, #toolbox) end
    end
    local xmlText = Helper.Lua2XmlString(toolbox, true);
    ParaMisc.CopyTextToClipboard(xmlText);
    GameLogic.AddBBS("Blockly", "图块工具栏XML已拷贝至剪切板");
end

function ContextMenu:OnMouseMove(event)
    event:Accept();
    self:SelectMenuItem(event);
end

function ContextMenu:OnMouseUp(event)
    event:Accept();
end

-- 定宽不定高
function ContextMenu:OnUpdateLayout()
    self:GetLayout():SetWidthHeight(MenuItemWidth, self:GetMenuItemCount() * MenuItemHeight);
end

function ContextMenu:Show(menuType)
    self:SetMenuType(menuType);
    local menus = self:GetMenus();
    if (#menus == 0) then return end

    self.selectedIndex = 0;
    self:SetVisible(true);
    self:UpdateLayout();
end

function ContextMenu:Hide()
    self:SetVisible(false);
end

 