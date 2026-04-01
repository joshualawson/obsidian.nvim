local workspace_state = require "obsidian.workspace_state"
local new_set, eq = MiniTest.new_set, MiniTest.expect.equality

local T = new_set()

T["filepath"] = new_set()

T["filepath"]["returns path inside stdpath data ending with obsidian-workspaces.json"] = function()
  local fp = workspace_state.filepath()
  eq(true, vim.startswith(fp, vim.fn.stdpath "data"))
  eq(true, vim.endswith(fp, "obsidian-workspaces.json"))
end

T["load"] = new_set()

T["load"]["returns empty table when file does not exist"] = function()
  local orig = workspace_state.filepath
  workspace_state.filepath = function()
    return "/tmp/obsidian-test-nonexistent-" .. os.time() .. ".json"
  end
  local specs = workspace_state.load()
  workspace_state.filepath = orig
  eq(0, #specs)
end

T["load"]["returns empty table for malformed JSON"] = function()
  local path = "/tmp/obsidian-test-malformed-" .. os.time() .. ".json"
  vim.fn.writefile({ "not json {{{{" }, path)
  local orig = workspace_state.filepath
  workspace_state.filepath = function() return path end
  local specs = workspace_state.load()
  workspace_state.filepath = orig
  vim.fn.delete(path)
  eq(0, #specs)
end

T["load"]["returns specs from valid JSON"] = function()
  local path = "/tmp/obsidian-test-valid-" .. os.time() .. ".json"
  local content = vim.fn.json_encode { { name = "myws", path = "/tmp/myws" } }
  vim.fn.writefile({ content }, path)
  local orig = workspace_state.filepath
  workspace_state.filepath = function() return path end
  local specs = workspace_state.load()
  workspace_state.filepath = orig
  vim.fn.delete(path)
  eq(1, #specs)
  eq("myws", specs[1].name)
  eq("/tmp/myws", specs[1].path)
end

T["add"] = new_set()

T["add"]["creates file and adds spec when file does not exist"] = function()
  local path = "/tmp/obsidian-test-add-" .. os.time() .. ".json"
  vim.fn.delete(path)
  local orig = workspace_state.filepath
  workspace_state.filepath = function() return path end
  workspace_state.add { name = "ws1", path = "/tmp/ws1" }
  workspace_state.filepath = orig
  local lines = vim.fn.readfile(path)
  local decoded = vim.fn.json_decode(table.concat(lines, ""))
  vim.fn.delete(path)
  eq(1, #decoded)
  eq("ws1", decoded[1].name)
end

T["add"]["appends to existing file"] = function()
  local path = "/tmp/obsidian-test-append-" .. os.time() .. ".json"
  vim.fn.writefile({ vim.fn.json_encode { { name = "ws1", path = "/tmp/ws1" } } }, path)
  local orig = workspace_state.filepath
  workspace_state.filepath = function() return path end
  workspace_state.add { name = "ws2", path = "/tmp/ws2" }
  workspace_state.filepath = orig
  local lines = vim.fn.readfile(path)
  local decoded = vim.fn.json_decode(table.concat(lines, ""))
  vim.fn.delete(path)
  eq(2, #decoded)
  eq("ws2", decoded[2].name)
end

return T
