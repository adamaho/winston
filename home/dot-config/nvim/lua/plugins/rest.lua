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
		-- Configure JSON formatting for rest.nvim responses
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "json",
			callback = function()
				vim.bo.formatprg = "jq"
			end,
		})
	end,
}
