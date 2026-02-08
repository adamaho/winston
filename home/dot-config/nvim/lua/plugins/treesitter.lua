return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		config = function()
			local ok, treesitter = pcall(require, "nvim-treesitter")
			if not ok then
				vim.notify("nvim-treesitter module not found. Run :Lazy sync.", vim.log.levels.ERROR)
				return
			end

			local languages = {
				"lua",
				"astro",
				"typescript",
				"tsx",
				"html",
				"css",
				"json",
				"markdown",
				"markdown_inline",
				"bash",
			}
			local filetypes = {
				"lua",
				"astro",
				"typescript",
				"tsx",
				"html",
				"css",
				"json",
				"markdown",
				"sh",
			}

			treesitter.setup({})
			treesitter.install(languages)

			local ts_group = vim.api.nvim_create_augroup("nvim_treesitter_start", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				group = ts_group,
				pattern = filetypes,
				callback = function(args)
					pcall(vim.treesitter.start, args.buf)
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
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
