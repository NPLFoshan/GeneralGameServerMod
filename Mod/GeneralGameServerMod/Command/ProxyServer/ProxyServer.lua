--[[
Title: ProxyServer
Author(s):  wxa
Date: 2020-06-12
Desc: Command
use the lib:
------------------------------------------------------------
local ProxyServer = NPL.load("Mod/GeneralGameServerMod/Command/ProxyServer/ProxyServer.lua");
------------------------------------------------------------
]]
local EventEmitter = NPL.load("Mod/GeneralGameServerMod/CommonLib/EventEmitter.lua");

NPL.load("(gl)script/apps/WebServer/npl_http.lua");
local npl_http = commonlib.gettable("WebServer.npl_http");

NPL.load("(gl)script/ide/System/os/GetUrl.lua");

_G.__System_os_GetUrl__ = _G.__System_os_GetUrl__ or System.os.GetUrl;
_G.__is_ggs_http__ = _G.__is_ggs_http__ or npl_http.IsGGSHTTP;

npl_http.IsGGSHTTP = function(msg)
    if (_G.__is_ggs_http__(msg)) then return true end 
    local url = type(msg) == "table" and msg.url or "";
    if (string.find(url, "/paracraft_asset_server_proxy", 1, true) == 1) then return true end 
    if (string.find(url, "/version.php", 1, true) == 1) then return true end 
    if (string.find(url, "/update61/coredownload/list/full.p", 1, true) == 1) then return true end 
    if (string.match(url, "/update61/coredownload/[^/]+/list/full.p")) then return true end 
    return false;
end

local FileCache = NPL.load("./FileCache.lua", IsDevEnv);
local ProxyGetUrl = NPL.load("./ProxyGetUrl.lua", IsDevEnv);
local AssetServerProxy = NPL.load("./AssetServerProxy.lua", IsDevEnv);
local AutoUpdaterProxy = NPL.load("./AutoUpdaterProxy.lua", IsDevEnv);

local __event_emitter__ = EventEmitter:new();
local __System_os_GetUrl_Requesting__ = {};
local function __System_os_GetUrl_Proxy__(url, callback, option)
    if (type(url) ~= "string") then return _G.__System_os_GetUrl__(url, callback, option) end
    __event_emitter__:RegisterOnceEventCallBack(url, callback);
    if (__System_os_GetUrl_Requesting__[url]) then return end
    __System_os_GetUrl_Requesting__[url] = true;
    _G.__System_os_GetUrl__(url, function(rcode, msg, data)
        __System_os_GetUrl_Requesting__[url] = nil;
        __event_emitter__:TriggerOnceEventCallBack(url, rcode, msg, data);
    end, option); 
end

ProxyGetUrl.SetSystemOsGetUrl(_G.__System_os_GetUrl__);
AssetServerProxy.SetSystemOsGetUrl(__System_os_GetUrl_Proxy__);
AutoUpdaterProxy.SetSystemOsGetUrl(__System_os_GetUrl_Proxy__);

local ProxyServer =  commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

function ProxyServer:StartProxy(ip, port)
    local proxy_host = string.format("%s:%s", ip, port);
    if (self.__proxy_host__ == proxy_host) then return end  
    
    print("================start proxy================", proxy_host);

    self.__proxy_host__ = proxy_host;

    AssetServerProxy:StartProxy(ip, port);
    AutoUpdaterProxy:StartProxy(ip, port);
end

function ProxyServer:StopProxy()
    AssetServerProxy:StopProxy();
    AutoUpdaterProxy:StopProxy();
    
    self.__proxy_host__ = nil;
    print("================stop proxy================");
end

ProxyServer:InitSingleton();
ProxyServer:StartProxy("127.0.0.1", "8099");


