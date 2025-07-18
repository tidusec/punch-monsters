--!native
--!strict
local module = {
	Map1 = {
		SitupBench1 = {
			AbsRequirement = 0,
			Hit = 1 * 1.4 * 1.2 * 5,
		},
		SitupBench2 = {
			AbsRequirement = 500,
			Hit = 2 * 1.4 * 1.2 * 5,
		},
		SitupBench3 = {
			AbsRequirement = 4000,
			Hit = 4 * 1.4 * 1.2 * 5,
		},
		SitupBench4 = {
			AbsRequirement = 22000,
			Hit = 6 * 1.4 * 1.2 * 5,
		},
		SitupBench5 = {
			AbsRequirement = 100000,
			Hit = 8 * 1.4 * 1.2 * 5,
		},
		SitupBench6VIP = {
			AbsRequirement = 0,
			Hit = 15 * 1.4 * 1.2 * 5,

			Vip = true,
		}
	},
	Map2 = {
		SitupBench1 = {
			AbsRequirement = 0,
			Hit = 10 * 1.4 * 1.2,
		},
		SitupBench2 = {
			AbsRequirement = 500000,
			Hit = 15 * 1.4 * 1.2,
		},
		SitupBench3 = {
			AbsRequirement = 1000000,
			Hit = 20 * 1.4 * 1.2,
		},
		SitupBench4 = {
			AbsRequirement = 2000000,
			Hit = 30 * 1.4 * 1.2,
		},
		SitupBench5 = {
			AbsRequirement = 3500000,
			Hit = 50 * 1.4 * 1.2,
		},
		SitupBench6VIP = {
			AbsRequirement = 0,
			Hit = 150 * 1.4 * 1.2,

			Vip = true,
		}
	},
	Map3 = {
		SitupBench1 = {
			AbsRequirement = 0,
			Hit = 75 * 1.4 * 1.2,
		},
		SitupBench2 = {
			AbsRequirement = 10000000,
			Hit = 100 * 1.4 * 1.2,
		},
		SitupBench3 = {
			AbsRequirement = 15000000,
			Hit = 135 * 1.4 * 1.2,
		},
		SitupBench4 = {
			AbsRequirement = 42000000,
			Hit = 175 * 1.4 * 1.2,
		},
		SitupBench5 = {
			AbsRequirement = 110000000,
			Hit = 220 * 1.4 * 1.2,
		},
		SitupBench6VIP = {
			AbsRequirement = 0,
			Hit = 660 * 1.4 * 1.2,

			Vip = true,
		}
	}
	
}

return module
