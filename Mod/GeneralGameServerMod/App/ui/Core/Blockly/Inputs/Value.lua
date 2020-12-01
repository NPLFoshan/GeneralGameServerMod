--[[
Title: Value
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Value = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Inputs/Value.lua");
-------------------------------------------------------
]]

local InputElement = NPL.load("../../Window/Elements/Input.lua", IsDevEnv);
local Shape = NPL.load("../Shape.lua", IsDevEnv);
local Const = NPL.load("../Const.lua", IsDevEnv);
local Input = NPL.load("./Input.lua", IsDevEnv);
local Value = commonlib.inherit(Input, NPL.export());

local UnitSize = Const.UnitSize;

Value:Property("Value", ""); -- 值

function Value:ctor()
end

function Value:Init(block, opt)
    opt = opt or {};

    opt.color = opt.color or "#000000";

    Value._super.Init(self, block, opt);

    self.inputConnection:SetType("value");

    return self;
end


function Value:Render(painter)
    local inputBlock = self:GetInputBlock();
    if (inputBlock) then return inputBlock:Render(painter) end

    local offsetX, offsetY = self:GetOffset();
    painter:Translate(offsetX, offsetY);
    Shape:SetBrush(self:GetBackgroundColor());
    Shape:DrawLeftEdge(painter, self.heightUnitCount);
    Shape:DrawRightEdge(painter, self.heightUnitCount, 0, self.widthUnitCount - Const.BlockEdgeWidthUnitCount);
    painter:SetPen(self:GetBackgroundColor());
    painter:DrawRect(Const.BlockEdgeWidthUnitCount * UnitSize, 0, self.width - Const.BlockEdgeWidthUnitCount * 2 * UnitSize, self.height);

    painter:SetPen(self:GetColor());
    painter:SetFont(self:GetFont());
    painter:DrawText(Const.BlockEdgeWidthUnitCount * Const.UnitSize, (self.height - self:GetSingleLineTextHeight()) / 2, self:GetText());

    painter:Translate(-offsetX, -offsetY);
end

function Value:OnSizeChange()
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
    self.inputConnection:SetGeometry(leftUnitCount, topUnitCount, widthUnitCount, heightUnitCount);
end

function Value:UpdateWidthHeightUnitCount()
    local inputBlock = self:GetInputBlock();
    local widthUnitCount, heightUnitCount = 0, 0;
    if (inputBlock) then 
        _, _, _, _, widthUnitCount, heightUnitCount = inputBlock:UpdateWidthHeightUnitCount();
        return widthUnitCount, heightUnitCount;
    end
    widthUnitCount, heightUnitCount = math.max(self:GetTextWidthUnitCount(self:GetText()), 6) + Const.BlockEdgeWidthUnitCount * 2, Const.LineHeightUnitCount;
    return if_else(self:IsEdit(), math.max(widthUnitCount, self:GetMinEditFieldWidthUnitCount()), widthUnitCount), heightUnitCount;
end

function Value:UpdateLeftTopUnitCount()
    local inputBlock = self:GetInputBlock();
    if (not inputBlock) then return end
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    inputBlock:SetLeftTopUnitCount(leftUnitCount, topUnitCount);
    inputBlock:UpdateLeftTopUnitCount();
end

function Value:ConnectionBlock(block)
    if (block.outputConnection and not block.outputConnection:IsConnection() and self.inputConnection:IsMatch(block.outputConnection)) then
        block:GetBlockly():RemoveBlock(block);
        local inputConnectionConnection = self.inputConnection:Disconnection();
        self.inputConnection:Connection(block.outputConnection);
        self:GetTopBlock():UpdateLayout();
        if (inputConnectionConnection) then
            block:GetBlockly():AddBlock(inputConnectionConnection:GetBlock());
        end
        return true;
    end

    local inputBlock = self:GetInputBlock();
    return inputBlock and block:ConnectionBlock(inputBlock);
end

function Value:GetMouseUI(x, y, event)
    if (x < self.left or x > (self.left + self.width) or y < self.top or y > (self.top + self.height)) then return end
    local inputBlock = self:GetInputBlock();
    if (inputBlock) then return inputBlock:GetMouseUI(x, y, event) end
    return self;
end

function Value:IsCanEdit()
    return true;
end

function Input:GetFieldEditElement(parentElement)
    local InputFieldEditElement = InputElement:new():Init({
        name = "input",
        attr = {
            style = "width: 100%; height: 100%; font-size: 14px;",
            value = self:GetValue(),
            autofocus = true,
        },
    }, parentElement:GetWindow(), parentElement);

    InputFieldEditElement:SetAttrValue("onkeydown.enter", function()
        local value = InputFieldEditElement:GetValue();
        self:SetValue(value);
        self:SetText(value);
        self:FocusOut();
    end)

    return InputFieldEditElement;
end