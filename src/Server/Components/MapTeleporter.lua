--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Debounce = require(ReplicatedStorage.Modules.Debounce)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Component = require(Packages.Component)
local Array = require(ReplicatedStorage.Modules.NewArray)

local ServerScriptService = game:GetService("ServerScriptService")
local Modules = ServerScriptService.Server.Modules
local AssertPlayer = require(Modules.AssertPlayer)

local MapTeleporter: Component.Def = {
  Name = script.Name;
  Guards = {
    Ancestors = { workspace.Map1, workspace.Map2, workspace.Map3 },
    ClassName = "Model",
    PrimaryPart = function(primary)
      return primary ~= nil
    end,
    Attributes = {
      RequiredRebirths = { Type = "number" },
      RequiredWins = { Type = "number" },
    },
    Children = {
      Portal = { ClassName = "MeshPart" },
      Back = {
        ClassName = "Model",
        Children = {
          Circle = { ClassName = "MeshPart" }
        }
      }
    }
  };
}

local playerTeleporterDebounces: { [number]: typeof(Debounce.new(0)) } = {}
local playerBackTeleporterDebounces: { [number]: typeof(Debounce.new(0)) } = {}

function MapTeleporter:Initialize(): nil
  self._data = Knit.GetService("DataService")
  self._pets = Knit.GetService("PetService")
  self._mapName = self.Instance.Parent.Name
  local _, mapNumberString = table.unpack(self._mapName:split("Map"))

  local function getPlayerFromPart(hit: BasePart): Player?
    local character = hit:FindFirstAncestorOfClass("Model")
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    return true, Players:GetPlayerFromCharacter(character)
  end

  if self._mapName ~= "Map3" then
    local destinationMapName = `Map{tonumber(mapNumberString) :: number + 1}`
    local destinationMap = workspace:FindFirstChild(destinationMapName) :: Model
    local destinationTeleporter = destinationMap:FindFirstChild("Teleporter") :: Model
    local destinationCFrame = (destinationTeleporter.PrimaryPart :: BasePart).CFrame
    local destinationOffset = destinationCFrame.LookVector * 5

    self:AddToJanitor(self.Instance.Portal.Touched:Connect(function(hit: BasePart): nil
      if self._mapName == "Map3" then return end
  
      local success, player = getPlayerFromPart(hit)
      if not success then return end
      AssertPlayer(player)

      if not playerTeleporterDebounces[player.UserId] then
        local db = Debounce.new(2)
        playerTeleporterDebounces[player.UserId] = db
        self:Teleport(player, player.Character, destinationCFrame + destinationOffset)
        self:AddToJanitor(db)
        return
      end
      
      local db = playerTeleporterDebounces[player.UserId]
      if db:IsActive() then return end

      self:Teleport(player, player.Character, destinationCFrame + destinationOffset)
      
      return
    end))
  end

  if self._mapName ~= "Map1" then
    local previousMapName = `Map{tonumber(mapNumberString) :: number - 1}`
    local previousMap = workspace:FindFirstChild(previousMapName) :: Model
    local previousTeleporter = previousMap:FindFirstChild("Teleporter") :: Model
    local previousCFrame = (previousTeleporter.PrimaryPart :: BasePart).CFrame
    local previousOffset = previousCFrame.LookVector * 5

    self:AddToJanitor(self.Instance.Back.Circle.Touched:Connect(function(hit: BasePart): nil
      local success, player = getPlayerFromPart(hit)
      if not success then return end
      if not player then return end
      if not playerBackTeleporterDebounces[player.UserId] then
        local db = Debounce.new(2)
        playerBackTeleporterDebounces[player.UserId] = db
        self:AddToJanitor(db)
      end
      
      local db = playerBackTeleporterDebounces[player.UserId]
      if db:IsActive() then return end
      self:Teleport(player,player.Character, previousCFrame + previousOffset, true)
      return
    end))
  end

  return
end

function MapTeleporter:Teleport(player: Player, character: Model, cframe: CFrame, bypass: boolean): nil
  bypass = bypass or false
  if bypass then
    (character.HumanoidRootPart :: BasePart).CFrame = cframe
  end
  AssertPlayer(player)
  if not Array.new("string",self._data:GetValue(player, "DefeatedBosses")):Has(self._mapName) then return end
  if self._data:GetValue(player, "Rebirths") < self.Attributes.RequiredRebirths then return end
  if self._data:GetValue(player, "Wins") < self.Attributes.RequiredWins then return end
  (character.HumanoidRootPart :: BasePart).CFrame = cframe
  self._pets:UpdateFollowingPets(player, self._data:GetValue(player, "Pets").Equipped)
  return
end

return Component.new(MapTeleporter)