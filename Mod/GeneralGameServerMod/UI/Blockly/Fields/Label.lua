--[[
Title: Label
Author(s): wxa
Date: 2020/6/30
Desc: 标签字段
use the lib:
-------------------------------------------------------
local Label = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Label.lua");
-------------------------------------------------------
]]

local Const = NPL.load("../Const.lua", IsDevEnv);
local Field = NPL.load("./Field.lua", IsDevEnv);
local Label = commonlib.inherit(Field, NPL.export());

Label:Property("Color", "#ffffff");

function Label:Init(block, opt)
    Label._super.Init(self, block, opt);

    self:SetValue(opt and opt.text or "");

    return self;
end

function Label:RenderContent(painter)
    painter:SetPen(self:GetColor());
    painter:SetFont(self:GetFont());
    painter:DrawText(0, (self.height - self:GetSingleLineTextHeight()) / 2, self:GetValue());
end

function Label:UpdateWidthHeightUnitCount()
    return self:GetTextWidthUnitCount(self:GetValue()), self:GetTextHeightUnitCount();
end
