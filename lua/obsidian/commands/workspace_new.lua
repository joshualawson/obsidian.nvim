local Workspace = require "obsidian.workspace"
local workspace_state = require "obsidian.workspace_state"
local log = require "obsidian.log"

---@param data obsidian.CommandArgs
return function(data)
  local name = data.fargs[1]
  local path = data.fargs[2]

  if not name or name == "" then
    log.err "workspace_new requires a NAME argument"
    return
  end

  -- Reject duplicate names
  for _, ws in ipairs(Obsidian.workspaces) do
    if ws.name == name then
      log.err("Workspace '%s' already exists", name)
      return
    end
  end

  -- Default path: cwd/.vault
  if not path or path == "" then
    path = vim.uv.cwd() .. "/.vault"
  end

  -- Create the directory
  vim.fn.mkdir(path, "p")
  if vim.fn.isdirectory(path) == 0 then
    log.err("Failed to create directory: %s", path)
    return
  end

  -- Build workspace object (returns nil if path still absent)
  local ws = Workspace.new { name = name, path = path }
  if not ws then
    log.err("Failed to initialise workspace at: %s", path)
    return
  end

  -- Register in memory
  table.insert(Obsidian.workspaces, ws)

  -- Persist to state file
  workspace_state.add { name = name, path = path }

  -- Switch
  Workspace.set(ws)

  log.info("Created and switched to workspace '%s' @ '%s'", name, path)
end
