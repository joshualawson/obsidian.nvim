local log = require "obsidian.log"

local M = {}

--- Returns the path to the workspace state file.
---@return string
M.filepath = function()
  return vim.fn.stdpath "data" .. "/obsidian-workspaces.json"
end

--- Loads workspace specs from the state file.
--- Returns empty table if file does not exist or is malformed.
---@return obsidian.workspace.WorkspaceSpec[]
M.load = function()
  local path = M.filepath()
  if vim.fn.filereadable(path) == 0 then
    return {}
  end
  local lines = vim.fn.readfile(path)
  local ok, decoded = pcall(vim.fn.json_decode, table.concat(lines, ""))
  if not ok or type(decoded) ~= "table" then
    log.warn("obsidian.nvim: workspace state file is malformed, ignoring: %s", path)
    return {}
  end
  return decoded
end

--- Appends a new workspace spec to the state file.
---@param spec obsidian.workspace.WorkspaceSpec
M.add = function(spec)
  local specs = M.load()
  table.insert(specs, { name = spec.name, path = tostring(spec.path) })
  vim.fn.writefile({ vim.fn.json_encode(specs) }, M.filepath())
end

return M
