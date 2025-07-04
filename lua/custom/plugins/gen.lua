return  {
 "David-Kunz/gen.nvim",
  config = function()
    require('gen').setup({
      model = "gemini-1.5-flash",
      display_mode = "float",
      show_prompt = false,
      show_model = false,
      no_auto_close = false,
      debug = false,
      -- Custom command for direct Gemini API
      command = function(options)
        local api_key = os.getenv("GEMINI_API_KEY")
        if not api_key then
          error("GEMINI_API_KEY environment variable not set")
        end
        
        local body = vim.json.encode({
          contents = {
            {
              parts = {
                { text = options.prompt }
              }
            }
          },
          generationConfig = {
            temperature = 0.7,
            maxOutputTokens = 4096,
          }
        })
        
        local url = "https://generativelanguage.googleapis.com/v1beta/models/" .. options.model .. ":generateContent?key=" .. api_key
        
        return "curl -s -X POST '" .. url .. "' " ..
               "-H 'Content-Type: application/json' " ..
               "-d '" .. body .. "' | " ..
               "jq -r '.candidates[0].content.parts[0].text' 2>/dev/null"
      end,
    })

    -- Key mappings
    vim.keymap.set('v', '<leader>gg', ':Gen<CR>', { desc = "Generate with Gemini" })
    vim.keymap.set('n', '<leader>gg', ':Gen<CR>', { desc = "Generate with Gemini" })
    
    -- Custom Gemini prompts
    require('gen').prompts['Gemini_Explain'] = {
      prompt = "Explain the following $filetype code in detail:\n```$filetype\n$text\n```",
      replace = false
    }
    
    require('gen').prompts['Gemini_Fix'] = {
      prompt = "Fix any bugs or issues in this code. Only output the corrected code:\n```$filetype\n$text\n```",
      replace = true,
      extract = "```$filetype\n(.-)```"
    }
    
    require('gen').prompts['Gemini_Optimize'] = {
      prompt = "Optimize this code for better performance and readability:\n```$filetype\n$text\n```",
      replace = true,
      extract = "```$filetype\n(.-)```"
    }
    
    require('gen').prompts['Gemini_Review'] = {
      prompt = "Provide a detailed code review with suggestions for improvement:\n```$filetype\n$text\n```",
      replace = false
    }
    
    require('gen').prompts['Gemini_Document'] = {
      prompt = "Add comprehensive documentation/comments to this code:\n```$filetype\n$text\n```",
      replace = true,
      extract = "```$filetype\n(.-)```"
    }
  end,
  }

