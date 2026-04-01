local Path = require "obsidian.path"
local Workspace = require "obsidian.workspace"
local workspace_state = require "obsidian.workspace_state"
local new_set, eq = MiniTest.new_set, MiniTest.expect.equality

-- Each test gets a fresh obsidian setup with one initial workspace.
-- The state file is reset after each test to avoid cross-test pollution.
local T = new_set {
  hooks = {
    pre_case = function()
      local tmpdir = Path.temp()
      tmpdir:mkdir()
      require("obsidian").setup {
        legacy_commands = false,
        workspaces = { { path = tostring(tmpdir), name = "initial" } },
        log_level = vim.log.levels.ERROR,
      }
    end,
    post_case = function()
      vim.fn.writefile({ "[]" }, workspace_state.filepath())
    end,
  },
}

local handler = function(name, path)
  local args = path and (name .. " " .. path) or name
  local fargs = path and { name, path } or { name }
  require("obsidian.commands.workspace_new") { args = args, fargs = fargs }
end

T["workspace_new"] = new_set()

T["workspace_new"]["creates cwd/.vault when no path given"] = function()
  local cwd = vim.uv.cwd()
  local expected = cwd .. "/.vault"
  handler("testnew")
  eq(true, vim.fn.isdirectory(expected) == 1)
  vim.fn.delete(expected, "rf")
end

T["workspace_new"]["switches to the new workspace"] = function()
  local path = "/tmp/obsidian-test-switch-" .. os.time()
  handler("switched", path)
  eq("switched", Obsidian.workspace.name)
  vim.fn.delete(path, "rf")
end

T["workspace_new"]["creates directory at given path"] = function()
  local path = "/tmp/obsidian-test-custom-" .. os.time()
  handler("custom", path)
  eq(true, vim.fn.isdirectory(path) == 1)
  vim.fn.delete(path, "rf")
end

T["workspace_new"]["persists workspace to state file"] = function()
  local path = "/tmp/obsidian-test-persist-" .. os.time()
  handler("persisted", path)
  local specs = workspace_state.load()
  local found = false
  for _, spec in ipairs(specs) do
    if spec.name == "persisted" then found = true end
  end
  eq(true, found)
  vim.fn.delete(path, "rf")
end

T["workspace_new"]["appends to in-memory workspace list"] = function()
  local before = #Obsidian.workspaces
  local path = "/tmp/obsidian-test-append-" .. os.time()
  handler("appended", path)
  eq(before + 1, #Obsidian.workspaces)
  vim.fn.delete(path, "rf")
end

return T
