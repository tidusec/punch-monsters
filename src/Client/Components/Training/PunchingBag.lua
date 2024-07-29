--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Sound = game:GetService("SoundService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local CameraShaker = require(script.Parent.Parent.Parent.Modules.CameraShaker)

local PunchBagsTemplate = require(ReplicatedStorage.Templates.PunchBagsTemplate)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Array = require(ReplicatedStorage.Modules.NewArray)
local Component = require(Packages.Component)

local camera = workspace.CurrentCamera

local cameraShaker = CameraShaker.new(Enum.RenderPriority.Camera.Value + 1, function(shakeCF)
	camera.CFrame *= shakeCF
end)
cameraShaker:Start()

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local characterRoot = character:WaitForChild("HumanoidRootPart")

local MAX_BAG_DISTANCE = 6
local COOLDOWN = 0.5

local PunchingBag: Component.Def = {
	Name = script.Name;
	Guards = {
		Ancestors = { workspace:WaitForChild("Map1"):WaitForChild("PunchingBags"), workspace:WaitForChild("Map2"):WaitForChild("PunchingBags"), workspace:WaitForChild("Map3"):WaitForChild("PunchingBags") },
		ClassName = "Model",
		Attributes = {
			PunchDebounce = { Type = "boolean" }
		},
		Children = {
			Cylinder = { ClassName = "MeshPart" }
		}
	};
}

function PunchingBag:Initialize(): nil
	self._data = Knit.GetService("DataService")
	self._gamepass = Knit.GetService("GamepassService")
	self._dumbell = Knit.GetService("DumbellService")
	self._punchingbag = Knit.GetService("PunchingBagService")
	self._animation = Knit.GetService("AnimationService")
	self._sound = Knit.GetService("SoundService")
	self._ui = Knit.GetController("UIController")
	local scheduler = Knit.GetController("SchedulerController")
	local destroyAutoTrainClicker

	local function startAutoTrain(): nil
		if destroyAutoTrainClicker then
			self._janitor:RemoveNoClean("AutoTrain")
			destroyAutoTrainClicker()
		end
		destroyAutoTrainClicker = scheduler:Every("0.33 second", function(): nil
			return self:Punch()
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
		return startAutoTrain()
	end))

	self._jab1 = true
	return
end

local function getDistanceFromPlayer(bag: Model & { Cylinder: MeshPart }): number
	return (bag.Cylinder.Position - characterRoot.Position).Magnitude
end

function PunchingBag:IsClosest(): boolean
	local closestBag = Array.new("Instance", CollectionService:GetTagged(self.Name))
		:Filter(function(bag)
			local distance = getDistanceFromPlayer(bag)
			return distance <= MAX_BAG_DISTANCE
		end)
		:Sort(function(a, b)
			local distanceA = getDistanceFromPlayer(a)
			local distanceB = getDistanceFromPlayer(b)
			return distanceA < distanceB
		end)
		:First()

	return closestBag == self.Instance
end

function PunchingBag:Punch(): nil
	if self.Attributes.PunchDebounce then return end
	
	local isClosestBag = self:IsClosest()
	if not isClosestBag then return end
	
	local mapName = self.Instance.Parent.Parent.Name
	local bagTemplate = PunchBagsTemplate[mapName][self.Instance.Name]
	local punchStrength, strengthMultiplier = self._data:GetTotalStrength("Punch")
	if punchStrength < bagTemplate.PunchRequirement then self._ui:ShowError("You don't have enough strength!") return end
	if self._dumbell:IsEquipped() then self._ui:ShowError("Please unequip the dumbell!") return end

	self.Attributes.PunchDebounce = true
	task.spawn(function(): nil
		local punchAnim = if self._jab1 then "Jab" else "Jab2"
		self._animation:Play(punchAnim, 1)
		self._jab1 = not self._jab1
		task.delay(COOLDOWN, function()
			self.Attributes.PunchDebounce = false
		end)
		return
	end)

	local hasVIP =  self._gamepass:DoesPlayerOwn("VIP")
	if bagTemplate.Vip and not hasVIP then
		return self._gamepass:PromptPurchase("VIP")
	end
	
	self._sound:Play("Punch")
	task.spawn(function()
		cameraShaker:Shake(CameraShaker.Presets.Rock)
		local vfx = PunchBagsTemplate[mapName].VFX:Clone()
		vfx.Parent = self.Instance.Cylinder
		Debris:AddItem(vfx, 0.7)
	end)

	self._punchingbag:Hit(mapName, self.Instance.Name)

	return
end

return Component.new(PunchingBag)