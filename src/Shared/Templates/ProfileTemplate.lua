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

	DefeatedBosses = {},
	Wins = 0,

	PunchStrength = 0,
	BicepsStrength = 0,
	AbsStrength = 0,

	ProductsLog = {},
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

	Map1 = 0,
	Map2 = 0,
	Map3 = 0,
	Map4 = 0,
	Map5 = 0,
}

return PROFILE_TEMPLATE