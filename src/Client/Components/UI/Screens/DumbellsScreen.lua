--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local DumbellsTemplate = require(ReplicatedStorage.Templates.DumbellsTemplate)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Array = require(ReplicatedStorage.Modules.NewArray)
local Component = require(Packages.Component)

local player = Players.LocalPlayer

local DumbellsScreen: Component.Def = {
	Name = script.Name;
	IgnoreAncestors = { StarterGui };
	Guards = {
		Ancestors = { player.PlayerGui },
		ClassName = "ScreenGui",
		Attributes = {
			MapName = { Type = "string" }
		},
		Children = {
			Map1 = {
				ClassName = "ImageLabel",
				Children = {
					Close = { ClassName = "ImageButton" },
					Title = { ClassName = "ImageLabel" }
				}
			},
			Map2 = {
				ClassName = "ImageLabel",
				Children = {
					Close = { ClassName = "ImageButton" },
					Title = { ClassName = "ImageLabel" }
				}
			},
			Map3 = {
				ClassName = "ImageLabel",
				Children = {
					Close = { ClassName = "ImageButton" },
					Title = { ClassName = "ImageLabel" }
				}
			}
		}
	};
}

function DumbellsScreen:Initialize(): nil
	local dumbell = Knit.GetService("DumbellService")
	local data = Knit.GetService("DataService")
	local ui = Knit.GetController("UIController")
	local cards = Array.new( "Instance", self.Instance.Map1:GetChildren())
		:AddValues(self.Instance.Map2:GetChildren())
		:AddValues(self.Instance.Map3:GetChildren())
		:Filter(function(element: Instance): boolean
			return element:IsA("ImageLabel") and element.Name ~= "Title"
		end)

	for _, card: ImageLabel & { ImageButton: ImageButton & { TextLabel: TextLabel } } in cards:GetValues() do
		task.spawn(function()
			local equipButton = card.ImageButton
			self:AddToJanitor(equipButton.MouseButton1Click:Connect(function()
				local mapName: string = self.Attributes.MapName
				local mapDumbells = DumbellsTemplate[mapName]
				local cardNumber = tonumber(card.Name) :: number
				local template = mapDumbells[cardNumber]
				
				template.IsVIP = cardNumber == 15
				local plr_strength = data:GetTotalStrength("Biceps")
				if plr_strength < template.Required then
					ui:ShowError("You don't have enough strength!")
					 return 
				end
				
				local isEquipped = dumbell:IsEquipped()
				task.spawn(function()
					if isEquipped then
						dumbell:Unequip()
					else
						dumbell:Equip(mapName, cardNumber, template)
					end
					equipButton.TextLabel.Text = if not isEquipped then "Unequip" else "Equip"
					equipButton.ImageColor3 = if not isEquipped then Color3.fromRGB(255, 46, 46) else Color3.fromRGB(255, 255, 255)
				end)
			end))
		end)
	end

	return
end

return Component.new(DumbellsScreen)