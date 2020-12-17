--[[
Title: Vue
Author(s): wxa
Date: 2020/6/30
Desc: 组件基类
use the lib:
-------------------------------------------------------
local Vue = NPL.load("Mod/GeneralGameServerMod/UI/Vue/Vue.lua");
-------------------------------------------------------
]]

local Window = NPL.load("../Window/Window.lua", IsDevEnv);
local ElementManager = NPL.load("../Window/ElementManager.lua");
local Helper = NPL.load("./Helper.lua", IsDevEnv);
local Scope = NPL.load("./Scope.lua", IsDevEnv);
local ComponentScope = NPL.load("./ComponentScope.lua", IsDevEnv);
local Table = NPL.load("./Table.lua", IsDevEnv);
local Compile = NPL.load("./Compile.lua", IsDevEnv);
local Component = NPL.load("./Component.lua", IsDevEnv);
local Slot = NPL.load("./Slot.lua", IsDevEnv);

ElementManager:RegisterByTagName("Component", Component);
ElementManager:RegisterByTagName("Slot", Slot);

local Vue = commonlib.inherit(Window, NPL.export());


function Vue:LoadXmlNodeByUrl(url)
    return {
        name = "html",
        attr = {
            style = "width: 100%; height:100%;",
            -- id = "debug"
        }, 
        {
            name = "component",
            attr = {
                src = url,
            }
        }
    }
end

function Vue:LoadXmlNodeByTemplate(template)
    return {
        name = "html",
        attr = {
            style = "width: 100%; height:100%;",
        }, 
        {
            name = "component",
            template = template,
            attr = {
            }
        }
    }
end

-- 扩展全局方法
function Vue:ExtendG(G)
    G.ShowWindow = function(G, params)
        params = params or {};
        if (not params.url) then return end
        params.G = G;
        
        return Vue:new():Show(params);
    end

    G.GetGlobalScope = function()
        if (not G.GlobalScope) then
            G.GlobalScope = Scope:__new__();
            G.GlobalScope:__set_metatable_index__(G);
        end
        return G.GlobalScope;
    end

    G.table = Table;  -- 替换全局table以便支持scope特性
end

function Vue:NewG(g)
    local G = Vue._super.NewG(self, g);

    self:ExtendG(G);

    return G;
end

function Vue.Register(tagname, tagclass)
    ElementManager:RegisterByTagName(tagname, Component.Extend(tagclass))
end

function Vue.SetPathAlias(alias, path)
    Helper.SetPathAlias(alias, path);
end

-- 静态初始化
local function StaticInit()
    Vue.Register("WindowTitleBar", "%vue%/Components/WindowTitleBar.html");
end


StaticInit();
