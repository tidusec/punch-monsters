--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Debounce = require(ReplicatedStorage.Modules.Debounce)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Component = require(Packages.Component)
local Array = require(ReplicatedStorage.Modules.NewArray)

local ServerScriptService = game:GetService("ServerScriptService")
local Modules = ServerScriptService.Server.Modules
local AssertPlayer = require(Modules.AssertPlayer)

local LimitedPets: Component.Def = {
  Name = script.Name;
  Guards = {
    Attributes = {
      Pet = { Type = "string" },
      BeginAmount = { Type = "number" },
      ProductID = { Type = "number" },
    }
  };
}

local API_KEY = "asodifjasopdijfas"
local WORKER_URL = "https://dudleyit.be"

local function getAvailablePets(petName)
    local url = WORKER_URL .. "/getavailable?pet=" .. HttpService:UrlEncode(petName)
    local response = HttpService:GetAsync(url)
    return tonumber(response)
end


function LimitedPets:Initialize(): nil
  local part = self.Instance.Part
  local proximityprompt = part:WaitForChild("ProximityPrompt")
  local pet = self.Attributes.Pet
  local textlabel = self.Instance.BillboardGui.TextLabel

  proximityprompt.Triggered:Connect(function(player)
    local available = getAvailablePets(pet)
    if available == 0 then
      return
    end
    game:GetService("MarketplaceService"):PromptProductPurchase(player, self.Attributes.ProductID)
  end)

  task.spawn(function()
    while true do
      local available = getAvailablePets(pet)
      if available == 0 then
        proximityprompt.Enabled = false
      else
        proximityprompt.Enabled = true
      end
      textlabel.Text = available.."/"..self.Attributes.BeginAmount.." Left"
      task.wait(60)
    end
  end)
end

return Component.new(LimitedPets)