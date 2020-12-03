--[[
Title: Element
Author(s): wxa
Date: 2020/6/30
Desc: 元素类
use the lib:
-------------------------------------------------------
local Element = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Element.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/Rect.lua");
NPL.load("(gl)script/ide/math/Point.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");
local Rect = commonlib.gettable("mathlib.Rect");
local Point = commonlib.gettable("mathlib.Point");

local Style = NPL.load("./Style/Style.lua", IsDevEnv);
local Layout = NPL.load("./Layout/Layout.lua", IsDevEnv);
local ElementUI = NPL.load("./ElementUI.lua", IsDevEnv);
local Element = commonlib.inherit(ElementUI, NPL.export());

local ElementDebug = GGS.Debug.GetModuleDebug("ElementDebug").Enable();   --Enable  Disable
local ElementHoverDebug = GGS.Debug.GetModuleDebug("ElementHoverDebug").Enable();
local ElementFocusDebug = GGS.Debug.GetModuleDebug("ElementFocusDebug").Disable();

Element:Property("Window");     -- 元素所在窗口
Element:Property("Attr", {});   -- 元素属性
Element:Property("XmlNode");    -- 元素XmlNode
Element:Property("ParentElement");                        -- 父元素
Element:Property("Layout");                               -- 元素布局
Element:Property("Style");                                -- 样式
Element:Property("StyleSheet");                           -- 元素样式表
Element:Property("BaseStyle");                            -- 默认样式, 基本样式
Element:Property("Selector");                             -- 选择器集
Element:Property("Rect");                                 -- 元素几何区域矩形
Element:Property("Name", "Element");                      -- 元素名
Element:Property("TagName");                              -- 标签名


-- 构造函数
function Element:ctor()
    self.childrens = {};   -- 子元素列表

    -- 设置布局
    self:SetLayout(Layout:new():Init(self));
    self:SetRect(Rect:new():init(0,0,0,0));
    self:SetSelector({});
    self:SetStyle(Style:new());
end

-- 是否是元素
function Element:IsElement()
    return true;
end

-- 是否是组件
function Element:IsComponent()
    return false;
end

-- 是否是窗口
function Element:IsWindow()
    return false;
end

-- 获取元素
function Element:GetElementByTagName(tagname)
    return self:GetWindow():GetElementManager():GetElementByTagName(tagname);
end

-- 创建元素
function Element:CreateFromXmlNode(xmlNode, window, parent)
    local PageElement = type(xmlNode) == "table" and self:GetElementByTagName(xmlNode.name) or self:GetWindow():GetElementManager():GetTextElement();
    return PageElement:new():Init(xmlNode, window, parent);
end

-- 元素初始化
function Element:Init(xmlNode, window, parent)
    self:InitElement(xmlNode, window, parent);
    self:InitChildElement(xmlNode, window);
    return self;
end

-- 初始化基本属性
function Element:InitElement(xmlNode, window, parent)
    -- 设置窗口
    self:SetWindow(window);
    -- 设置父元素
    self:SetParentElement(parent);
    -- 先清除子元素
    self:ClearChildElement();

    -- 设置元素属性
    self:SetAttr({});
    if (type(xmlNode) ~= "table") then 
        self:SetTagName(nil);
        self:SetAttr({});
        self:SetXmlNode(xmlNode);
    else 
        self:SetTagName(xmlNode.name);
        self:SetXmlNode(xmlNode);
        if (type(xmlNode.attr) == "table") then
            for key, val in pairs(xmlNode.attr) do self:GetAttr()[key] = val end
        end
    end

    -- 初始化样式表
    if (not self:GetStyleSheet()) then
        self:SetStyleSheet(self:GetWindow():GetStyleManager():NewStyleSheet());
    end
    self:GetStyleSheet():SetInheritStyleSheet(parent and parent:GetStyleSheet());

    -- 设置继承样式
    self:GetStyle():Init(self:GetBaseStyle(), parent and parent:GetStyle());
end

-- 初始化子元素
function Element:InitChildElement(xmlNode, window)
    if (not xmlNode) then return end
    -- 创建子元素
    for i, childXmlNode in ipairs(xmlNode) do
        local childElement = self:CreateFromXmlNode(childXmlNode, window, self);
        if (childElement) then 
            -- ElementDebug.Format("InitChildElement Child Element Name = %s, TagName = %s", childElement:GetName(), childElement:GetTagName());
        else 
            ElementDebug("元素不存在", xmlNode);
        end
        -- self:InsertChildElement(childElement);
        table.insert(self.childrens, childElement);
        childElement:SetParentElement(self);
    end
end

-- 元素加载
function Element:LoadElement()
    self:OnLoadElementBeforeChild();

    self:OnLoadElement();
    for child in self:ChildElementIterator() do
        child:LoadElement();
    end

    self:OnLoadElementAfterChild();
end

function Element:OnLoadElementBeforeChild()
end

function Element:OnLoadElement()
end

function Element:OnLoadElementAfterChild()
end


-- 上一个兄弟元素
function Element:GetPrevSiblingElement()
    local parentElement = self:GetParentElement();
    if (not parentElement) then return end
    local prevSiblingElement = nil;
    for i, child in ipairs(parentElement.childrens) do
        if (child == self) then return prevSiblingElement end
        prevSiblingElement = if_else(child:IsExist(), child, prevSiblingElement);
    end
end

-- 下一个兄弟元素
function Element:GetNextSiblingElement()
    local parentElement = self:GetParentElement();
    if (not parentElement) then return end
    local nextSiblingElement = nil;
    for i = #self.childrens, 1, -1 do
        child = self.childrens[i];
        if (child == self) then return nextSiblingElement end
        nextSiblingElement = if_else(child:IsExist(), child, nextSiblingElement);
    end
end

-- 获取元素位置
function Element:GetChildElementPos(childElement)
    for i, child in ipairs(self.childrens) do 
        if (child == childElement) then return i end 
    end
    return 0;
end

-- 添加子元素
function Element:InsertChildElement(pos, childElement)
    local element = childElement or pos;
    -- 验证元素的有效性
    if (type(element) ~= "table" or not element.IsElement or not element:IsElement()) then return end
    -- 添加子元素
    if (childElement) then
        table.insert(self.childrens, pos, element);
    else 
        table.insert(self.childrens, element);
    end
    -- 设置子元素的父元素
    element:SetParentElement(self);

    -- 应用元素样式
    -- element:ApplyElementStyle();

    -- 更新元素布局
    element:Attach();
end

-- 移除子元素
function Element:RemoveChildElement(pos)
    if (type(pos) == "table" and pos.IsElement and pos:IsElement()) then
        for i = 1, #self.childrens do
            if (self.childrens[i] == pos) then 
                table.remove(self.childrens, i);
                pos:SetParentElement(nil);
                pos:OnDetach();
                return;
            end
        end
    end
    pos = pos or self:GetChildElementCount();
    if (type(pos) ~= "number" or pos < 1 or pos > self:GetChildElementCount()) then return end
    local element = self.childrens[pos];
    table.remove(self.childrens, pos);
    if (element) then 
        element:Detach();
        element:SetParentElement(nil);
    end
end

-- 清除子元素
function Element:ClearChildElement()
    for _, child in ipairs(self.childrens) do
        child:Detach();
    end

    self.childrens = {};
end

-- 获取子元素数量
function Element:GetChildElementCount()
    return #self.childrens;
end

-- 获取子元素列表
function Element:GetChildElementList()
    return self.childrens;
end

-- 遍历 默认渲染序  false 事件序
function Element:ChildElementIterator(isRender, filter)
    local list = {};
    for _, child in ipairs(self.childrens) do
        if (child:IsExist()) then
            table.insert(list, child);
        end
    end

    isRender = isRender == nil or isRender;
    local function comp(child1, child2)
        local style1, style2 = child1:GetStyle() or {}, child2:GetStyle() or {};
        local zindex1, zindex2 = style1["z-index"] or 0, style2["z-index"] or 0;
        -- 函数返回true, 表两个元素需要交换位置
        local sort = if_else(zindex1 == zindex2, style1.float ~= nil and style2.float == nil, zindex1 < zindex2);  -- true 默认升序  z-index 相同 含有float优先
        return if_else(isRender, sort, not sort);
    end
    -- table.sort(list, comp);
    -- 自行排序 table.sort 不稳定报错
    for i = 1, #list do
        for j = i + 1, #list do 
            if (comp(list[i], list[j])) then
                list[i], list[j] = list[j], list[i];
            end
        end
    end
    
    if (self.horizontalScrollBar) then table.insert(list, isRender and (#list + 1) or 1, self.horizontalScrollBar) end
    if (self.verticalScrollBar) then table.insert(list, isRender and (#list + 1) or 1, self.verticalScrollBar) end

    local i, size = 0, #list;
    local function iterator() 
        i = i + 1;
        
        if (i > size) then return end
        
        if (type(filter) == "function" and not filter(list[i])) then return iterator() end

        return list[i];
    end

    return iterator;
end

-- 元素添加至文档树
function Element:Attach()
    self:OnAttach();

    for _, child in ipairs(self.childrens) do
        child:Attach();
    end
end

-- 元素脱离文档树
function Element:Detach()
    self:OnDetach();

    for _, child in ipairs(self.childrens) do
        child:Detach();
    end
end

-- 添加DOM树中
function Element:OnAttach()
    self:ApplyElementStyle();
end

-- 从DOM树中移除
function Element:OnDetach()
end

-- 创建样式
function Element:ApplyElementStyle()
    local style = self:GetStyle();

    -- 全局样式表
    self:GetWindow():GetStyleManager():ApplyElementStyle(self, style);

    -- 局部样式表
    self:GetStyleSheet():ApplyElementStyle(self, style);
    -- ElementDebug.If(self:GetName() == "Text", "class", style);
    -- 内联样式
    style:AddString(self:GetAttrValue("style"));
    -- ElementDebug.If(self:GetAttrStringValue("id") == "debug", style:GetCurStyle());
    -- ElementDebug.If(self:GetName() == "Text", "inline", style);

    -- 选择默认样式
    return style:SelectNormalStyle();
end

-- 元素布局更新前回调
function Element:OnBeforeUpdateLayout()
end
-- 子元素布局更新前回调
function Element:OnBeforeUpdateChildLayout()
end
-- 子元素布局更新后回调
function Element:OnAfterUpdateChildLayout()
end
-- 元素布局更新回调
function Element:OnUpdateLayout()
end

-- 元素布局更新后回调
function Element:OnAfterUpdateLayout()
end
-- 更新布局, 先进行子元素布局, 再布局当前元素
function Element:UpdateLayout()
    -- 是否正在更新布局
    if (self.isUpdateLayout) then return end
    self.isUpdateLayout = true;

    -- 布局更新前回调
    if (self:OnBeforeUpdateLayout()) then 
        self.isUpdateLayout = false;
        return; 
    end

    -- 选择合适样式
    self:SelectStyle();
    -- 准备布局
    local layout = self:GetLayout();
    layout:PrepareLayout();

    -- 是否布局
    if (not layout:IsLayout()) then 
        self.isUpdateLayout = false;
        return; 
    end

    -- 子元素布局更新前回调
    local isUpdatedChildLayout = self:OnBeforeUpdateChildLayout();

    -- 执行子元素布局  子元素布局未更新则进行更新
    if (not isUpdatedChildLayout) then
		for childElement in self:ChildElementIterator() do
			childElement:UpdateLayout();
		end
    end
    
	-- 执行子元素布局后回调
    self:OnAfterUpdateChildLayout();

    -- 更新元素布局
    self:OnUpdateLayout();

    -- 调整布局
    self:GetLayout():Update();

    -- 元素布局更新后回调
    self:OnAfterUpdateLayout();

    self.isUpdateLayout = false;
    return;
end

-- 真实内容大小更改
function Element:OnRealContentSizeChange()
    if (not self:GetWindow()) then return end
    local ElementManager = self:GetWindow():GetElementManager();
    local layout, ScrollBar = self:GetLayout(), ElementManager.ScrollBar;
    local width, height = layout:GetWidthHeight();
    local contentWidth, contentHeight = layout:GetContentWidthHeight();
    local realContentWidth, realContentHeight = layout:GetRealContentWidthHeight();
    local isOverflowX, isOverflowY = layout:IsOverflowX(), layout:IsOverflowY();

    -- ElementDebug.If(
    --     self:GetAttrStringValue("id") == "debug", 
    --     isOverflowX, isOverflowY, 
    --     width, height, contentWidth, contentHeight, realContentWidth, realContentHeight);

    if (isOverflowX) then self.horizontalScrollBar = self.horizontalScrollBar or ScrollBar:new():Init({name = "ScrollBar", attr = {direction = "horizontal"}}, self:GetWindow(), self) end

    if (self.horizontalScrollBar) then
        self.horizontalScrollBar:SetVisible(isOverflowX);
        self.horizontalScrollBar:SetScrollWidthHeight(width, height, contentWidth, contentHeight, realContentWidth, realContentHeight);
    end

    if (isOverflowY) then self.verticalScrollBar = self.verticalScrollBar or ScrollBar:new():Init({name = "ScrollBar", attr = {direction = "vertical"}}, self:GetWindow(), self) end

    if (self.verticalScrollBar) then
        self.verticalScrollBar:SetVisible(isOverflowY);
        self.verticalScrollBar:SetScrollWidthHeight(width, height, contentWidth, contentHeight, realContentWidth, realContentHeight);
    end
end

function Element:OnScroll(scrollEl)
    self:UpdateWindowPos(true);
end

-- 获取属性值
function Element:GetAttrValue(attrName, defaultValue)
    local attr = self:GetAttr();
    return attr[attrName] or defaultValue;
end

-- 获取数字属性值
function Element:GetAttrNumberValue(attrName, defaultValue)
    return tonumber(self:GetAttrValue(attrName)) or defaultValue;
end

-- 获取数字属性值
function Element:GetAttrStringValue(attrName, defaultValue)
    local value = self:GetAttrValue(attrName, defaultValue)
    return value and tostring(value);
end

-- 获取布尔属性值
function Element:GetAttrBoolValue(attrName, defaultValue)
    local value = self:GetAttrValue(attrName);
    if (type(value) == "boolean") then return value end
    if (type(value) ~= "string") then return defaultValue end
    return value == "true";
end

-- 获取函数属性
function Element:GetAttrFunctionValue(attrName, defaultValue)
    local value = self:GetAttrValue(attrName, defaultValue);
    if (type(value) == "string") then
        local code_func, errmsg = loadstring(value);
        if (code_func) then
            setfenv(code_func, self:GetWindow():GetG());
            value = code_func;
        end
    end

    return type(value) == "function" and value or nil;
end

-- 调用事件函数
function Element:CallAttrFunction(attrName, defaultValue, ...)
    local func = self:GetAttrFunctionValue(attrName, defaultValue);
    if (not func) then return end
    func(...)
end

-- 元素属性值更新
function Element:OnAttrValueChange(attrName, attrValue, oldAttrValue)
end

-- 设置属性值
function Element:SetAttrValue(attrName, attrValue)
    local attr = self:GetAttr();
    local oldAttrValue = attr[attrName];
    attr[attrName] = attrValue;
    self:OnAttrValueChange(attrName, attrValue, oldAttrValue);
end

-- 获取内联文本
function Element:GetInnerText()
    local function GetInnerText(xmlNode)
        if (not xmlNode) then return "" end
        if (type(xmlNode) == "string") then return xmlNode end
        local text = "";
        for _, childXmlNode in ipairs(xmlNode) do
            text = text .. GetInnerText(childXmlNode);
        end 
        return text;
    end
    return GetInnerText(self:GetXmlNode());
end

-- 遍历每个元素
function Element:ForEach(callback)
    local function forEach(element)
        callback(element);
        for child in element:ChildElementIterator() do
            forEach(child);
        end
    end
    forEach(self);
end

-- 获取元素通过名称
function Element:GetElementsByName(name)
    local list = {};

    self:ForEach(function(element)
        if (element:GetAttrValue("name") == name) then
            table.insert(list, element);
        end
    end)

    return list;
end

-- 获取元素通过Id
function Element:GetElementsById(id)
    local list = {};

    self:ForEach(function(element)
        if (element:GetAttrValue("id") == id) then
            table.insert(list, element);
        end
    end)

    return list;
end

-- 获取元素通过Id
function Element:GetElementById(id)
    return self:GetElementsById(id)[1];
end

-- 获取定位元素
function Element:GetPositionElements()
    local list = {};
    local function GetPositionElements(element)
        if (element:GetLayout():IsPositionElement()) then
            table.insert(list, element);
        end
        for childElement in element:ChildElementIterator(false) do
            GetPositionElements(childElement);
        end
    end
    GetPositionElements(self);
    return list;
end