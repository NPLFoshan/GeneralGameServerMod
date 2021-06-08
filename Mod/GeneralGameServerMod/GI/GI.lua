--[[
Title: GI
Author(s):  wxa
Date: 2021-06-01
Desc: GI 全局对象
use the lib:
------------------------------------------------------------
local GI = NPL.load("Mod/GeneralGameServerMod/GI/GI.lua");
------------------------------------------------------------
]]
-- 先加载相关脚本, 避免相关文件都需要Load 
NPL.load("(gl)script/ide/headon_speech.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/math/ShapeAABB.lua");
NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/PhysicsWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovable.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityNPC.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/SelectionManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/CameraController.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");

-- 加载粒子系统
-- NPL.load("./Game/ParticleSystem/ParticleHeader");

local Listener = NPL.load("./Utility/Listener.lua", IsDevEnv);

local GI = NPL.export();

_G.GI = GI;

GI.Listener = Listener;