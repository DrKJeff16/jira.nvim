local M = {}

local api = vim.api

local state = require "jira.state"
local config = require "jira.config"
local render = require "jira.render"
local util = require "jira.util"
local sprint = require("jira.jira-api.sprint")
local ui = require("jira.ui")

M.setup = function(opts)
  config.setup(opts)
end

M.open = function(project_key)
  -- If already open, just focus
  if state.win and api.nvim_win_is_valid(state.win) then
    api.nvim_set_current_win(state.win)
    return
  end

  -- Validate Config
  local jc = config.options.jira
  if not jc.base or jc.base == "" or not jc.email or jc.email == "" or not jc.token or jc.token == "" then
    vim.notify("Jira configuration is missing. Please run setup() with base, email, and token.", vim.log.levels.ERROR)
    return
  end

  if not project_key then
    project_key = vim.fn.input("Jira Project Key: ")
  end

  if not project_key or project_key == "" then
     vim.notify("Project key is required", vim.log.levels.ERROR)
     return
  end

  ui.start_loading("Loading Sprint Data for " .. project_key .. "...")
  
  sprint.get_active_sprint_issues(project_key, function(issues, err)
    if err then
      vim.schedule(function()
        ui.stop_loading()
        vim.notify("Error: " .. err, vim.log.levels.ERROR)
      end)
      return
    end

    if not issues or #issues == 0 then
      vim.schedule(function()
        ui.stop_loading()
        vim.notify("No issues in active sprint.", vim.log.levels.WARN)
      end)
      return
    end

    -- Fetch Status Colors
    local api_client = require("jira.jira-api.api")
    api_client.get_project_statuses(project_key, function(project_statuses, st_err)
      vim.schedule(function()
        ui.stop_loading()
        
        -- Setup UI
        ui.create_window()
        ui.setup_static_highlights()
        if not st_err and project_statuses then
          ui.setup_highlights(project_statuses)
        end

        local tree = util.build_issue_tree(issues)
        render.render_issue_tree(tree)
        vim.notify("Loaded Dashboard for " .. project_key, vim.log.levels.INFO)
      end)
    end)
  end)
end

return M