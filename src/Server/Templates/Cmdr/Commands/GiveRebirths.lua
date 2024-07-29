return {
	Name = "GiveRebirths";
    Aliases = {"gr"};
	Description = "Gives a certain amount of rebirths to a player";
	Group = "Admin";
	Args = {
		{
			Type = "player";
			Name = "player";
			Description = "Player to give rebirths to";
		},
        {
            Type = "number";
            Name = "amount";
            Description = "Amount of rebirths to give";
        }
	};
}