local module = {
	Map1 = {
		{
      Required = 0,
      Gain = 1 * 5,
      IsVIP = false
    }, {
      Required = 150,
      Gain = 2 * 5,
      IsVIP = false
    }, {
      Required = 350,
      Gain = 4 * 5,
      IsVIP = false
    }, {
      Required = 550,
      Gain = 6 * 5,
      IsVIP = false
    }, {
      Required = 800,
      Gain = 8 * 5,
      IsVIP = false
    }, {
      Required = 1200,
      Gain = 10 * 5,
      IsVIP = false
    }, {
      Required = 2000,
      Gain = 18 * 0.65 * 0.9 * 5,
      IsVIP = false
    }, {
      Required = 3500,
      Gain = 23 * 0.65 * 0.75 * 5,
      IsVIP = false
    }, {
      Required = 7500,
      Gain = 25 * 0.65 * 0.75 * 5,
      IsVIP = false
    }, {
      Required = 15_000,
      Gain = 30 * 0.65 * 0.75 * 5,
      IsVIP = false
    }, {
      Required = 25_000,
      Gain = 35 * 0.65 * 0.75 * 5,
      IsVIP = false
    }, {
      Required = 45_000,
      Gain = 50 * 0.65 * 0.75 * 5,
      IsVIP = false
    }, {
      Required = 75_000,
      Gain = 50 * 0.65 * 0.75 * 5,
      IsVIP = false
    }, {
      Required = 110_000,
      Gain = 90 * 0.65 * 0.75 * 5,
      IsVIP = false
    }, { -- VIP
      Required = 0,
      Gain = 100 * 0.65 * 0.75 * 5,
      IsVIP = true
    }
	},
	Map2 = {
		{
      Required = 0,
      Gain = 120 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 450_000,
      Gain = 150 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 550_000,
      Gain = 175 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 700_000,
      Gain = 200 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 850_000,
      Gain = 225 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 1_000_000,
      Gain = 250 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 1_200_000,
      Gain = 300 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 1_500_000,
      Gain = 11_250 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 1_800_000,
      Gain = 13_000 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 2_200_000,
      Gain = 15_000 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 2_600_000,
      Gain = 18_000 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 3_000_000,
      Gain = 22_500 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 3_500_000,
      Gain = 26_500 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 4_100_000,
      Gain = 42_000 * 0.65 * 0.75,
      IsVIP = false
    }, { -- VIP
      Required = 0,
      Gain = 50_000 * 0.65 * 0.75,
      IsVIP = true
    }
	},
	Map3 = {
		{
      Required = 0,
      Gain = 60_000 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 6_000_000,
      Gain = 75_000 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 7_500_000,
      Gain = 87_500 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 9_000_000,
      Gain = 100_000 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 11_000_000,
      Gain = 112_500 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 13_000_000,
      Gain = 125_000 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 16_000_000,
      Gain = 150_000 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 20_000_000,
      Gain = 562_500 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 24_000_000,
      Gain = 650_000 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 30_000_000,
      Gain = 750_000 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 36_000_000,
      Gain = 900_000 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 43_000_000,
      Gain = 1_125_000 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 50_000_000,
      Gain = 1_325_000 * 0.65 * 0.75,
      IsVIP = false
    }, {
      Required = 60_000_000,
      Gain = 2_100_000 * 0.65 * 0.75,
      IsVIP = false
    }, { -- VIP
      Required = 0,
      Gain = 2_500_000 * 0.65 * 0.75,
      IsVIP = true
    }
	}
}

return module
