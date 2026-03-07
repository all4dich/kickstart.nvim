return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "hrsh7th/nvim-cmp", -- Optional: for completion
    "nvim-telescope/telescope.nvim", -- Optional: for actions
    "stevearc/dressing.nvim" -- Optional: for UI enhancements
  },
  opts = {
    adapters = {
      http = {
          gemini = function()
            return require("codecompanion.adapters").extend("gemini", {
              env = {
               api_key = os.getenv("GEMINI_API_KEY") or "",
              },
          })
          end,
          copilot = function()
            return require("codecompanion.adapters").extend("copilot", {
              env = {
               api_key = os.getenv("COPILOT_API_KEY") or "",
od
              },
          })
          end,
      }
    },
    strategies = {
      chat = {
        adapter = {
          name = "copilot",
          model = "gemini-3-pro-preview"
        },
      },
      inline = {
        adapter = "copilot",
      },
      cmd = {
        adapter = "copilot",
      },
    },
  }
}
