local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Sound = game:GetService("SoundService")
local Players = game:GetService("Players")

local SitupBenchTemplate = require(ReplicatedStorage.Templates.SitupBenchTemplate)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Component = require(Packages.Component)

local player = Players.LocalPlayer
local defaultCameraMinZoom = player.CameraMinZoomDistance
local character = player.Character or player.CharacterAdded:Wait()
local characterRoot = character:WaitForChild("HumanoidRootPart")

local COOLDOWN = 1.5

local SitupBench: Component.Def = {
	Name = script.Name;
	Guards = {
		Ancestors = { workspace:WaitForChild("Map1"):WaitForChild("SitupBenches"), workspace:WaitForChild("Map2"):WaitForChild("SitupBenches"), workspace:WaitForChild("Map3"):WaitForChild("SitupBenches") },
		ClassName = "Model",
		Attributes = {
			InUse = { Type = "boolean" },
			SitupDebounce = { Type = "boolean" }
		},
		Children = {
			Cube = { ClassName = "MeshPart" },
			TP = {
				ClassName = "Part",
				Transparency = 1,
				Anchored = true,
				CanCollide = false
			}
		}
	};
}

function SitupBench:Initialize(): nil	
	self._remoteDispatcher = Knit.GetService("RemoteDispatcher")
	self._data = Knit.GetService("DataService")
	self._gamepass = Knit.GetService("GamepassService")
	self._dumbell = Knit.GetService("DumbellService")
	self._situp = Knit.GetService("SitupService")
	self._animation = Knit.GetService("AnimationService")
	self._ui = Knit.GetController("UIController")
	local scheduler = Knit.GetController("SchedulerController")
	local destroyAutoTrainClicker

	local function startAutoTrain(): nil
		if destroyAutoTrainClicker then
			self._janitor:RemoveNoClean("AutoTrain")
			destroyAutoTrainClicker()
		end
		destroyAutoTrainClicker = scheduler:Every("0.33 seconds", function()
			self:Situp()
		end)
		self:AddToJanitor(destroyAutoTrainClicker, true, "AutoTrain")
		return
	end
	
	self:AddToJanitor(self._data.DataUpdated:Connect(function(key, on: boolean): nil
		if key ~= "AutoTrain" then return end
		if not on then
			if destroyAutoTrainClicker then
				self._janitor:RemoveNoClean("AutoTrain")
				destroyAutoTrainClicker()
			end
			return
		end
		startAutoTrain()
		return
	end))
	
	self._proximityPrompt = Instance.new("ProximityPrompt")
	self._proximityPrompt.HoldDuration = 1
	self._proximityPrompt.ObjectText = "Train"
	self._proximityPrompt.Parent = self.Instance.Cube
	
	local MainUi = player.PlayerGui.MainUi
	self._exitBench = MainUi.ExitBench.Exit.TextButton
	self._exitFrame = MainUi.ExitBench
	
	self._benchTemplate = SitupBenchTemplate[self.Instance.Parent.Parent.Name][self.Instance.Name]
	self._absRequirement = self._benchTemplate.AbsRequirement
	self:AddToJanitor(self._proximityPrompt.Triggered:Connect(function()
		self:Enter()
	end))
	self:AddToJanitor(self._exitBench.MouseButton1Click:Connect(function()
		self:Exit()
	end))

	return
end

function SitupBench:Toggle(on: boolean): nil
	--self._ui:SetShiftLock(not on)
	self._proximityPrompt.Enabled = not on
	self._exitFrame.Visible = on
	characterRoot.Anchored = on
	return
end

function SitupBench:Enter(): nil
	if self._dumbell:IsEquipped() then return end
	
	task.spawn(function()
		self._situp:Enter(self.Instance.Parent.Parent.Name, self.Instance)
	end)

	local absStrength = self._data:GetTotalStrength("Abs")
	if absStrength < self._absRequirement then self._ui:ShowError("You don't have enough strength!") return end
	
	self:Toggle(true)
	self.DoingSitups = true
	characterRoot.CFrame = self.Instance.TP.CFrame
	player.CameraMinZoomDistance = 4
	return
end

function SitupBench:Exit(): nil
	task.spawn(function()
		self._situp:Exit()
	end)
	self:Toggle(false) 
	self.DoingSitups = false
	player.CameraMinZoomDistance = defaultCameraMinZoom
	return
end

function SitupBench:Situp(): nil
	if self.Attributes.SitupDebounce then return end
	if not self.DoingSitups then return end

	self.Attributes.SitupDebounce = true
	task.delay(COOLDOWN, function()
		self.Attributes.SitupDebounce = false
	end)

	self._animation:Play("Situp", 1.5)
	Sound.Master.Train:Play()
	local hasVIP =  self._gamepass:DoesPlayerOwn("VIP")
	if self._benchTemplate.Vip and not hasVIP then
		return self._gamepass:PromptPurchase("VIP")
	end
	
	self._situp:Situp()
	--self._data:IncrementValue("AbsStrength", self._benchTemplate.Hit * strengthMultiplier)
	return
end

return Component.new(SitupBench)