local M = {}

local function generate_maze(width, height)
  width = (width % 2 == 0) and (width + 1) or width
  height = (height % 2 == 0) and (height + 1) or height

  local grid = {}
  for y = 1, height do
    grid[y] = {}
    for x = 1, width do
      grid[y][x] = "#"
    end
  end

  local stack = {}
  local start_x, start_y = 2, 2
  grid[start_y][start_x] = "S"
  table.insert(stack, { x = start_x, y = start_y })

  local dirs = {
    { x = 0,  y = -2, wx = 0,  wy = -1 },
    { x = 0,  y = 2,  wx = 0,  wy = 1 },
    { x = -2, y = 0,  wx = -1, wy = 0 },
    { x = 2,  y = 0,  wx = 1,  wy = 0 },
  }

  while #stack > 0 do
    local current = stack[#stack]
    local valid_dirs = {}
    for _, d in ipairs(dirs) do
      local nx, ny = current.x + d.x, current.y + d.y
      if nx > 1 and nx < width and ny > 1 and ny < height and grid[ny][nx] == "#" then
        table.insert(valid_dirs, d)
      end
    end

    if #valid_dirs > 0 then
      local d = valid_dirs[math.random(#valid_dirs)]
      grid[current.y + d.wy][current.x + d.wx] = " "
      grid[current.y + d.y][current.x + d.x] = " "
      table.insert(stack, { x = current.x + d.x, y = current.y + d.y })
    else
      table.remove(stack)
    end
  end

  for y = height - 1, 2, -1 do
    for x = width - 1, 2, -1 do
      if grid[y][x] == " " then
        grid[y][x] = "G"
        goto found_goal
      end
    end
  end
  ::found_goal::

  local lines = {}
  for y = 1, height do
    table.insert(lines, table.concat(grid[y], ""))
  end

  return lines, start_x, start_y
end

function M.start(level)
  local width, height = 31, 15
  if level == "hard" then
    width, height = 51, 23
  elseif level == "easy" then
    width, height = 19, 9
  end

  local lines, sx, sy = generate_maze(width, height)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].modifiable = false

  local ui = vim.api.nvim_list_uis()[1]
  local win_width, win_height = width + 2, height + 2
  local row = math.floor((ui.height - win_height) / 2)
  local col = math.floor((ui.width - win_width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " 迷路 (:q で終了) ",
    title_pos = "center",
  })

  vim.cmd([[
    syntax match MeiroWall /#/
    syntax match MeiroStart /S/
    syntax match MeiroGoal /G/
    highlight default link MeiroWall Comment
    highlight default link MeiroStart String
    highlight default link MeiroGoal WarningMsg
  ]])

  local last_pos = { sy, sx - 1 }
  vim.api.nvim_win_set_cursor(win, last_pos)

  local uv = vim.uv or vim.loop
  local start_time = uv.hrtime()

  local group = vim.api.nvim_create_augroup("MeiroGame_" .. buf, { clear = true })
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    buffer = buf,
    callback = function()
      if not vim.api.nvim_win_is_valid(win) then return end
      local cur_pos = vim.api.nvim_win_get_cursor(win)
      local row_idx, col_idx = cur_pos[1], cur_pos[2]

      local line = vim.api.nvim_buf_get_lines(buf, row_idx - 1, row_idx, false)[1]
      local char = line:sub(col_idx + 1, col_idx + 1)

      if char == "#" then
        vim.api.nvim_win_set_cursor(win, last_pos)
      elseif char == "G" then
        local time_taken = string.format("%.2f", (uv.hrtime() - start_time) / 1e9)
        vim.api.nvim_del_augroup_by_id(group)
        vim.notify(" clear! time: " .. time_taken .. "sec", vim.log.levels.INFO, { title = "Meiro" })
        
        vim.defer_fn(function()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end, 1500)
      else
        last_pos = cur_pos
      end
    end,
  })

  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end, { buffer = buf, silent = true })
  end
end

return M
