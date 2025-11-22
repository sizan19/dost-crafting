Config = {
    BlipSprite = 237,
    BlipColor = 26,
    BlipText = 'Crafting Station',
    
    UseLimitSystem = false,
    CraftingStopWithDistance = false,
    HideWhenCantCraft = false,
    Debug = false,
    
    Categories = {
        ['Weapons'] = {
            Label = 'WEAPONS',
            Image = 'WEAPON_APPISTOL',
            Jobs = {}
        },
        ['Survival'] = {
            Label = 'SURVIVAL',
            Image = 'lockpick',
            Jobs = {}
        },
        -- ['Clothing'] = {
        --     Label = 'CLOTHING',
        --     Image = 'cloth',
        --     Jobs = {}
        -- },
        -- ['Electronics'] = {
        --     Label = 'ELECTRONICS',
        --     Image = 'electronickit',
        --     Jobs = {}
        -- },
        ['Medical'] = {
            Label = 'MEDICAL',
            Image = 'bandage',
            Jobs = {}
        }
    },
    
    PermanentItems = {
        ['wrench'] = true,
        ['hammer'] = true,
        ['screwdriver'] = true,
        ['scissors'] = true,
        ['needle'] = true
    },
    
    WorkbenchTypes = {
        ['weapons'] = {
            name = 'Weapons Workbench',
            description = 'Craft weapons and ammunition',
            blipColor = 1,
            blipSprite = 110,
            prop = 'gr_prop_gr_bench_01b',
            targetIcon = 'fas fa-crosshairs',
            targetLabel = 'Weapons Bench'
        },
        ['survival'] = {
            name = 'Survival Workbench',
            description = 'Craft survival tools and electronics',
            blipColor = 2,
            blipSprite = 402,
            prop = 'imp_prop_impexp_mechbench',
            targetIcon = 'fas fa-tools',
            targetLabel = 'Survival Bench'
        },
        ['medical'] = {
            name = 'Medical Workbench',
            description = 'Craft medical supplies',
            blipColor = 3,
            blipSprite = 153,
            prop = 'gr_prop_gr_cnc_01c',
            targetIcon = 'fas fa-plus-circle',
            targetLabel = 'Medical Bench'
        },
        ['universal'] = {
            name = 'Universal Workbench',
            description = 'Access all crafting recipes',
            blipColor = 5,
            blipSprite = 566,
            prop = 'gr_prop_gr_bench_02a',
            targetIcon = 'fas fa-cogs',
            targetLabel = 'Universal Crafting'
        },
        -- ['electronics'] = {
        --     name = 'Electronics Workbench',
        --     description = 'Craft electronic devices',
        --     blipColor = 5,
        --     blipSprite = 521,
        --     prop = 'gr_prop_gr_bench_02a',
        --     targetIcon = 'fas fa-microchip',
        --     targetLabel = 'Access Electronics Bench'
        -- }
    },
    
    Workbenches = {
        {
            coords = vector3(2763.84, 1548.16, 24.5),
            heading = 345.05,
            jobs = {},
            blip = false,
            radius = 3.0,
            workbenchType = 'weapons'
        },
        {
            coords = vector3(-171.06, 6146.6, 42.64),
            heading = 315.74,
            jobs = {},
            blip = false,
            radius = 3.0,
            workbenchType = {'survival','weapons','medical'}
        },
        -- {
        --     coords = vector3(1346.95, 4390.88, 44.36),
        --     heading = 270.0,
        --     jobs = {'mayor'},
        --     blip = true,
        --     radius = 3.0,
        --     workbenchType = 'medical'
        -- },
        {
            coords = vector3(1346.35, 4389.77, 44.34),
            heading = 350.2,
            jobs = {},
            blip = false,
            radius = 3.0,
            workbenchType = 'medical'
        },
        -- Universal Workbench Example - Shows ALL crafting recipes from all categories
        -- {
        --     coords = vector3(0.0, 0.0, 0.0), -- Replace with your desired coordinates
        --     heading = 0.0,
        --     jobs = {},
        --     blip = true,
        --     radius = 3.0,
        --     workbenchType = 'universal'
        -- }
    },
    
    Recipes = {
        -- BASIC ITEMS (No skill requirements)
		['weapon_bat'] = {
			Level = 0,
			Category = 'Weapons',
			isGun = true,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 40,
			WorkbenchType = 'weapons',
			
			Ingredients = {
				['copper'] = 30,
				['metalscrap'] = 20,
				['iron'] = 20
			}
		},
		['weapon_switchblade'] = {
			Level = 0,
			Category = 'Weapons',
			isGun = true,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 40,
			WorkbenchType = 'weapons',
			
			Ingredients = {
				['copper'] = 30,
				['metalscrap'] = 20,
				['iron'] = 30,
			}
		},
		['weapon_m9'] = {
			Level = 0,
			Category = 'Weapons',
			isGun = true,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 180,
			WorkbenchType = 'weapons',
			
			Ingredients = {
				['pistol_part1'] = 1,
				['pistol_part2'] = 1,
				['pistol_part3'] = 1,
				['pistol_spring'] = 1,
				['weapon_m9_blueprint'] = 1,
			}
		},

		['weapon_revolver'] = {
			Level = 0,
			Category = 'Weapons',
			isGun = true,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 180,
			WorkbenchType = 'weapons',
			
			Ingredients = {
				['pistol_part1'] = 1,
				['pistol_part2'] = 1,
				['pistol_part3'] = 1,
				['pistol_spring'] = 1,
				['weapon_revolver_blueprint'] = 1,
			}
		},

		['weapon_banksongp2kvector'] = {
			Level = 0,
			Category = 'Weapons',
			isGun = true,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 180,
			WorkbenchType = 'weapons',
			
			Ingredients = {
				['smg_part1'] = 1,
				['smg_part2'] = 1,
				['smg_part3'] = 1,
				['smg_spring'] = 1,
				['jewels'] = 30,
				['weapon_9mmarpblue2_blueprint'] = 1,
			}
		},


		['pistol_part1'] = {
			Level = 0,
			Category = 'Weapons',
			isGun = true,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 40,
			WorkbenchType = 'weapons',
			
			Ingredients = {
				['copper'] = 45,
				['metalscrap'] = 60,
				['iron'] = 45,
			}
		},

		['pistol_part2'] = {
			Level = 0,
			Category = 'Weapons',
			isGun = true,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 40,
			WorkbenchType = 'weapons',
			
			Ingredients = {
				['steel'] = 45,
				['metalscrap'] = 40,
				['aluminum'] = 45,
			}
		},

		['pistol_part3'] = {
			Level = 0,
			Category = 'Weapons',
			isGun = true,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 40,
			WorkbenchType = 'weapons',
			
			Ingredients = {
				['copper'] = 40,
				['metalscrap'] = 60,
				['iron'] = 45,
			}
		},

		['smg_part1'] = {
			Level = 0,
			Category = 'Weapons',
			isGun = true,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 40,
			WorkbenchType = 'weapons',
			
			Ingredients = {
				['copper'] = 45,
				['metalscrap'] = 60,
				['iron'] = 45,
			}
		},

		['smg_part2'] = {
			Level = 0,
			Category = 'Weapons',
			isGun = true,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 40,
			WorkbenchType = 'weapons',
			
			Ingredients = {
				['steel'] = 45,
				['metalscrap'] = 40,
				['aluminum'] = 45,
			}
		},

		['smg_part3'] = {
			Level = 0,
			Category = 'Weapons',
			isGun = true,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 40,
			WorkbenchType = 'weapons',
			
			Ingredients = {
				['copper'] = 40,
				['metalscrap'] = 60,
				['iron'] = 45,
			}
		},

		['ammocrate'] = {
			Level = 0,
			Category = 'Weapons',
			isGun = false,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 40,
			WorkbenchType = 'weapons',
			Ingredients = {
				['gunpowder'] = 8,
				['ammo_shell'] = 10,
			}
		},
	
		-- SURVIVAL WORKBENCH RECIPES
		['advancedlockpick'] = {
			Level = 0,
			Category = 'survival',
			isGun = false,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 40,
			WorkbenchType = 'survival',
			SkillRequirement = {
				category = 'personal',
				skill = {'skill_139','skill_12','skill_122'}
			},
			Ingredients = {
				['aluminum'] = 20,
				['plastic'] = 10,
				['iron'] = 10,
				['lockpick'] = 1,
			}
		},
		['trojan_usb'] = {
			Level = 0,
			Category = 'Electronics',
			isGun = false,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 40,
			WorkbenchType = 'survival',
			
			Ingredients = {
				['empty_usb'] = 1,
				['corrupt_data'] = 5
			}
		},
		['electronickit'] = {
			Level = 0,
			Category = 'Electronics',
			isGun = false,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 40,
			WorkbenchType = 'survival',
			
			Ingredients = {
				['metalscrap'] = 30,
				['plastic'] = 20,
				['circuit_board'] = 2,
				['wires'] = 10,
			}
		},
		['radio'] = {
			Level = 0,
			Category = 'Electronics',
			isGun = false,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 40,
			WorkbenchType = 'survival',
			Ingredients = {
				['electronickit'] = 1,
				['broken_plastic'] = 10,
				['wires'] = 10,
				['broken_glass'] = 5,
			}
		},
		['gunpowder'] = {
			Level = 0,
			Category = 'Electronics',
			isGun = false,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 20,
			WorkbenchType = 'survival',
			Ingredients = {
				['graphite_chunk'] = 5,
				['sulfur_chunk'] = 5,
			}
		},
		['handcuffs'] = {
			Level = 0,
			Category = 'survival',
			isGun = false,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 40,
			WorkbenchType = 'survival',
			Ingredients = {
				['metalscrap'] = 20,
				['steel'] = 20,
				['aluminum'] = 20
			}
		},
		['repair_kit'] = {
			Level = 0,
			Category = 'Survival',
			isGun = false,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 40,
			WorkbenchType = 'survival',
			Ingredients = {
				['metalscrap'] = 20,
				['steel'] = 20,
				['aluminum'] = 20,
				['rubber'] = 20,
				['iron'] = 20,
				['glass'] = 20,

			}
		},
		
		-- MEDICAL WORKBENCH RECIPES
		['adrenaline'] = {
			Level = 0,
			Category = 'Medical',
			isGun = false,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 5,
			WorkbenchType = 'medical',
			SkillRequirement = {
				category = 'herbalAlchemist',
				skill = 'skill_23'
			},
			Ingredients = {
				['syringe'] = 1,
				['bitratrate'] = 5,
				['cotton'] = 3
			}
		},
		
		
		-- Items without skill requirements (old recipes)
		
		['regular_backpack'] = {
			Level = 0,
			Category = 'Clothing',
			isGun = false,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 60,
			WorkbenchType = 'medical',
			SkillRequirement = {
				category = 'personal',
				skill = 'skill_30'
			},
			Ingredients = {
				['leather'] = 5,
				['dirty_clothes'] = 10,
				['threads'] = 30,
			}
		},
		['athlete_backpack'] = {
			Level = 0,
			Category = 'Clothing',
			isGun = false,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 120,
			WorkbenchType = 'medical',
			SkillRequirement = {
				category = 'personal',
				skill = 'skill_30'
			},
			Ingredients = {
				['leather'] = 10,
				['dirty_clothes'] = 20,
				['threads'] = 50,
			}
		},
		['tactical_backpack'] = {
			Level = 0,
			Category = 'Clothing',
			isGun = false,
			Jobs = {},
			JobGrades = {},
			Amount = 1,
			SuccessRate = 100,
			requireBlueprint = false,
			Time = 180,
			WorkbenchType = 'medical',
			SkillRequirement = {
				category = 'personal',
				skill = 'skill_30'
			},
			Ingredients = {
				['leather'] = 20,
				['heavy_clothes'] = 20,
				['nylon_threads'] = 20,
			}
		}
    },
    
    Text = {
        ['not_enough_ingredients'] = 'You dont have enough ingredients',
        ['you_cant_hold_item'] = 'You cant hold the item',
        ['item_crafted'] = 'Item crafted successfully!',
        ['wrong_job'] = 'You cant access this workbench',
        ['workbench_hologram'] = '[~g~E~w~] %s',
        ['wrong_usage'] = 'Wrong usage of command',
        ['inv_limit_exceed'] = 'Inventory limit exceeded!',
        ['crafting_failed'] = 'Crafting failed!',
        ['skill_required'] = 'You need the skill: %s to craft this item',
        ['skill_not_unlocked'] = 'This item requires a specific skill to unlock'
    }
}