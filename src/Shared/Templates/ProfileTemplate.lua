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

	--// Roman Numerals because GameAnalytics doesn't allow numbers as keys
	MapI = 0,
	MapII = 0,
	MapIII = 0,
	MapIV = 0,
	MapV = 0,
}

return PROFILE_TEMPLATE