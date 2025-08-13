local opts = { noremap = true, silent = true }

vim.g.mapleader = " "

-- stylua: ignore start
vim.keymap.set('n', '<Esc>', ':nohl<CR>')
vim.keymap.set("i", "jj", "<Esc>", vim.tbl_extend("force", opts, { desc = "exit insert mode" }))

vim.keymap.set("v", "J", ":m '>+1<CR>gv", vim.tbl_extend("force", opts, { desc = "Move block down" }))
vim.keymap.set("v", "K", ":m '<-2<CR>gv", vim.tbl_extend("force", opts, { desc = "Move block up" }))

-- lines 
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "view line diagnostics" }))
vim.keymap.set("n", "<leader>[d", vim.diagnostic.goto_prev, vim.tbl_extend("force", opts, { desc = "go to previous diagnostic" }))
vim.keymap.set("n", "<leader>]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "go to next diagnostic" }))

-- buffers
vim.keymap.set("n", "<leader>bd", ":bd<CR>", vim.tbl_extend("force", opts, { desc = "Close buffer" }))
vim.keymap.set("n", "<S-l>", ":bn<CR>", vim.tbl_extend("force", opts, { desc = "Next buffer" }))
vim.keymap.set("n", "<S-h>", ":bp<CR>", vim.tbl_extend("force", opts, { desc = "Previous buffer" }))
-- stylua: ignore end
