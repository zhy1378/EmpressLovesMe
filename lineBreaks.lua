-- linebreaks_strict.lua
-- 规则:
--  1 个“空行”（只含空白字符） -> 插入一个换行标签 <br>
--  2 个及以上“空行”                 -> 段落分隔（保留为两个换行）
-- 同时：保留 fenced code blocks 里的内容不做处理。

local function split_lines(s)
  -- 统一换行符，然后按行切分（保留可能的末尾空行）
  s = s:gsub("\r\n", "\n")
  local t = {}
  for line in s:gmatch("([^\n]*)\n?") do
    table.insert(t, line)
  end
  return t
end

local function solve_evernote(input)
  local lines = split_lines(input)
  local out_lines = {}
  local blank_count = 0

  local in_fence = false
  local fence_char = nil
  local fence_len = 0

  for i, line in ipairs(lines) do
    -- detect start/end of fenced code block (``` or ~~~)
    local s, e, fence = line:find("^([`~]+)")
    if s and not in_fence then
      -- start fence
      in_fence = true
      fence_char = fence:sub(1,1)
      fence_len = #fence
      -- flush any pending blanks before starting a fence
      insert_trailing(blank_count, table, out_lines, line)
    elseif in_fence and line:find("^" .. string.rep(fence_char, fence_len)) then
      -- possible closing fence (match same char and at least same length)
      in_fence = false
      fence_char = nil
      fence_len = 0
      table.insert(out_lines, line .. "\n")
    elseif in_fence then
      -- inside fence: do not process blanks — keep as-is
      table.insert(out_lines, line .. "\n")
    else
      -- not in fence: treat lines that are only whitespace as blank
      if line:match("^%s*$") then
        blank_count = blank_count + 1
      else
        -- non-blank line: first flush blanks according to rules
        insert_trailing(blank_count, table, out_lines, line)

        blank_count = 0
        table.insert(out_lines, line .. "\n")
      end
    end
  end

  -- trailing blanks handling (if file ends with blanks)
  insert_trailing(blank_count, table, out_lines, line)

  local merged = table.concat(out_lines)
  return merged
end

function insert_trailing(blank_count, table, out_lines, line)
	if blank_count == 1 then
		table.insert(out_lines, "  ")
	elseif blank_count >= 2 then
		table.insert(out_lines, "\n")
	end

	if line ~= nil then
		blank_count = 0
		table.insert(out_lines, line .. "\n")
	end
end

function Reader(input, reader)
  local merged = solve_evernote(input)
  return pandoc.read(merged, "markdown")
end

-----------------------------------------------------------
-- MAIN
-----------------------------------------------------------

if type(arg) == "table" then
	-- 1. Check command-line argument
	if #arg < 1 then
		io.stderr:write("Usage: lua clean_md.lua <input-file>\n")
		os.exit(1)
	end

	local infile = arg[1]

	-- 2. Read file
	local f = io.open(infile, "r")
	if not f then
		io.stderr:write("Error: cannot open input file: " .. infile .. "\n")
		os.exit(1)
	end

	local text = f:read("*a")
	f:close()

	-- 3. Process text
	local cleaned = solve_evernote(text)

	-- 4. Generate output filename
	local outfile = infile:gsub("%.md$", "") .. ".cleaned.md"

	-- If extension wasn't .md
	if outfile == infile then
		outfile = infile .. ".cleaned.md"
	end

	-- 5. Write to output
	local out = io.open(outfile, "w")
	if not out then
		io.stderr:write("Error: cannot write to output file: " .. outfile .. "\n")
		os.exit(1)
	end

	out:write(cleaned)
	out:close()

	print("Cleaned file written to: " .. outfile)
end