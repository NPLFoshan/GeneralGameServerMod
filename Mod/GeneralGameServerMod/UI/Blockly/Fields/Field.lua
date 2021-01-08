--[[
Title: Field
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Field = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Field.lua");
-------------------------------------------------------
]]

local Const = NPL.load("../Const.lua", IsDevEnv);
local BlockInputField = NPL.load("../BlockInputField.lua", IsDevEnv);
local Field = commonlib.inherit(BlockInputField, NPL.export());

local MinEditFieldWidth = 120;


Field:Property("Type");                     -- label text, value

function Field:ctor()
end

function Field:Render(painter)
    painter:SetPen(self:GetBlock():GetColor());

    local offsetX, offsetY = self.left + (self.maxWidth - self.width) / 2, self.top + (self.maxHeight - self.height) / 2;
    painter:SetPen(self:GetColor());
    painter:Translate(offsetX, offsetY);
    self:RenderContent(painter);
    painter:Translate(-offsetX, -offsetY);
end

function Field:IsField()
    return true;
end

function Field:IsCanEdit()
    return true;
end

function Field:GetBlockly()
    return self:GetBlock():GetBlockly();
end

function Field:GetFieldValue()
    return self:GetValue();
end

function Field:GetValueAsString()
    return string.format('"%s"', self:GetValue());
end

-- 获取xmlNode
function Field:SaveToXmlNode()
    local xmlNode = {name = "Field", attr = {}};
    local attr = xmlNode.attr;
    
    attr.name = self:GetName();
    attr.label = self:GetLabel();
    attr.value = self:GetValue();

    return xmlNode;
end

function Field:LoadFromXmlNode(xmlNode)
    local attr = xmlNode.attr;

    self:SetLabel(attr.label);
    self:SetValue(attr.value);
end