return {
  'stevearc/oil.nvim',
  dependencies = {},
  lazy = false,
  config = function()
	local oil = require("oil")
	oil.setup({})
	vim.keymap.set(
		"n",
		"<leader>fs",
		function()
			local oil = require("oil")
			if vim.bo.filetype == "oil" then
				oil.close()
			else
				oil.open()
			end
		end,
		{ desc = "toggle file system" }
	)
  end,
}
