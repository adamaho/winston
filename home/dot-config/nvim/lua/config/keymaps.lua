local opts = { noremap = true, silent = true }

vim.g.mapleader = " "

vim.keymap.set("i", "jj", "<Esc>", vim.tbl_extend("force", opts, { desc = "exit insert mode" }))

-- diagnostics
vim.keymap.set(
	"n",
	"<leader>d",
	vim.diagnostic.open_float,
	vim.tbl_extend("force", opts, { desc = "view line diagnostics" })
)
vim.keymap.set(
	"n",
	"<leader>[d",
	vim.diagnostic.goto_prev,
	vim.tbl_extend("force", opts, { desc = "go to previous diagnostic" })
)
vim.keymap.set(
	"n",
	"<leader>]d",
	vim.diagnostic.goto_next,
	vim.tbl_extend("force", opts, { desc = "go to next diagnostic" })
)
