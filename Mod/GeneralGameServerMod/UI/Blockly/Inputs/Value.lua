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
local Const = NPL.load("../Const.lua");
local Shape = NPL.load("../Shape.lua");
local Connection = NPL.load("../Connection.lua");
local Input = NPL.load("./Input.lua");
local Value = commonlib.inherit(Input, NPL.export());

local TextMarginUnitCount = Const.TextMarginUnitCount;     -- 文本边距

Value:Property("ClassName", "InputValue");                 -- 类名
Value:Property("Value", "");                               -- 值
Value:Property("Color", "#000000");

function Value:ctor()
end

function Value:Init(block, opt)
    opt = opt or {};
    opt.color = opt.color or "#000000";
    Value._super.Init(self, block, opt);

    self.shadowConnection = Connection:new():Init(block);
    self.inputConnection:SetType("input_connection");

    local shadowType = self:GetShadowType();
    if (not self:IsNumberType(shadowType) and not self:IsTextType(shadowType)) then
        local shadowBlock = self:GetBlockly():GetBlockInstanceByType(shadowType);
        if (shadowBlock and shadowBlock.outputConnection) then
            self:SetInputShadowBlock(shadowBlock);
            shadowBlock:SetInputShadowBlock(true);
            shadowBlock:SetDraggable(false);
            shadowBlock:SetProxyBlock(self:GetBlock());
            shadowBlock:SetFieldsValue(self:GetValue());
            self.inputConnection:Connection(shadowBlock.outputConnection);

            self.inputConnection:SetOnDisconnectionCallback(function()
                self.inputConnection:Connection(shadowBlock.outputConnection);
            end);
        end
    end

    return self;
end

function Value:Render(painter)
    if (self:IsEdit() and not self:IsSelectType()) then return end
    
    local UnitSize = self:GetUnitSize();
    local inputBlock = self:GetInputBlock();
    if (inputBlock) then return inputBlock:Render(painter) end

    local offsetX, offsetY = self:GetOffset();
    painter:Translate(offsetX, offsetY);
    Shape:SetBrush("#ffffff");
    if (self.shadowConnection:IsConnection()) then
        Shape:DrawInputValue(painter, self.widthUnitCount + 2, self.heightUnitCount + 2, -1, -1);
    end
    Shape:DrawInputValue(painter, self.widthUnitCount, self.heightUnitCount);
    painter:SetPen(self:GetColor());
    painter:SetFont(self:GetFont());
    painter:DrawText((Const.BlockEdgeWidthUnitCount + TextMarginUnitCount) * UnitSize, (self.height - self:GetSingleLineTextHeight()) / 2, self:GetShowText());
    painter:Translate(-offsetX, -offsetY);
end

function Value:OnSizeChange()
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
    self.inputConnection:SetGeometry(leftUnitCount, topUnitCount, widthUnitCount, heightUnitCount);
end

function Value:UpdateWidthHeightUnitCount()
    local inputBlock = self:GetInputBlock();
    if (inputBlock) then 
        local _, _, _, _, widthUnitCount, heightUnitCount = inputBlock:UpdateWidthHeightUnitCount();
        return widthUnitCount, heightUnitCount;
    else
        local widthUnitCount = self:GetTextWidthUnitCount(self:GetLabel()) + (TextMarginUnitCount + Const.BlockEdgeWidthUnitCount) * 2;
        return math.min(math.max(widthUnitCount, Const.MinTextShowWidthUnitCount), Const.MaxTextShowWidthUnitCount), Const.LineHeightUnitCount;
    end
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
        if (block.isShadowBlock) then
            self.shadowConnection:Connection(block.outputConnection);
        else
            local inputConnectionConnection = self.inputConnection:Disconnection();
            self.inputConnection:Connection(block.outputConnection);
            self:GetTopBlock():UpdateLayout();
            local inputConnectionConnectionBlock = inputConnectionConnection and inputConnectionConnection:GetBlock();
            if (inputConnectionConnectionBlock and not inputConnectionConnectionBlock:IsInputShadowBlock()) then
                block:GetBlockly():AddBlock(inputConnectionConnectionBlock, true);
            end
        end
        return true;
    end

    return false;
    -- local inputBlock = self:GetInputBlock();
    -- return inputBlock and inputBlock:ConnectionBlock(block);
end

function Value:GetMouseUI(x, y, event)
    if (x < self.left or x > (self.left + self.width) or y < self.top or y > (self.top + self.height)) then return end
    local inputBlock = self:GetInputBlock();
    if (inputBlock) then return inputBlock:GetMouseUI(x, y, event) end
    return self;
end

function Value:IsCanEdit()
    return if_else(self:GetOption().editable == false, false, true);
end

function Value:GetShadowType()
    local option = self:GetOption();
    return option.shadowType or (option.shadow and option.shadow.type) or "";
end

function Value:GetFieldEditType()
    return self:GetShadowType() == "field_dropdown" and "select" or "input";
end

function Value:GetValueAsString()
    if (not self:GetInputBlock()) then 
        if (self:IsNumberType()) then
            return string.format('%s', tonumber(self:GetValue()) or 0);
        elseif (self:IsCodeType()) then
            return string.format('%s', self:GetValue());
        else 
            return string.format('"%s"', self:GetValue());   -- 虚拟一个图块
        end
    end
    return self:GetInputBlock():GetBlockCode();
end

function Value:GetFieldValue() 
    if (not self:GetInputBlock()) then 
        if (self:IsNumberType()) then
            return self:GetNumberValue();
        else 
            return self:GetValue();
        end
    end
    -- return self:GetInputBlock():GetFieldsValue();
    return self:GetInputBlock():GetBlockCode();
end