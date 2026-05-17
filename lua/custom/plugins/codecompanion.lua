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
    interactions = {
      adapters = {
        acp = {
          claude_code = function()
              return require("codecompanion.adapters").extend("claude_code", {
                env = {
                  api_key = os.getenv("CLAUDE_API_KEY") or "",
                }, 
              })
          end,
        },
        http = {
--           gemini = function()
--               return require("codecompanion.adapters").extend("gemini", {
--                 env = {
--                   api_key = os.getenv("GEMINI_API_KEY") or "",
--                 }, 
--               })
--           end,
          anthropic = function()
              return require("codecompanion.adapters").extend("anthropic", {
                env = {
                  api_key = os.getenv("ANTHROPIC_API_KEY") or "",
                }, 
              })
          end,
        },
      },
      chat = {
        adapter = "copilot",
        model = "claude-opus-4.6",
      },
      inline = {
        adapter = "copilot",
        model = "claude-opus-4.6",
      },
      cli = {
        agent = "claude_code",
        agents = {
          claude_code = {
            cmd = "claude",
            args = {},
            description = "Claude Code CLI",
            provider = "terminal",
          }
        },
      }
    }
  }
}
