--[[
Title: Tutorial Context
Author(s): wxa
Date: 2015/12/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/TutorialContext.lua");
local TutorialContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.TutorialContext");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/EditContext.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameMode.lua");
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local TutorialContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditContext"), NPL.export());

TutorialContext:Property({"Name", "TutorialContext"});
TutorialContext:Property("TutorialSandbox");
TutorialContext:Property("ModeCanDestroyBlock", true);
TutorialContext:Property("ModeCanRightClickToCreateBlock", true);
TutorialContext:Property("ModeHasJumpRestriction", true);
TutorialContext:Property("CanFly", false, "IsCanFly");
TutorialContext:Property("CanJump", false, "IsCanJump");
TutorialContext:Property("CanClickScene", true, "IsCanClickScene");


local shift_pressed, ctrl_pressed, alt_pressed = nil;

function TutorialContext:Init(tutorialSandbox)
	self:SetTutorialSandbox(tutorialSandbox);
	return self;
end

function TutorialContext:handleCodeGlobalKeyPressEvent(event)
	if(GameLogic.GetCodeGlobal():BroadcastKeyPressedEvent(event.keyname)) then
		event:accept();
		return true;
	end
end 

function TutorialContext:HandleGlobalKey(event)
	-- 禁用全局按键行为
	TutorialContext._super.HandleGlobalKey(self, event);
end

function TutorialContext:handlePlayerKeyEvent(event)
	TutorialContext._super.handlePlayerKeyEvent(self, event);
end

function TutorialContext:keyPressEvent(event)
	if (self:GetTutorialSandbox():OnKeyPressEvent(event)) then return end

	local dik_key, ctrl_pressed, shift_pressed, alt_pressed = event.keyname, event.ctrl_pressed, event.shift_pressed, event.alt_pressed;
	if(not ctrl_pressed and not alt_pressed and not shift_pressed) then
		if(dik_key == "DIK_SPACE") then
			if (self:IsCanJump()) then GameLogic.DoJump() end
			return self:handleCodeGlobalKeyPressEvent(event);
		elseif(dik_key == "DIK_F") then
			if(self:IsCanFly()) then GameLogic.ToggleFly() end
			return self:handleCodeGlobalKeyPressEvent(event);
		end
	end

	if(dik_key == "DIK_S" and ctrl_pressed) then
		GameLogic.RunCommand("/save");
		return self:handleCodeGlobalKeyPressEvent(event);
	end

	TutorialContext._super.keyPressEvent(self, event);
end

function TutorialContext:mousePressEvent(event)
	if (not self:IsCanClickScene()) then return end

	TutorialContext._super.mousePressEvent(self, event);
end

function TutorialContext:mouseMoveEvent(event)
	if (not self:IsCanClickScene()) then return end
	
	TutorialContext._super.mouseMoveEvent(self, event);
end

function TutorialContext:mouseReleaseEvent(event)
	if (not self:IsCanClickScene()) then return end
	
	TutorialContext._super.mouseReleaseEvent(self, event);
end

function TutorialContext:handleLeftClickScene(event, result)
	shift_pressed, ctrl_pressed, alt_pressed = event.shift_pressed, event.ctrl_pressed, event.alt_pressed;
	result = result or self:CheckMousePick();

	if (result) then
		local data = {blockX = result.blockX, blockY = result.blockY, blockZ = result.blockZ, blockId = result.block_id, shift_pressed = shift_pressed, ctrl_pressed = ctrl_pressed, alt_pressed = alt_pressed, mouseKeyState = 1};
		if (not self:GetTutorialSandbox():IsCanClick(data)) then return end
	end
	
	return TutorialContext._super.handleLeftClickScene(self, event, result);
end

function TutorialContext:handleRightClickScene(event, result)
	shift_pressed, ctrl_pressed, alt_pressed = event.shift_pressed, event.ctrl_pressed, event.alt_pressed;
	result = result or self:CheckMousePick();

	if (result) then
		local data = {blockX = result.blockX, blockY = result.blockY, blockZ = result.blockZ, blockId = result.block_id, shift_pressed = shift_pressed, ctrl_pressed = ctrl_pressed, alt_pressed = alt_pressed, mouseKeyState = 2};
		if ((shift_pressed or ctrl_pressed or alt_pressed) and not self:GetTutorialSandbox():IsCanClick(data)) then return end
	end
	
	return TutorialContext._super.handleRightClickScene(self, event, result);
end

function TutorialContext:TryDestroyBlock(result, is_allow_delete_terrain)
	local data = {blockX = result.blockX, blockY = result.blockY, blockZ = result.blockZ, blockId = result.block_id, mouseKeyState = 1};
	if (self:GetTutorialSandbox():IsCanClick(data)) then return TutorialContext._super.TryDestroyBlock(self, result, is_allow_delete_terrain) end
end

function TutorialContext:OnCreateSingleBlock(blockX, blockY, blockZ, blockId, result)
	local data = {blockX = blockX, blockY = blockY, blockZ = blockZ, blockId = blockId, mouseKeyState = 2};
	if(self:GetTutorialSandbox():IsCanClick(data)) then return TutorialContext._super.OnCreateSingleBlock(self, blockX, blockY, blockZ, blockId, result) end
end

