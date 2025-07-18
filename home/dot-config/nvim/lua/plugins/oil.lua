return {
	"stevearc/oil.nvim",
	dependencies = {},
	lazy = false,
	config = function()
		local oil = require("oil")
		oil.setup({
			view_options = {
				show_hidden = true,
			},
			float = {
				max_width = 30,
				max_height = 40,
				override = function(conf)
					conf.anchor = "NW"
					conf.row = 1
					conf.col = 1
					return conf
				end,
			},
			keymaps = {
				["q"] = "actions.close",
			},
		})
		vim.keymap.set("n", "<leader>fs", oil.open_float, { desc = "toggle file system" })
	end,
}
