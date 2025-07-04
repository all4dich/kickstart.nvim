return  {
  'echasnovski/mini.nvim',
  version = false, -- Use the latest version
  config = function()
    require('mini.starter').setup {
      items = {
        { name = 'Find File', action = 'Telescope find_files' },
        { name = 'Recent Files', action = 'Telescope oldfiles' },
        { name = 'Find Word', action = 'Telescope live_grep' },
        { name = 'Find Help', action = 'Telescope help_tags' },
        { name = 'Find Keymaps', action = 'Telescope keymaps' },
        { name = 'Find Commands', action = 'Telescope commands' },
      },
      header = 'Welcome to Neovim!',
    }
  end,
}
