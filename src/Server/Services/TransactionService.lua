--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerScriptService = game:GetService("ServerScriptService")

local getPageContents = require(ServerScriptService.Server.Modules.getPageContents)
local Array = require(ReplicatedStorage.Packages.Array)
local PurchaseHistory = DataStoreService:GetDataStore("PurchaseHistory")

local Packages = ReplicatedStorage.Packages

local Knit = require(Packages.Knit)

local TransactionService = Knit.CreateService {
	Name = "TransactionService"
}

function TransactionService:KnitStart()
	local data = Knit.GetService("DataService")
	local gamepass = Knit.GetService("GamepassService")
	local boosts = Knit.GetService("BoostService")
	local rebirths = Knit.GetService("RebirthService")
	local hatching = Knit.GetService("HatchingService")
	local purchaseLogger = Knit.GetService("PurchaseLogService")
	local pets = Knit.GetService("PetService")
	
	local ProductFunctions = {
		[1631383839] = function(player: Player): nil -- win1
			data:IncrementValue(player, "Wins", 2_500)
			return
		end,
		[1631383838] = function(player: Player): nil -- win2
			data:IncrementValue(player, "Wins", 15_000)
			return
		end,
		[1631385713] = function(player: Player): nil -- win3
			data:IncrementValue(player, "Wins", 55_000)
			return
		end,
		[1631385717] = function(player: Player): nil -- win4
			data:IncrementValue(player, "Wins", 200_000)
			return
		end,
		[1631385715] = function(player: Player): nil -- win5
			data:IncrementValue(player, "Wins", 1_000_000)
			return
		end,
		[1631385718] = function(player: Player): nil -- win6
			data:IncrementValue(player, "Wins", 5_000_000)
			return
		end,
		[1631385716] = function(player: Player): nil
			boosts:Activate10xLuckBoost(player)
			return
		end,
		[1631387042] = function(player: Player): nil
			boosts:Activate100xLuckBoost(player)
			return
		end,
		[1631387040] = function(player: Player): nil
			boosts:ActivateDoubleWinsBoost(player)
			return
		end,
		[1631387043] = function(player: Player): nil
			boosts:ActivateDoubleStrengthBoost(player)
			return
		end,
		[1654924365] = function(player: Player): nil -- skip rebirth
			rebirths:_AddRebirth(player)
			return
		end,
		[1631383150] = function(player: Player): nil -- skip rebirth
			hatching:HatchServer(player, "Map1", "Egg3Robux")
			return
		end,
		[1631383146] = function(player: Player): nil -- skip rebirth
			hatching:HatchManyServer(player, "Map1", "Egg3Robux", 3)
			return
		end,
		[1631383837] = function(player: Player): nil -- skip rebirth
			hatching:HatchManyServer(player, "Map1", "Egg3Robux", 5)
			return
		end,
		[1884295167] = function(player: Player): nil --give mega quest
			local questprogress = data:GetValue(player, "MegaQuestProgress")
			questprogress["Completed"] = true
			data:SetValue(player, "MegaQuestProgress", questprogress)
			pets:Add(player, "Magical Winged Wyvern")
			hatching:ShowFakeHatch(player, "Magical Winged Wyvern")
			return
		end,

		[1631387975] = function(player: Player): nil -- give best pet
			pets:Add(player, "Mystic Lunar Guard")
			hatching:ShowFakeHatch(player, "Mystic Lunar Guard")
		end,

		[1631387976] = function(player: Player): nil --give limited pet
			pets:Add(player, "Mystic Void Phoenix")
			hatching:ShowFakeHatch(player, "Mystic Void Phoenix")
		end,

		
	}
	
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passID, wasPurchased)
		if not wasPurchased then return end
		gamepass:UpdatePlayerOwnedCache(player, passID)
		purchaseLogger:Log(player, passID, true)
	end)
	
	function MarketplaceService.ProcessReceipt(receipt)
		local playerProductKey = receipt.PlayerId .. "_" .. receipt.PurchaseId
		local purchased = false

		local success, errorMessage = pcall(function()
			purchased = PurchaseHistory:GetAsync(playerProductKey)
		end)

		if success and purchased then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		elseif not success then
			error("Data store error:" .. errorMessage)
		end

		local success, isPurchaseRecorded = pcall(function()
			return PurchaseHistory:UpdateAsync(playerProductKey, function(alreadyPurchased): boolean?
				if alreadyPurchased then return true end
				
				local player = Players:GetPlayerByUserId(receipt.PlayerId)
				if not player then return nil end

				local handleProduct = ProductFunctions[receipt.ProductId]
				if not handleProduct then
					return error("Missing dev product handler function in TransactionService")
				end

				local success, err = pcall(function()
					handleProduct(player)
				end)
				if not success then
					return error(`Failed to process a product purchase for {player.Name}, ProductId: {receipt.ProductId}. Error: {err}`)
				end
				
				task.defer(function()
					local player = Players:GetPlayerByUserId(receipt.PlayerId)
					local devProductIDs = Array.new("table", getPageContents(MarketplaceService:GetDeveloperProductsAsync()):ToTable())
						:Map(function(product)
							return product.ProductId
						end)

					purchaseLogger:Log(player, receipt.ProductId, devProductIDs:Has(receipt.ProductId))
				end)
				
				return true
			end)
		end)


		if not success then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		elseif isPurchaseRecorded == nil then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		else	
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
end

return TransactionService