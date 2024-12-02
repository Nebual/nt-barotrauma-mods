-- list of afflictions available to gain via cloning

CloneMod.RandomCloneAffliction = {"narcolepsy", "hemophilia", "medicineinsensitivity", "splitconsciousness", "frailbody", "opiateintolerance", "frailbody"}

-- at x world difficulty %, gain y cellular damage per clone cycle using z clone pod
CloneMod.ClonePodWeakness = {10, 40, 60, 75}
CloneMod.SpeedClonerWeakness = {15, 50, 75, 90}

CloneMod.DifficultyThresholds = {0, 15, 40, 75}

-- threshold of post-clone cellular damage to give clone injuries, and the chance to gain an affliction
CloneMod.randomAfflictionThreshold = 40

CloneMod.randomAfflictionChance = 80

-- if set to false, human husks will explode when cloned
CloneMod.cloneHusks = true

-- does cloning via clone pod leave behind the old body?

CloneMod.RetainOldBody = true