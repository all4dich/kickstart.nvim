return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "hrsh7th/nvim-cmp", -- Optional: for completion
    "nvim-telescope/telescope.nvim", -- Optional: for actions
    "stevearc/dressing.nvim" -- Optional: for UI enhancements
  },
  config = function()
    -- Load the codecompanion module
    require("codecompanion").setup({
      -- Configuration options can be added here
     adapters = {
      gemini = function()
        return require("codecompanion.adapters").extend("gemini", {
          env = {
           api_key = os.getenv("GEMINI_API_KEY") or "",
          },
      })
      end,
    },
    strategies = {
      chat = {
        adapter = "gemini",
      },
      inline = {
        adapter = "gemini",
      },
    },
     -- For example, you can set up keybindings, UI options, etc.
    })
    end,
}
