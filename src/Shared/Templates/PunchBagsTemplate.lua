--!native
--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local module = {
	Map1 = {
		VFX = ReplicatedStorage.Assets.VFX.Hit1,
		
		PunchBag1 = {
			PunchRequirement = 0,
			Hit = 1 * 1.4 * 5,
		},
		PunchBag2 = {
			PunchRequirement = 500,
			Hit = 2 * 1.4 * 5,
		},
		PunchBag3 = {
			PunchRequirement = 4000,
			Hit = 3 * 1.4 * 5,
		},
		PunchBag4 = {
			PunchRequirement = 22000,
			Hit = 4 * 1.4 * 5,
		},
		PunchBag5 = {
			PunchRequirement = 100000,
			Hit = 5 * 1.4 * 5,
		},
		PunchBag6VIP = {
			PunchRequirement = 0,
			Hit = 10 * 1.4 * 5,

			Vip = true,
		}
	},
	Map2 = {
		VFX = ReplicatedStorage.Assets.VFX.Hit2,

		PunchBag1 = {
			PunchRequirement = 0,
			Hit = 10 * 1.4,
		},
		PunchBag2 = {
			PunchRequirement = 500000,
			Hit = 15 * 1.4,
		},
		PunchBag3 = {
			PunchRequirement = 1000000,
			Hit = 20 * 1.4,
		},
		PunchBag4 = {
			PunchRequirement = 2000000,
			Hit = 30 * 1.4,
		},
		PunchBag5 = {
			PunchRequirement = 3500000,
			Hit = 50 * 1.4,
		},
		PunchBag6VIP = {
			PunchRequirement = 0,
			Hit = 150 * 1.4,

			Vip = true,
		}
	},
	Map3 = {
		VFX = ReplicatedStorage.Assets.VFX.Hit3,

		PunchBag1 = {
			PunchRequirement = 0,
			Hit = 75 * 1.4,
		},
		PunchBag2 = {
			PunchRequirement = 10000000,
			Hit = 100 * 1.4,
		},
		PunchBag3 = {
			PunchRequirement = 16000000,
			Hit = 135 * 1.4,
		},
		PunchBag4 = {
			PunchRequirement = 42000000,
			Hit = 175 * 1.4,
		},
		PunchBag5 = {
			PunchRequirement = 110000000,
			Hit = 220 * 1.4,
		},
		PunchBag6VIP = {
			PunchRequirement = 0,
			Hit = 660 * 1.4,

			Vip = true,
		}
	}
	
}

return module
