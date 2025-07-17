return {
  'stevearc/oil.nvim',
  dependencies = {},
  lazy = false,
  config = function()
    local oil = require("oil")
    oil.setup({ view_options = { show_hidden = true } })
    vim.keymap.set(
      "n",
      "<leader>fs",
      function()
        if vim.bo.filetype == "oil" then
          oil.close()
        else
          oil.open_float()
        end
      end,
      { desc = "toggle file system" }
    )
  end,
}
