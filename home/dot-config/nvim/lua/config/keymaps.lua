local opts = { noremap = true, silent = true }

vim.g.mapleader = " "

-- stylua: ignore start
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", vim.tbl_extend("force", opts, { desc = "move lines down" }))
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", vim.tbl_extend("force", opts, { desc = "move lines up" }))

vim.keymap.set("i", "jj", "<Esc>", vim.tbl_extend("force", opts, { desc = "exit insert mode" }))

vim.keymap.set("n", "j", "gj", vim.tbl_extend("force", opts, { desc = "move down by display line" }))
vim.keymap.set("n", "k", "gk", vim.tbl_extend("force", opts, { desc = "move up by display line" }))
vim.keymap.set("n", "<Down>", "gj", vim.tbl_extend("force", opts, { desc = "move down by display line" }))
vim.keymap.set("n", "<Up>", "gk", vim.tbl_extend("force", opts, { desc = "move up by display line" }))

vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "view line diagnostics" }))
vim.keymap.set("n", "<leader>[d", vim.diagnostic.goto_prev, vim.tbl_extend("force", opts, { desc = "go to previous diagnostic" }))
vim.keymap.set("n", "<leader>]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "go to next diagnostic" }))
-- stylua: ignore end
