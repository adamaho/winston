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
    local opts = { noremap = true, silent = true }

    vim.keymap.set("n", "<leader>ff", builtin.find_files, vim.tbl_extend("force", opts, { desc = "find all files" }))
    vim.keymap.set("n", "<leader>fh", function() builtin.find_files({ hidden = true }) end,
      vim.tbl_extend("force", opts, { desc = "find all files including hidden files" }))
    vim.keymap.set("n", "<leader>fi", builtin.live_grep, vim.tbl_extend("force", opts, { desc = "find in files" }))
    vim.keymap.set("n", "<leader>fd", builtin.diagnostics,
      vim.tbl_extend("force", opts, { desc = "find diagnostics in workspace" }))
    vim.keymap.set("n", "<leader>fb", function() builtin.diagnostics({ bufnr = 0 }) end,
      vim.tbl_extend("force", opts, { desc = "find diagnostics in current buffer" }))
  end,
}
