local Path = require "obsidian.path"
local workspace = require "obsidian.workspace"
local new_set, eq = MiniTest.new_set, MiniTest.expect.equality
local expect = MiniTest.expect

local T = new_set()

T["new"] = new_set()

T["new"]["should be able to initialize a workspace"] = function()
  local tmpdir = Path.temp()
  tmpdir:mkdir()
  local ws = workspace.new {
    path = tmpdir,
    name = "test_workspace",
  }
  assert(ws, "")
  eq("test_workspace", ws.name)
  eq(true, tmpdir:resolve() == ws.path)
end

local workspace_state = require "obsidian.workspace_state"

T["setup"] = new_set() -- TODO: test for cwd vs first ws

T["setup"]["merges state-file workspaces into workspace list"] = function()
  local config_dir = Path.temp()
  config_dir:mkdir()
  local state_dir = Path.temp()
  state_dir:mkdir()

  local orig = workspace_state.load
  workspace_state.load = function()
    return { { name = "state_ws", path = tostring(state_dir) } }
  end

  local wss = workspace.setup { { path = tostring(config_dir), name = "config_ws" } }
  workspace_state.load = orig

  eq(2, #wss)
  local names = vim.tbl_map(function(ws) return ws.name end, wss)
  eq(true, vim.tbl_contains(names, "config_ws"))
  eq(true, vim.tbl_contains(names, "state_ws"))
end

T["setup"]["config workspace name takes precedence over state-file duplicate"] = function()
  local config_dir = Path.temp()
  config_dir:mkdir()

  local orig = workspace_state.load
  workspace_state.load = function()
    return { { name = "config_ws", path = tostring(config_dir) } }
  end

  local wss = workspace.setup { { path = tostring(config_dir), name = "config_ws" } }
  workspace_state.load = orig

  eq(1, #wss)
end

T["setup"]["should error for no valid workspace"] = function()
  local tmpdir = Path.temp()
  expect.error = function()
    workspace.setup {
      {
        path = tmpdir,
        name = "test_workspace that does not exist",
      },
    }
  end

  tmpdir:mkdir()

  expect.no_error = function()
    workspace.setup {
      {
        path = tmpdir,
        name = "test_workspace that does exist",
      },
    }
  end
end

T["find"] = new_set()

T["find"]["find and resolve workspace based on dirs"] = function()
  local tmpdir = Path.temp()
  tmpdir:mkdir()
  local wss = workspace.setup {
    {
      path = tmpdir,
      name = "test_workspace",
    },
  }

  local subdir = tmpdir / "child"

  subdir:mkdir()

  eq(wss[1], workspace.find(subdir, wss))
end

return T
