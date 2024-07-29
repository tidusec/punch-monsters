--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local TFM = require(ReplicatedStorage.Modules.TFMv2)
local Debounce = require(ReplicatedStorage.Modules.Debounce)
local parseTime = require(ReplicatedStorage.Modules.ParseTime)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Array = require(ReplicatedStorage.Modules.NewArray)
local Component = require(Packages.Component)

local Assets = ReplicatedStorage.Assets

local player = Players.LocalPlayer

type CrateButton = ImageButton & {
	RemainingTime: TextLabel;
	Icon: ImageLabel & {
		TextLabel: TextLabel
	};
}

local RewardsScreen: Component.Def = {
	Name = script.Name;
	IgnoreAncestors = { StarterGui };
	Guards = {
		Ancestors = { player.PlayerGui },
		ClassName = "ScreenGui",
		Children = {
			Background = {
				ClassName = "ImageLabel",
				Children = {
					Close = { ClassName = "ImageButton" },
					Title = { ClassName = "ImageLabel" },
					Crates = { ClassName = "Frame" }
				}
			}
		}
	};
}

function RewardsScreen:Initialize(): nil
	self._ui = Knit.GetController("UIController")
	local NotificationButton = Component.Get("NotificationButton")
	repeat task.wait()
		self._rewardsButton = NotificationButton:Find(self.Instance.Parent.MainUi.PlaytimeRewardButton)
	until self._rewardsButton;
	(self._rewardsButton :: any):ToggleNotification(false)

	self._timedRewards = Knit.GetService("TimedRewardService")
	local data = Knit.GetService("DataService")
	local scheduler = Knit.GetController("SchedulerController")

	self._crateButtons = Array.new("Instance", self.Instance.Background.Crates:GetChildren())
		:Filter(function(element: Instance): boolean
			return element.ClassName == "ImageButton"
		end)

	self._crateList = self._crateButtons:ToTable()

	for _, crateButton: CrateButton in self._crateButtons:GetValues() do
		local db = Debounce.new(0.5)
		self:AddToJanitor(crateButton.MouseButton1Click:Connect(function()
			if db:IsActive() then return end
			if self:GetRemainingTime(crateButton) ~= 0 then return end
			local icon = crateButton:FindFirstChild("Icon")
			local shakeDuration = 0.5
			local shakeIntensity = 5
			
			local originalPosition = icon.Position
			
			for i = 1, 10 do
				local randomOffset = Vector2.new(
					math.random(-shakeIntensity, shakeIntensity),
					math.random(-shakeIntensity, shakeIntensity)
				)
				
				icon.Position = originalPosition + UDim2.fromOffset(randomOffset.X, randomOffset.Y)
				task.wait(shakeDuration / 10)
			end
			
			icon.Position = originalPosition
			
			-- TODO: Add opening animation here
			
			self._timedRewards:Claim(crateButton.LayoutOrder)
		end))
	end

	self:AddToJanitor(data.DataUpdated:Connect(function(key)
		if key ~= "ClaimedRewardsToday" then return end
		self:UpdateScreen()
	end))

	self:AddToJanitor(scheduler:Every("0.5s", function(): nil
		self:UpdateScreen()
		return
	end))

	self._ui:AddModelToViewport(self.Instance.Huge.ViewportFrame, Assets.Pets["Mystic Blackhole Phoenix"], { replaceModel = true })

	return
end

function RewardsScreen:UpdateScreen(): nil
	local ObjectOfTime = TFM.Convert(self._timedRewards:GetTimeLeft())
	self.Instance.Background.TimeLeft.Text = TFM.FormatStr(ObjectOfTime, "%02h:%02m:%02S").." Remaining"
	task.spawn(function(): nil
		local hasUnclaimed = Array.new("Instance", self.Instance.Background.Crates:GetChildren())
			:Filter(function(element: Instance): boolean
				return element.ClassName == "ImageButton"
			end)
			:Filter(function(crateButton: CrateButton): boolean
				return self:GetRemainingTime(crateButton) == 0
			end)
			:Some(function(crateButton: CrateButton): boolean
				return not self._timedRewards:IsClaimed(crateButton.LayoutOrder)
			end)

		if self._rewardsButton.Instance.Exclamation.Visible == hasUnclaimed then return end
		self._rewardsButton:ToggleNotification(hasUnclaimed)
		return
	end)
	for _, crateButton: CrateButton in self._crateList do
		task.spawn(function(): nil
			local isClaimed = self._timedRewards:IsClaimed(crateButton.LayoutOrder)
			local collectText = if isClaimed then "Collected!" else "Collect"
			local icon = crateButton:FindFirstChild("Icon")
			if icon then
				local textLabel = icon:FindFirstChild("TextLabel")
				if textLabel and textLabel:IsA("TextLabel") and textLabel.Visible and textLabel.Text ~= collectText then
					textLabel.Text = collectText
				end
			end
			return
		end)
		task.spawn(function(): nil
			local remainingTime = self:GetRemainingTime(crateButton)
			local timerFinished = remainingTime == 0
			crateButton.Icon.TextLabel.Visible = timerFinished
			crateButton.RemainingTime.Visible = not timerFinished

			if timerFinished then return end
			local timeObject = TFM.Convert(remainingTime)
			crateButton.RemainingTime.Text = TFM.FormatStr(timeObject, "%02h:%02m:%02S")
			return
		end)
	end
	
	return
end

function RewardsScreen:GetRemainingTime(crateButton: Instance): number
	local crateTime = parseTime(crateButton:GetAttribute("Length"))
	return math.round(math.max(crateTime - self._timedRewards:GetElapsedTime(), 0))
end

return Component.new(RewardsScreen)