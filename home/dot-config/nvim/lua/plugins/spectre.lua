return {
	"nvim-pack/nvim-spectre",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local spectre = require("spectre")

		spectre.setup()

		-- keymaps
		local opts = { noremap = true, silent = true }

		-- stylua: ignore start
		vim.keymap.set("n", "<leader>S", function() spectre.toggle() end, vim.tbl_extend("force", opts, { desc = "toggle spectre" }))
		-- stylua: ignore end
	end,
}
