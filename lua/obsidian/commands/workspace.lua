local Workspace = require "obsidian.workspace"

---@param data obsidian.CommandArgs
return function(data)
  if not data.args or string.len(data.args) == 0 then
    ---@type obsidian.PickerEntry[]
    local items = {}
    for _, ws in ipairs(Obsidian.workspaces) do
      if ws.name ~= ".obsidian.wiki" then
        table.insert(items, {
          user_data = ws,
          text = tostring(ws),
          filename = tostring(ws.path),
        })
      end
    end
    Obsidian.picker.pick(items, {
      prompt_title = "Obsidian Workspace",
      callback = function(entry)
        Workspace.set(entry.user_data)
      end,
    })
  else
    Workspace.set(data.args)
  end
end
