return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},
	config = function()
		local telescope = require("telescope")
		local builtin = require("telescope.builtin")

		telescope.setup({
			defaults = {
				file_ignore_patterns = {
					"%.git/",
					"node_modules/",
				},
			},
		})

		local ok_fzf, fzf_err = pcall(telescope.load_extension, "fzf")
		if not ok_fzf then
			vim.schedule(function()
				vim.notify("telescope-fzf-native unavailable: " .. tostring(fzf_err), vim.log.levels.WARN)
			end)
		end

		-- keymaps
		local opts = { noremap = true, silent = true }

		-- stylua: ignore start
		vim.keymap.set("n", "<leader>ff", builtin.find_files, vim.tbl_extend("force", opts, { desc = "find all files" }))
		vim.keymap.set("n", "<leader>fh", function() builtin.find_files({ hidden = true }) end, vim.tbl_extend("force", opts, { desc = "find all files including hidden files" }))
		vim.keymap.set("n", "<leader>fi", builtin.live_grep, vim.tbl_extend("force", opts, { desc = "find in files" }))
		vim.keymap.set("n", "<leader>fd", function() builtin.diagnostics({ bufnr = 0 }) end, vim.tbl_extend("force", opts, { desc = "find diagnostics in current buffer" }))
		vim.keymap.set("n", "<leader>fD", builtin.diagnostics, vim.tbl_extend("force", opts, { desc = "find diagnostics in workspace" }))
		vim.keymap.set("n", "<leader>fb", builtin.buffers, vim.tbl_extend("force", opts, { desc = "find buffers" }))
		-- stylua: ignore end
	end,
}
