-- ~/.config/nvim/lua/config/git-commit.lua
--
-- Generates commit messages using GitHub Copilot's CLI (`copilot -p`).

local function generate_commit_message()
  local staged_files = vim.fn.system("git diff --cached --name-only"):gsub("%s+$", "")
  if vim.v.shell_error ~= 0 then
    vim.notify("Not a git repo?", vim.log.levels.ERROR)
    return nil
  end
  if staged_files == "" then
    vim.notify("Nothing staged. Run `:Git add -A` or stage hunks first.", vim.log.levels.WARN)
    return nil
  end

  vim.notify("Asking Copilot for a commit message...", vim.log.levels.INFO)

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

  -- `--allow-all-tools` is required for non-interactive mode.
  -- `--silent` strips the stats footer so stdout is just the model's reply.
  -- `--no-color` avoids ANSI escapes leaking into the commit message.
  local cmd = string.format(
    "copilot -p %s --allow-all-tools --silent --no-color",
    vim.fn.shellescape(full_prompt)
  )
  local msg = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify("copilot failed:\n" .. msg, vim.log.levels.ERROR)
    return nil
  end

  msg = msg:gsub("^%s+", ""):gsub("%s+$", "")
  msg = msg:gsub("^```%w*\n", ""):gsub("\n```$", "")
  return msg
end

-- :GitCommit  → generate message, open fugitive's commit buffer pre-filled
vim.api.nvim_create_user_command("GitCommit", function()
  local msg = generate_commit_message()
  if not msg then return end

  local tmp = vim.fn.tempname()
  local f = io.open(tmp, "w")
  f:write(msg)
  f:close()

  -- Force a bottom horizontal split for the commit buffer.
  -- -e = edit, -F = read message from file
  vim.cmd("botright Git commit -e -F " .. vim.fn.shellescape(tmp))

  vim.defer_fn(function() os.remove(tmp) end, 5000)
end, { desc = "Generate commit message with Copilot and open commit buffer" })

-- :GitCommitNow → same, but commit immediately without the edit buffer
vim.api.nvim_create_user_command("GitCommitNow", function()
  local msg = generate_commit_message()
  if not msg then return end

  local tmp = vim.fn.tempname()
  local f = io.open(tmp, "w")
  f:write(msg)
  f:close()

  vim.cmd("Git commit -F " .. vim.fn.shellescape(tmp))
  os.remove(tmp)
end, { desc = "Generate commit message with Copilot and commit immediately" })

-- Keymaps
vim.keymap.set("n", "<leader>gm", "<cmd>GitCommit<cr>",    { desc = "Copilot: commit (review)" })
vim.keymap.set("n", "<leader>gM", "<cmd>GitCommitNow<cr>", { desc = "Copilot: commit (auto)" })
