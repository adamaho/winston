return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"mason-org/mason.nvim",
		"mason-org/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"hrsh7th/nvim-cmp",
	},
	config = function()
		-- lsp
		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = { "lua_ls", "vtsls", "cssls", "astro", "svelte", "rust_analyzer" },
			automatic_enable = true,
		})
		require("mason-tool-installer").setup({
			ensure_installed = { "stylua", "prettierd" },
		})

		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		local on_attach = function(_, bufnr)
			vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

			-- keymaps
			local opts = { noremap = true, silent = true, buffer = bufnr }
      -- stylua: ignore start
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "go to definition" }))
			vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "hover documentation" }))
			vim.keymap.set("n","<leader>ca",vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "open code actions" }))
			-- stylua ignore end
		end

		for _, server in ipairs(require("mason-lspconfig").get_installed_servers()) do
			if server == "vtsls" then
				vim.lsp.config(server, {
					on_attach = on_attach,
					capabilities = capabilities,
					root_markers = { ".git", "pnpm-workspace.yaml", "pnpm-lock.yaml", "bun.lock" },
					experimental = {
						completion = {
							entriesLimit = 5,
						},
					},
				})
			else
				vim.lsp.config(server, {
					on_attach = on_attach,
					capabilities = capabilities,
				})
			end
		end
	end,
}
