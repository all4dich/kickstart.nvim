return {
  "github/copilot.vim",
  init = function()
    vim.g.copilot_no_tab_map = true
    vim.keymap.set("i", "<C-J>", 'copilot#Accept("\\<CR>")', {
      expr = true,
      replace_keycodes = false,
      silent = true,
    })
    vim.keymap.set("i", "<M-]>", "<Plug>(copilot-next)")
    vim.keymap.set("i", "<M-[>", "<Plug>(copilot-previous)")
    vim.keymap.set("i", "<C-]>", "<Plug>(copilot-dismiss)")
  end,
}
