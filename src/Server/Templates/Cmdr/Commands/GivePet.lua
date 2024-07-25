return {
	Name = "GivePet";
	Aliases = {"gp"};
	Description = "Gives a pet to a player";
	Group = "Admin";
	Args = {
		{
			Type = "pet";
			Name = "petname";
			Description = "The pet to give";
		},
		{
			Type = "player";
			Name = "to";
			Description = "The player to give the pet to"
		},
        {
            Type = "number";
            Name = "amount";
            Description = "The amount of pets to give";
        }
	};
}