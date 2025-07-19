return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	keys = function()
		local harpoon = require("harpoon")

		return {
			{
				"<leader>a",
				function()
					harpoon:list():add()
				end,
				desc = "add to harpoon",
			},
			{
				"<C-e>",
				function()
					harpoon.ui:toggle_quick_menu(harpoon:list())
				end,
				desc = "toggle harpoon menu",
			},
			{
				"<leader>1",
				function()
					harpoon:list():select(1)
				end,
				desc = "go to harpoon 1",
			},
			{
				"<leader>2",
				function()
					harpoon:list():select(2)
				end,
				desc = "go to harpoon 2",
			},
			{
				"<leader>3",
				function()
					harpoon:list():select(3)
				end,
				desc = "go to harpoon 3",
			},
			{
				"<leader>4",
				function()
					harpoon:list():select(4)
				end,
				desc = "go to harpoon 4",
			},
		}
	end,
}
