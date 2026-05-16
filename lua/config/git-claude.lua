-- ~/.config/nvim/lua/config/git-claude.lua
--
-- :ClaudeCommit -- ask the running Claude session (via claudecode.nvim) to
-- write a commit message for the staged diff, then auto-open fugitive's
-- commit buffer pre-filled with that message for review and :wq.
--
-- Bridge: the diff is dropped on disk, the prompt is injected into Claude's
-- terminal via chansend, and Claude is instructed to Write the result to a
-- sentinel file. An fs_event watcher picks the file up and opens the buffer.

local DIFF_FILE = ".claude-commit-diff.patch"
local MSG_FILE = ".claude-commit-msg.txt"
local WATCH_TIMEOUT_MS = 120000

local function git_dir()
  local out = vim.fn.system("git rev-parse --git-dir"):gsub("%s+$", "")
  if vim.v.shell_error ~= 0 or out == "" then return nil end
  return vim.fn.fnamemodify(out, ":p"):gsub("/$", "")
end

local function stage_diff(gd)
  local staged_names = vim.fn.system("git diff --cached --name-only"):gsub("%s+$", "")
  if staged_names == "" then
    vim.notify("Nothing staged. Run `:Git add -A` or stage hunks first.", vim.log.levels.WARN)
    return nil
  end
  local diff = vim.fn.system("git diff --cached")
  local diff_path = gd .. "/" .. DIFF_FILE
  local f, err = io.open(diff_path, "w")
  if not f then
    vim.notify("Couldn't write diff file: " .. tostring(err), vim.log.levels.ERROR)
    return nil
  end
  f:write(diff)
  f:close()
  return diff_path
end

local function claude_jobid()
  local ok, term = pcall(require, "claudecode.terminal")
  if not ok then
    vim.notify("claudecode.nvim is not loaded", vim.log.levels.ERROR)
    return nil
  end

  local bufnr = term.get_active_terminal_bufnr()
  if not bufnr then
    pcall(term.open)
    local deadline = vim.uv.now() + 2000
    while vim.uv.now() < deadline do
      bufnr = term.get_active_terminal_bufnr()
      if bufnr then break end
      vim.wait(50)
    end
  end
  if not bufnr then
    vim.notify("Claude terminal not available. Open it with :ClaudeCode first.", vim.log.levels.ERROR)
    return nil
  end

  local jobid = vim.b[bufnr].terminal_job_id
  if not jobid or jobid == 0 then
    vim.notify("Claude terminal has no job id", vim.log.levels.ERROR)
    return nil
  end
  return jobid
end

local function build_prompt(diff_path, msg_path)
  return string.format(
    [[Write a git commit message for the staged diff in `%s`.

Rules:
- First line: `[type] short description` (max 72 chars, imperative mood, no trailing period).
- Allowed types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.
- If the change is non-trivial, add a blank line then a body wrapped at 72 cols explaining WHY.
- Read the diff with the Read tool, then write ONLY the commit message (no fences, no preamble) to `%s` using the Write tool.
- After writing the file, reply with a single line: DONE.]],
    diff_path,
    msg_path
  )
end

local function open_commit_buffer(msg_path)
  vim.cmd("botright Git commit -e -F " .. vim.fn.shellescape(msg_path))
end

local function watch_for(msg_path, on_ready)
  local dir = vim.fn.fnamemodify(msg_path, ":h")
  local target = vim.fn.fnamemodify(msg_path, ":t")
  local handle = vim.uv.new_fs_event()
  if not handle then
    vim.notify("fs_event unavailable; falling back to polling", vim.log.levels.WARN)
  end

  local fired = false
  local function fire()
    if fired then return end
    fired = true
    if handle then
      pcall(handle.stop, handle)
      pcall(handle.close, handle)
    end
    vim.schedule(function()
      if vim.fn.filereadable(msg_path) == 1 then
        on_ready()
      else
        vim.notify("Claude signaled but " .. msg_path .. " is not readable", vim.log.levels.ERROR)
      end
    end)
  end

  if handle then
    handle:start(dir, {}, function(err, fname, _events)
      if err then return end
      if fname == target then
        vim.schedule(function()
          if vim.fn.filereadable(msg_path) == 1 then fire() end
        end)
      end
    end)
  end

  vim.defer_fn(function()
    if fired then return end
    if vim.fn.filereadable(msg_path) == 1 then
      fire()
    else
      if handle then
        pcall(handle.stop, handle)
        pcall(handle.close, handle)
      end
      vim.notify("Claude commit-message timeout after " .. (WATCH_TIMEOUT_MS / 1000) .. "s.", vim.log.levels.WARN)
    end
  end, WATCH_TIMEOUT_MS)
end

local function run_claude_commit()
  local gd = git_dir()
  if not gd then
    vim.notify("Not a git repo?", vim.log.levels.ERROR)
    return
  end

  local msg_path = gd .. "/" .. MSG_FILE
  os.remove(msg_path)

  local diff_path = stage_diff(gd)
  if not diff_path then return end

  local jobid = claude_jobid()
  if not jobid then return end

  local prompt = build_prompt(diff_path, msg_path)
  vim.notify("Asking Claude for a commit message...", vim.log.levels.INFO)

  vim.api.nvim_chan_send(jobid, prompt .. "\r")

  watch_for(msg_path, function()
    open_commit_buffer(msg_path)
  end)
end

vim.api.nvim_create_user_command("ClaudeCommit", run_claude_commit, {
  desc = "Ask Claude session to write a commit message; auto-open commit buffer pre-filled",
})

vim.keymap.set("n", "<leader>gm", "<cmd>ClaudeCommit<cr>", { desc = "Claude: commit (review)" })
