return {
	"rest-nvim/rest.nvim",
	dependencies = {
		{
			"nvim-treesitter/nvim-treesitter",
			opts = function(_, opts)
				opts.ensure_installed = opts.ensure_installed or {}
				table.insert(opts.ensure_installed, "http")
				return opts
			end,
		},
		{ "nvim-lua/plenary.nvim" },
		{
			"vhyrro/luarocks.nvim",
			priority = 1000,
			config = true,
			opts = {
				rocks = { "xml2lua" },
			},
		},
	},
	config = function()
		-- Setup rest.nvim with response window below
		require("rest-nvim").setup({
			result = {
				split = "horizontal", -- Opens response below instead of to the left
			},
		})

		-- Configure JSON formatting for rest.nvim responses
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "json",
			callback = function()
				vim.bo.formatprg = "jq"
			end,
		})

		-- Add keymaps for http files
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "http",
			callback = function()
				vim.keymap.set("n", "<leader>rr", "<cmd>Rest run<cr>", { buffer = true, desc = "Run request" })
			end,
		})
	end,
}
