--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local trim = require(ReplicatedStorage.Assets.Modules.Trim)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Array = require(Packages.Array)
local Component = require(Packages.Component)

local player = Players.LocalPlayer

local SUCCESS_STATUS_COLOR = Color3.fromRGB(55, 255, 55)
local ERROR_STATUS_COLOR = Color3.fromRGB(255, 45, 45)

local CodesScreen: Component.Def = {
	Name = script.Name;
	IgnoreAncestors = { StarterGui };
	Guards = {
		Ancestors = { player.PlayerGui },
		Name = "Codes",
		ClassName = "ScreenGui",
		Children = {
			Background = {
				ClassName = "ImageLabel",
				Children = {
					Close = { ClassName = "ImageButton" },
					Redeem = { ClassName = "ImageButton" }
				}
			}
		}
	};
}

function CodesScreen:Initialize(): nil
	self._code = Knit.GetService("CodeService")
	self._data = Knit.GetService("DataService")
	
	local background = self.Instance.Background
	self._redeem = background.Redeem
	self._status = background.Status
	self._textInput = background.TextBubble.Input
	
	self:AddToJanitor(self._redeem.MouseButton1Click:Connect(function()
		self:Redeem()
	end))
	return
end

function CodesScreen:Redeem(): nil
	local code = trim(self._textInput.Text:lower())
	if code == "" then
		return self:PushStatus("Please enter a code!", true)
	end
	local push = self._code:Redeem(code)
	self:PushStatus(push, not push:find("Success"))
end

function CodesScreen:PushStatus(message: string, err: boolean?): nil
	if self.Attributes.StatusDebounce then return end
	self.Attributes.StatusDebounce = true
	
	self._status.Visible = true
	self._status.Text = message
	self._status.TextColor3 = if err then ERROR_STATUS_COLOR else SUCCESS_STATUS_COLOR
	
	task.delay(1,  function()
		self._status.Visible = false
		self.Attributes.StatusDebounce = false
	end)
	return
end

return Component.new(CodesScreen)