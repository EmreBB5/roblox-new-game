-- Pure shared data: no Roblox globals. Loot decisions remain on the server.
return table.freeze({
	QuestTarget = 3, QuestXP = 75, QuestGold = 25, KillXP = 10,
	AttackDamage = 25, AttackRange = 11, AttackCooldown = 0.55,
	PlayerWalkSpeed = 20, MaxTravelSpeed = 40,
	EnemyHealth = 75, EnemyDamage = 10, EnemyAttackRange = 5,
	EnemyAttackCooldown = 1.4, EnemyAggroRange = 65, EnemyWalkSpeed = 10,
	EnemyRespawnSeconds = 8,
	SafeZoneRadius = 65,
	Regions = {
		forest = {Name = "Fısıltı Ormanı", X = -230, Z = -240, Radius = 200, EnemyLevel = 1, EnemyHealth = 90, EnemyDamage = 10},
		marsh = {Name = "Sisli Bataklık", X = 260, Z = -330, Radius = 215, EnemyLevel = 3, EnemyHealth = 150, EnemyDamage = 14},
		volcanic = {Name = "Köz Yaylası", X = 0, Z = -760, Radius = 230, EnemyLevel = 5, EnemyHealth = 210, EnemyDamage = 18},
	},
	BossOrder = {"thornwarden", "tide_sentinel", "ember_drake"},
	Bosses = {
		thornwarden = {Name = "Diken Muhafızı", PetId = "mossling", Minute = 0, RegionId = "forest", MaxHealth = 3500, Damage = 16, AttackRange = 8, AttackCooldown = 2, WalkSpeed = 9, XP = 200, Gold = 100, X = -230, Z = -300},
		tide_sentinel = {Name = "Sis Bekçisi", PetId = "tidefin", Minute = 20, RegionId = "marsh", MaxHealth = 4500, Damage = 20, AttackRange = 8, AttackCooldown = 2, WalkSpeed = 9, XP = 250, Gold = 125, X = 260, Z = -390},
		ember_drake = {Name = "Köz Ejderi", PetId = "embercub", Minute = 40, RegionId = "volcanic", MaxHealth = 5500, Damage = 24, AttackRange = 9, AttackCooldown = 2.2, WalkSpeed = 9, XP = 300, Gold = 150, X = 0, Z = -820},
	},
	Pets = {
		mossling = {Name = "Yosun Perisi", DamageBonus = 4},
		tidefin = {Name = "Sis Kanadı", DamageBonus = 4},
		embercub = {Name = "Köz Yavrusu", DamageBonus = 4},
	},
	BossDuration = 600, StudioBossDuration = 120, StudioBossHealthScale = 0.3,
	StudioFirstBossDelay = 20, StudioBossInterval = 180,
	PetDropChance = 0.03, PetPityLimit = 30, DuplicateStardust = 10,
	BossMinDamageFraction = 0.01, BossMinAcceptedHits = 3,
})
