---@class Jira.Command
local M = {}

---@type string[]
M.SUBCOMMANDS = { "info" }

---@param args string
function M.execute(args)
  local parts = {}
  for part in args:gmatch("%S+") do
    table.insert(parts, part)
  end

  local cmd = parts[1]

  if cmd == "info" then
    local key = parts[2]
    local tab_or_extra = parts[3]

    if not key then
      vim.notify("Usage: :Jira info <issue-key> [comment|description]", vim.log.levels.ERROR)
      return
    end

    local issue_view = require("jira.issue")

    local tab = "description"
    if tab_or_extra and (tab_or_extra == "comment" or tab_or_extra == "comments") then
      tab = "comments"
    end

    issue_view.open(key, tab)
  else
    -- Default: Open Board
    -- Usage: :Jira [project-key]
    local project_key = parts[1]
    require("jira.board").open(project_key)
  end
end

return M
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
