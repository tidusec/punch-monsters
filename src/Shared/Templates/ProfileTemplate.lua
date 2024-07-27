--!native
--!strict
local PROFILE_TEMPLATE = {	
	leaderstats = {
		Strength = 0,
		Rebirths = 0,
		Eggs = 0
	},
	
	Pets = {
		OwnedPets = {},
		MaxEquip = 4,
		MaxStorage = 200,
		RobuxPurchasedPets = {},
		Equipped = {}
	},
	
	Timers = {},
	ClaimedRewardsToday = {},
	FirstJoinToday = tick(),
	TimePlayedToday = 0,

	DefeatedBosses = {},
	Wins = 0,

	PunchStrength = 0,
	BicepsStrength = 0,
	AbsStrength = 0,

	ProductsLog = {},
	GamePasses = {},
	RedeemedCodes = {},
	MegaQuestProgress = {},
	UpdatedQuestProgress = false,
	
	AutoFight = false,
	AutoTrain = false,
	AutoRebirth = false,

	RebirthBoosts = {
		Wins = 100,
		Strength = 100
	},

	Settings = {
		Sound = 0, -- 0 to 100
		ShowOwnPets = true,
		ShowOtherPets = true,
		LowQuality = false
	},

	Map = 0,
	TotalPlaytime = 0,
}

return PROFILE_TEMPLATE