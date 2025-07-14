vim.g.mapleader = " "

-- diagnostics
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "view line diagnostics" })
vim.keymap.set("n", "<leader>[d", vim.diagnostic.goto_prev, { desc = "go to previous diagnostic" })
vim.keymap.set("n", "<leader>]d", vim.diagnostic.goto_next, { desc = "go to next diagnostic" })

