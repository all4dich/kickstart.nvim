vim.api.nvim_create_user_command('GitLogTab', function()
  -- Run git log in the current directory
  local output = vim.fn.systemlist('git log --oneline')

  if vim.v.shell_error ~= 0 then
    vim.notify('Git log failed: ' .. table.concat(output, '\n'), vim.log.levels.ERROR)
    return
  end

  -- Open a new tab with an empty buffer
  vim.cmd('tabnew')

  -- Configure the buffer as a scratch buffer
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.swapfile = false
  vim.bo.filetype = 'git'
  vim.api.nvim_buf_set_name(0, 'Git Log')

  -- Write the output
  vim.api.nvim_buf_set_lines(0, 0, -1, false, output)

  -- Make it read-only
  vim.bo.modifiable = false
  vim.bo.readonly = true

  -- Shortcut to close: press 'q'
  vim.keymap.set('n', 'q', '<cmd>tabclose<cr>', {
    buffer = true,
    silent = true,
    desc = 'Close git log tab',
  })
end, { desc = 'Show git log --oneline in a new tab' })
