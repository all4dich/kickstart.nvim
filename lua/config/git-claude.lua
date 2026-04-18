-- ~/.config/nvim/lua/config/git-claude.lua

local function generate_commit_message()
  -- Check there are staged changes
  local staged_files = vim.fn.system("git diff --cached --name-only"):gsub("%s+$", "")
  if vim.v.shell_error ~= 0 then
    vim.notify("Not a git repo?", vim.log.levels.ERROR)
    return nil
  end
  if staged_files == "" then
    vim.notify("Nothing staged. Run `:Git add -A` or stage hunks first.", vim.log.levels.WARN)
    return nil
  end

  vim.notify("Asking Claude for a commit message...", vim.log.levels.INFO)

  local prompt = [[
Write a conventional-commit message for the following staged diff.

Rules:
- First line: <type>(<scope>): <summary>  (max 72 chars, imperative mood, no trailing period)
- Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
- If the change is non-trivial, add a blank line then a body (wrap at 72 cols) explaining WHY.
- Output ONLY the commit message. No preamble, no code fences, no explanation.

Diff:
]]

  local diff = vim.fn.system("git diff --cached")
  local full_prompt = prompt .. diff

  -- Call claude in headless mode. Use a tempfile to avoid shell-escaping the whole diff.
  local tmp = vim.fn.tempname()
  local f = io.open(tmp, "w")
  if not f then
    vim.notify("Couldn't create tempfile", vim.log.levels.ERROR)
    return nil
  end
  f:write(full_prompt)
  f:close()

  local cmd = string.format("claude -p < %s", vim.fn.shellescape(tmp))
  local msg = vim.fn.system(cmd)
  os.remove(tmp)

  if vim.v.shell_error ~= 0 then
    vim.notify("claude failed:\n" .. msg, vim.log.levels.ERROR)
    return nil
  end

  -- Trim whitespace and strip any stray code fences Claude might add
  msg = msg:gsub("^%s+", ""):gsub("%s+$", "")
  msg = msg:gsub("^```%w*\n", ""):gsub("\n```$", "")
  return msg
end

-- :ClaudeCommit  → generate message, open fugitive's commit buffer pre-filled
vim.api.nvim_create_user_command("ClaudeCommit", function()

  local msg = generate_commit_message()
  if not msg then return end

  -- Use git commit directly with -m (multiline-safe via tempfile)
  local tmp = vim.fn.tempname()
  local f = io.open(tmp, "w")
  f:write(msg)
  f:close()

    -- Force a bottom horizontal split for the commit buffer
  -- Open fugitive's commit buffer with the message as a template so you can review/edit.
  -- -e = edit, -F = read message from file
  vim.cmd("botright Git commit -e -F " .. vim.fn.shellescape(tmp))

  -- Clean up after nvim exits (fugitive reads the file synchronously so this is safe)
  vim.defer_fn(function() os.remove(tmp) end, 5000)
end, { desc = "Generate commit message with Claude and open commit buffer" })

-- :ClaudeCommitNow → same, but commit immediately without the edit buffer
vim.api.nvim_create_user_command("ClaudeCommitNow", function()
  local msg = generate_commit_message()
  if not msg then return end

  local tmp = vim.fn.tempname()
  local f = io.open(tmp, "w")
  f:write(msg)
  f:close()

  vim.cmd("Git commit -F " .. vim.fn.shellescape(tmp))
  os.remove(tmp)
end, { desc = "Generate commit message with Claude and commit immediately" })

-- Keymaps
vim.keymap.set("n", "<leader>gm", "<cmd>ClaudeCommit<cr>",    { desc = "Claude: commit (review)" })
vim.keymap.set("n", "<leader>gM", "<cmd>ClaudeCommitNow<cr>", { desc = "Claude: commit (auto)" })
