return {
	Name = "GiveWins";
    Aliases = {"gp"};
	Description = "Gives a certain amount of wins to a player";
	Group = "Admin";
	Args = {
		{
			Type = "player";
			Name = "player";
			Description = "Player to give wins to";
		},
        {
            Type = "number";
            Name = "amount";
            Description = "Amount of wins to give";
        }
	};
}