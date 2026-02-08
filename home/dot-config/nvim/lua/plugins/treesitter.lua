return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		build = ":TSUpdate",
		config = function()
			local ok, ts_configs = pcall(require, "nvim-treesitter.configs")
			if not ok then
				vim.notify("nvim-treesitter.configs not found. Run :Lazy sync.", vim.log.levels.ERROR)
				return
			end

			ts_configs.setup({
				ensure_installed = {
					"lua",
					"astro",
					"typescript",
					"tsx",
					"html",
					"css",
					"json",
					"jsonc",
					"markdown",
					"markdown_inline",
					"bash",
				},
				auto_install = true,
				highlight = {
					enable = true,
				},
				indent = {
					enable = true,
				},
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		opts = {
			max_lines = 1,
		},
	},
}
