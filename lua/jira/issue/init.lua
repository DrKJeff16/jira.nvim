local state = require("jira.issue.state")
local render = require("jira.issue.render")
local jira_api = require("jira.jira-api.api")
local ui = require("jira.common.ui")

local function setup_keymaps()
  local opts = { noremap = true, silent = true, buffer = state.buf }

  -- Quit
  vim.keymap.set("n", "q", function()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      vim.api.nvim_win_close(state.win, true)
    end
  end, opts)

  -- Switch Tabs
  vim.keymap.set("n", "<Tab>", function()
    local next_tab = { description = "comments", comments = "help", help = "description" }
    state.active_tab = next_tab[state.active_tab] or "description"
    render.render_content()
  end, opts)

  vim.keymap.set("n", "D", function()
    state.active_tab = "description"
    render.render_content()
  end, opts)

  vim.keymap.set("n", "C", function()
    state.active_tab = "comments"
    render.render_content()
  end, opts)

  vim.keymap.set("n", "H", function()
    state.active_tab = "help"
    render.render_content()
  end, opts)

  -- Add Comment
  vim.keymap.set("n", "c", function()
    if state.active_tab ~= "comments" then
      vim.notify("Switch to Comments tab to add a comment.", vim.log.levels.WARN)
      return
    end

    vim.ui.input({ prompt = "Comment: " }, function(input)
      if not input or input == "" then
        return
      end

      ui.start_loading("Adding comment...")
      jira_api.add_comment(state.issue.key, input, function(_, err)
        vim.schedule(function()
          ui.stop_loading()
          if err then
            vim.notify("Error adding comment: " .. err, vim.log.levels.ERROR)
            return
          end

          -- Refresh comments
          ui.start_loading("Refreshing comments...")
          jira_api.get_comments(state.issue.key, function(comments, c_err)
            vim.schedule(function()
              ui.stop_loading()
              if not c_err then
                state.comments = comments
                render.render_content()
                vim.notify("Comment added.", vim.log.levels.INFO)
              end
            end)
          end)
        end)
      end)
    end)
  end, opts)
end

---@class Jira.Issue
local M = {}

---@param issue_key string
---@param initial_tab? string
function M.open(issue_key, initial_tab)
  ui.start_loading("Fetching task " .. issue_key .. "...")

  -- Reset state
  state.issue = nil
  state.comments = {}
  state.active_tab = initial_tab or "description"
  state.buf = nil
  state.win = nil

  jira_api.get_issue(issue_key, function(issue, err)
    if err then
      vim.schedule(function()
        ui.stop_loading()
        vim.notify("Error fetching issue: " .. err, vim.log.levels.ERROR)
      end)
      return
    end

    jira_api.get_comments(issue_key, function(comments, c_err)
      vim.schedule(function()
        ui.stop_loading()
        if c_err then
          vim.notify("Error fetching comments: " .. c_err, vim.log.levels.WARN)
        end

        state.issue = issue
        state.comments = comments or {}

        -- Create UI
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option_value("filetype", "markdown", { buf = buf })
        vim.api.nvim_buf_set_option_value("buftype", "nofile", { buf = buf })
        vim.api.nvim_buf_set_option_value("bufhidden", "wipe", { buf = buf })
        vim.api.nvim_buf_set_name(buf, "Jira: " .. issue.key)

        local width = math.floor(vim.o.columns * 0.8)
        local height = math.floor(vim.o.lines * 0.8)

        local win = vim.api.nvim_open_win(buf, true, {
          relative = "editor",
          width = width,
          height = height,
          row = (vim.o.lines - height) / 2,
          col = (vim.o.columns - width) / 2,
          style = "minimal",
          border = "rounded",
        })

        state.buf = buf
        state.win = win

        render.render_content()
        setup_keymaps()
      end)
    end)
  end)
end

return M
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
