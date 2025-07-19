return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "",
			desc = "format",
		},
	},
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			typescript = { "prettierd" },
			typescriptreact = { "prettierd" },
			html = { "prettierd" },
			css = { "prettierd" },
			json = { "prettierd" },
		},
		format_on_save = {
			timeout_ms = 500,
			lsp_fallback = true,
		},
	},
}
