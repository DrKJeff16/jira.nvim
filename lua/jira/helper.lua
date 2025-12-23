local state = require('jira.state')

local M = {}

M.get_node_at_cursor = function()
  local cursor = vim.api.nvim_win_get_cursor(state.win)
  local row = cursor[1] - 1
  local node = state.line_map[row]
  return node
end

return M
