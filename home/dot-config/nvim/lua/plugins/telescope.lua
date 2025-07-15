return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  config = function()
    local telescope = require("telescope")
    local builtin = require("telescope.builtin")

    telescope.setup({
      defaults = {
        file_ignore_patterns = {
          "%.git/",
          "node_modules/",
        },
      },
    })

    telescope.load_extension("fzf")

    -- keymaps 
    vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "find all files" })
    vim.keymap.set("n", "<leader>fh", function() builtin.find_files({ hidden = true }) end, { desc = "find all files including hidden files" })
    vim.keymap.set("n", "<leader>fi", builtin.live_grep, { desc = "find in files" })
    vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "find diagnostics in workspace" })
    vim.keymap.set("n", "<leader>fb", function() builtin.diagnostics({bufnr=0}) end, { desc = "find diagnostics in current buffer" })
  end,
}
