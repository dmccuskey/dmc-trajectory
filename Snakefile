# dmc-trajectory

try:
	if not gSTARTED: print( gSTARTED )
except:
	MODULE = "dmc-trajectory"
	include: "../DMC-Corona-Library/snakemake/Snakefile"

module_config = {
	"name": "dmc-trajectory",
	"module": {
		"dir": "dmc_corona",
		"files": [
			"dmc_trajectory.lua",
		],
		"requires": [
			"dmc-corona-boot"
		]
	},
	"examples": {
		"base_dir": "examples",
		"apps": [
			{
				"exp_dir": "dmc-trajectory-basic",
				"requires": []
			},
			{
				"exp_dir": "dmc-trajectory-direction",
				"requires": []
			},
			{
				"exp_dir": "dmc-trajectory-multiple",
				"requires": []
			},
		]
	},
	"tests": {
		"files": [],
		"requires": []
	}
}


register( "dmc-trajectory", module_config )
