--!native
--!strict


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Sound = game:GetService("SoundService")
local Players = game:GetService("Players")

local CameraShaker = require(script.Parent.Parent.Modules.CameraShaker)

local abbreviate = require(ReplicatedStorage.Assets.Modules.Abbreviate)
local EnemyTemplate = require(ReplicatedStorage.Templates.EnemiesTemplate)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Component = require(Packages.Component)

local camera = workspace.CurrentCamera
local cameraShaker = CameraShaker.new(Enum.RenderPriority.Camera.Value + 1, function(shakeCF)
	camera.CFrame *= shakeCF
end)
cameraShaker:Start()

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local characterRoot = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local animations = ReplicatedStorage.Assets.Animations

local RAGDOLL_FORCE = 30
local COOLDOWN = 0.25
local PLAYER_ANIMS = {
	"Jab",
	"Jab2",
	"Uppercut"
}

local EnemyFighting: Component.Def = {
	Name = script.Name;
	IgnoreAncestors = { player.PlayerGui };
	Guards = {
		Ancestors = { workspace:WaitForChild("Map1"):WaitForChild("Enemies"), workspace:WaitForChild("Map2"):WaitForChild("Enemies"), workspace:WaitForChild("Map3"):WaitForChild("Enemies") },
		ClassName = "Model",
		Attributes = {
			InUse = { Type = "boolean" },
			PunchDebounce = { Type = "boolean" },
			Boss = { Type = "boolean" }
		},
		Children = {
			Head = { IsA = "BasePart" },
			HumanoidRootPart = { ClassName = "Part" },
			Humanoid = { ClassName = "Humanoid" },
			ProxyPart = {
				ClassName = "Part",
				Transparency = 1,
				Anchored = true,
				CanCollide = false
			}
		}
	};
}

function EnemyFighting:Initialize(): nil
	self._remoteDispatcher = Knit.GetService("RemoteDispatcher")	
	self._data = Knit.GetService("DataService")
	self._rebirths = Knit.GetService("RebirthService")
	self._boosts = Knit.GetService("BoostService")
	self._gamepass = Knit.GetService("GamepassService")
	self._dumbell = Knit.GetService("DumbellService")
	self._ragdoll = Knit.GetService("RagdollService")
	self._animation = Knit.GetService("AnimationService")
	self._ui = Knit.GetController("UIController")
	self._enemyfighting = Knit.GetService("EnemyFightingService")
	local scheduler = Knit.GetController("SchedulerController")
	local destroyAutoFightClicker

	local function startAutoFight(): nil
		if destroyAutoFightClicker then
			self._janitor:RemoveNoClean("AutoFight")
			destroyAutoFightClicker()
		end
		destroyAutoFightClicker = scheduler:Every("0.33 seconds", function()
			self:Attack()
		end)
		self:AddToJanitor(destroyAutoFightClicker, true, "AutoFight")
		return
	end
	
	self:AddToJanitor(self._data.DataUpdated:Connect(function(key, on: boolean): nil
		if key ~= "AutoFight" then return end
		if not on then
			if destroyAutoFightClicker then
				self._janitor:RemoveNoClean("AutoFight")
				destroyAutoFightClicker()
			end
			return
		end
		startAutoFight()
		return
	end))

	self._proxyPart = self.Instance:WaitForChild("ProxyPart")
	self._proximityPrompt = Instance.new("ProximityPrompt")
	self._proximityPrompt.HoldDuration = 1
	self._proximityPrompt.ObjectText = "Fight"
	self._proximityPrompt.RequiresLineOfSight = false
	self._proximityPrompt.Parent = self._proxyPart
	
	self._fighting = false
	self._healthToDamageRatio = 5
	self._strengthToHealthRatio = 20
	
	self._enemyTemplate = EnemyTemplate[self.Instance.Name]
	self._enemyStrength = self._enemyTemplate.Strength
	self._enemyMaxHealth = self._enemyStrength * self._strengthToHealthRatio
	self._enemyHealth = self._enemyMaxHealth
	self._enemyDamage = self._enemyStrength / self._healthToDamageRatio
	self._enemyAnims = {
		(self.Instance :: any).Humanoid:LoadAnimation(animations.Jab),
		(self.Instance :: any).Humanoid:LoadAnimation(animations.Jab2),
		(self.Instance :: any).Humanoid:LoadAnimation(animations.Uppercut)
	}
	
	self._fightUi = player.PlayerGui.FightUi
	self._originalCFrame = (self.Instance.PrimaryPart :: BasePart).CFrame
	self._originalCountdownColor = self._fightUi.Countdown.TextColor3
	self._ragdoll:RigModel(self.Instance)

	self:AddToJanitor(self._proximityPrompt.Triggered:Connect(function()
		self:Enter()
	end))
	
	self:AddToJanitor(self._fightUi.Exit.Exit.TextButton.MouseButton1Click:Connect(function()
		self:Exit(true)
	end))


	return
end

local defaultSpeed = humanoid.WalkSpeed
local defaultJumpPower = humanoid.JumpPower
function EnemyFighting:Toggle(on: boolean): nil
	humanoid.WalkSpeed = if on then 0 else defaultSpeed
	humanoid.JumpPower = if on then 0 else defaultJumpPower
	self._proximityPrompt.Enabled = not on
	return
end


function EnemyFighting:Enter(): nil
	if self._dumbell:IsEquipped() then 
		self._dumbell:Unequip()
	end

	self._playerMaxHealth, self._enemyMaxHealth = self._enemyfighting:Enter(self.Instance)
	
	local playerStrength = self._data:GetTotalStrength()

	self._playerHealth = self._playerMaxHealth
	self._enemyHealth = self._enemyMaxHealth
	
	local proxyCFrame: CFrame = self._proxyPart.CFrame;
	characterRoot.CFrame = proxyCFrame + Vector3.new(0, 2.5 * humanoid.BodyHeightScale.Value, 0)
	self:Toggle(true)
	
	task.spawn(function()
		self._fightUi.Countdown.TextColor3 = self._originalCountdownColor
		self._fightUi.Me.ImageLabel.Image = Players:GetUserThumbnailAsync(
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size420x420
		)
		self._fightUi.Me.TextLabel.Text = abbreviate(playerStrength)
		self._fightUi.Enemy.TextLabel.Text = abbreviate(self._enemyStrength)
		
		local viewport = self._fightUi.Enemy.Viewport
		self._ui:AddModelToViewport(viewport, self.Instance, { replaceModel = true })
		self._ui:SetScreen("FightUi")
	end)
	
	self._enemyHealth, self._playerHealth = self._enemyfighting:Update()

	task.spawn(function()
		for i = 3, 0, -1 do
			task.wait(0.8)
			self._fightUi.Countdown.Text = tostring(i)
		end
		self._fightUi.Countdown.Text = "Fight!"
		self:StartFight()
	end)
	return
end

function EnemyFighting:StartFight(): nil
	self._fighting = true
	self._enemyfighting:StartFight(self.Instance)
	
	task.spawn(function()
		repeat task.wait(0.4);
			task.spawn(function(): nil
				local punchAnim = self._enemyAnims[math.random(1, #self._enemyAnims)]
				punchAnim:Play()
				punchAnim:AdjustSpeed(2.8)
				return
			end);
			self:UpdateFight()
			self:UpdateBars()
		until (self._playerHealth <= 0) or (self._enemyHealth <= 0)
		
		self:UpdateBars()
		if self._playerHealth <= 0 then
			self:KillPlayer()
		end	
	end)
	return
end

function EnemyFighting:Reset(): nil
	self._ui:SetScreen("MainUi")
	self._fightUi.Countdown.Text = "3"
	self._fightUi.Me.HP.Bar.Size = UDim2.new(1, 0, 1, 0)
	self._fightUi.Enemy.HP.Bar.Size = UDim2.new(1, 0, 1, 0)

	character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	self.Instance.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	self.Instance.PrimaryPart.Anchored = true
	self.Instance.PrimaryPart.CFrame = self._originalCFrame
	return
end

function EnemyFighting:Exit(forced: boolean): nil
	self:Toggle(false)
	self:Reset()
	self._fighting = false

	task.spawn(function()
		if forced then
			self._enemyfighting:Exit(self.Instance)
			return
		end
	end)
	return
end

function EnemyFighting:UpdateBars(): nil
	task.spawn(function()
		local PlayerHPSize = math.clamp((self :: any)._playerHealth / (self._playerMaxHealth or 100), 0, 1)
		local EnemyHPSize = math.clamp((self :: any)._enemyHealth / (self._enemyMaxHealth or 100), 0, 1)
		
		self._fightUi.Me.HP.Bar:TweenSize(
			UDim2.fromScale(PlayerHPSize, 1),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Linear,
			0.2
		)
		self._fightUi.Enemy.HP.Bar:TweenSize(
			UDim2.fromScale(EnemyHPSize, 1),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Linear,
			0.2
		)
	end)
	return
end

function EnemyFighting:Attack(): nil
	if not self._fighting then return end
	if self.Attributes.PunchDebounce then return end
	self.Attributes.PunchDebounce = true
	task.delay(COOLDOWN, function()
		self.Attributes.PunchDebounce = false
	end)

	local punchAnim = PLAYER_ANIMS[math.random(1, #PLAYER_ANIMS)]
	self._animation:Play(punchAnim, 2.5)
	task.spawn(function()
		cameraShaker:Shake(CameraShaker.Presets.Rock);
	end);
	
	self._enemyHealth, self._playerHealth = self._enemyfighting:Attack(self.Instance)

	task.spawn(function()
		self:UpdateBars()
		if self._enemyHealth <= 0 then
			self:Kill()
		end
	end)

	return
end

function EnemyFighting:UpdateFight()
	task.spawn(function()
		self._enemyHealth, self._playerHealth = self._enemyfighting:Update()
	end)
end

function EnemyFighting:AddWin(): nil
	Sound.Master.Win:Play()
	--[[task.defer(function()
		Sound.Master.Win:Play()
		local hasDoubleWins = self._gamepass:DoesPlayerOwn("2x Wins")
		local hasWinsBoost = self._boosts:IsBoostActive("2xWins")
		local gamepassMultiplier: number = (if hasDoubleWins then 2 else 1)
			* (if hasWinsBoost then 2 else 1)

		local rebirthMultiplier: number = self._rebirths:GetBoost(player, "Wins")

		--self._data:IncrementValue("Wins", (self :: any)._enemyTemplate.Wins * rebirthMultiplier * gamepassMultiplier)
	end)]]
	return
end

function EnemyFighting:KillPlayer(): nil
	self._fighting = false
	self._fightUi.Countdown.TextColor3 = Color3.fromRGB(248, 80, 80)
	self._fightUi.Countdown.Text = `{self.Instance.Name} has won!`

	local forwards = characterRoot.CFrame.LookVector :: Vector3
	local up = characterRoot.CFrame.UpVector :: Vector3
	character.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	characterRoot.AssemblyLinearVelocity = forwards * -RAGDOLL_FORCE + up * (RAGDOLL_FORCE / 3)
	task.delay(2.5, function()
		self:Exit(false)
	end)
	return
end

function EnemyFighting:Kill(): nil
	self._fighting = false
	self._fightUi.Countdown.Text = "You won!"
	self._fightUi.Countdown.TextColor3 = Color3.fromRGB(108, 248, 80)
	self:AddWin()

	task.spawn(function()
		local forwards = self._originalCFrame.LookVector :: Vector3
		local up = self._originalCFrame.UpVector :: Vector3
		self.Instance.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		self.Instance.PrimaryPart.Anchored = false
		self.Instance.PrimaryPart.AssemblyLinearVelocity = forwards * -RAGDOLL_FORCE + up * (RAGDOLL_FORCE / 3)
	end)

	--[[if self.Attributes.Boss then
		self._data:AddDefeatedBoss(script.Parent.Parent.Name) -- map name
	end]]
	task.delay(2, function()
		self:Exit(false)
	end)

	return
end

return Component.new(EnemyFighting)