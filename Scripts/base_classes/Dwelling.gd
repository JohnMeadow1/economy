extends Node2D
class_name Dwelling

enum SettlementType{ ABANDONED, SETTLEMENT, VILLAGE, TOWN }
var SettlementNames = ["ABANDONED", "SETTLEMENT", "VILLAGE", "TOWN"]
var settlement_size = SettlementType.SETTLEMENT
export(int) var population:int = 2
var population_idle:int        = 0
var consumption_food:float     = 0.0
var stockpile_food:float       = 0.0

var population_transporting:int= 0