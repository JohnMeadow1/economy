extends Node2D
class_name Dwelling, "res://Sprites/Farm/House_Mini.png"


enum SettlementType {NO_SETTLEMENT = -1, ABANDONED, SETTLEMENT, VILLAGE, TOWN}
var SettlementName = ["ABANDONED", "SETTLEMENT", "VILLAGE", "TOWN"]
var settlement_size = SettlementType.SETTLEMENT
var SettlementSprites = ["res://Sprites/Town/Church_5_2.png",
                       "res://Sprites/Town/Church_3.png",
                       "res://Sprites/Town/Church_5_1.png",
                       "res://Sprites/Town/Church_1.png"]

#NOTE population should be changed to secondary variable for suming POPULATION_size array
export(int) var population: int         = 2

export(int) var radius: int             = 300
export(int) var population_idle: int    = 0
export(float) var stockpile_food: float = 0.0

#var population_transporting: int = 0 # local for transport_resources func
var population_collecting: int                      = 0
var population_needed_for_transport_this_cycle: int = 0
var population_needed_for_transport_next_cycle: int = 0
var population_reserved_for_transport: int          = 0
var total_population_transporting_this_cycle: int   = 0
var consumption_food: float                         = 0.0
var cycle: float                                    = 0.0

#NOTE each array holds specific data per age range (from 1 to 100 years old)
var POPULATION_size:PoolIntArray        = []
var POPULATION_food_req:PoolRealArray   = []
var POPULATION_work_eff:PoolRealArray   = []
var POPULATION_death_rate:PoolRealArray = []
var POPULATION_male_ratio:PoolRealArray = []

var POPULATION_birth_rate:PoolRealArray = [] 
var population_birth_multiplier:float   = 1.0

var POPULATION_housing_req:PoolRealArray = []
var housing:float = 10.0
