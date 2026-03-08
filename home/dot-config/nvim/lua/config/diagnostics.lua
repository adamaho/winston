vim.diagnostic.config({
	severity_sort = true,
	signs = true,
	underline = true,
	virtual_text = {
		severity = {
			min = vim.diagnostic.severity.WARN,
		},
		source = "if_many",
	},
	float = {
		source = "if_many",
		border = "rounded",
	},
})
