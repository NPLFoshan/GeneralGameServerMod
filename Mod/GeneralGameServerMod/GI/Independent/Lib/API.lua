--[[
Title: API
Author(s):  wxa
Date: 2021-06-01
Desc: 模块API的简化
use the lib:
------------------------------------------------------------
local API = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/API.lua");
------------------------------------------------------------
]]

local API = module("API");

-- 定义快捷方式接口
function GetNetModule()
    return require("Net");
end

function SetSharedData(key, val)
    GetNetModule():SetShareData({[key] = val})
end

function GetSharedData(key, default_val)
    return GetNetModule():GetShareData()[key] or default_val;
end

function OnSharedDataChanged(key, callback)
    return GetNetModule():OnShareDataItem(key, callback);
end

function GetNetStateModule()
    return require("NetState");
end

function GetUserData(key, default_val)
    return GetNetStateModule():GetUserState()[key] or default_val;
end

function SetUserData(key, val)
    GetNetStateModule():GetUserState()[key] = val;
end

function GetAllUserData()
    return GetNetStateModule():GetAllUserState();
end

function RegisterNetworkEvent(msgname, callback)
    GetNetModule():On(msgname, callback);
end

function TriggerNetworkEvent(msgname, msgdata)
    GetNetModule():Emit(msgname, msgdata);
end

function RegisterNetConnectEvent(callback)
    GetNetModule():Connect(callback);
end

function GetNetPlayerModule()
    return require("NetPlayer");
end

function GetNetRankModule()
    return require("NetRank");
end

function GetNetEntityModule()
    return require("NetEntity");
end

-- 获取KeepWorkAPI
local __keepwork_api__ = nil;
function GetKeepworkAPI()
    if (__keepwork_api__) then return __keepwork_api__ end 

    __keepwork_api__ = require("Http"):new():Init({
        baseURL = "https://api.keepwork.com/core/v0/",
        headers = {
            ["content-type"] = "application/json", 
        },
        transformRequest = function(request)
            request.headers["Authorization"] = string.format("Bearer %s", GetSystemUser().keepworktoken);
        end
    });

    return __keepwork_api__;
end

local __Net_api__ = nil;
function GetNetAPI()
    if (__Net_api__) then return __Net_api__ end 
    __Net_api__ = require("Http"):new():Init({
        baseURL = IsDevEnv and "http://127.0.0.1:9000/api/v0/" or "http://ggs.keepwork.com:9000/api/v0/",
        headers = {["content-type"] = "application/json"},
    });

    return __Net_api__;
end

function GetAllEntity()
    return require("Entity"):GetAllEntity();
end

function CreateEntity(opts)
    return require("Entity"):new():Init(opts);
end

function DestoryEntityByKey(key)
    local entity = require("Entity"):GetEntityByKey(key);
    if (not entity) then return end
    entity:Destroy();
end

function ShowEntityEditor(key)
    local entity = require("Entity"):GetEntityByKey(key);
    if (not entity) then return end 
    local screen_width = GetScreenSize();
    local width = math.floor(screen_width / 2);
    SetSceneMarginRight(width);
    ShowWindow({
        __entity__ = entity,
        OnClose = function()
            SetSceneMarginRight(0);
        end,
    }, {
        parent = GetRootUIObject(),
        url = "%gi%/Independent/UI/EntityEditor.html",
        width = width,
        height = "100%",
        alignment = "_rt",
    });
end

function CreateGoods(opts)
    return require("Goods"):new():Init(opts);
end
