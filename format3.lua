-- md_reader.lua
function Reader(input, opts)
  local content = tostring(input)
  local lines = {}
  
  -- 按行分割
  for line in content:gmatch("([^\r\n]*)[\r\n]?") do
    table.insert(lines, line)
  end
  if lines[#lines] == "" then table.remove(lines) end

  local processed_parts = {}
  local gap_count = 0
  local has_started = false

  for _, line in ipairs(lines) do
    local is_empty = line:match("^%s*$")

    if is_empty then
      if has_started then
        gap_count = gap_count + 1
      end
    else
      -- 检查当前行是否看起来像标题 (以 # 开头)
      -- 也可以根据需要扩展，比如引用 (>) 或无序列表 (-) 等
      local is_header = line:match("^%s*#+")

      if not has_started then
        table.insert(processed_parts, line)
        has_started = true
      else
        -- 核心逻辑修正：
        -- 如果当前行是标题，必须强制换段（\n\n），否则标题语法不生效。
        -- 此时忽略 "gap_count == 1 是硬换行" 的规则，因为标题不能接在硬换行后面。
        
        if is_header then
           table.insert(processed_parts, "\n\n" .. line)
        
        elseif gap_count == 0 then
           -- 规则 4: 紧邻行，保留原格式 (Soft Break)
           table.insert(processed_parts, "\n" .. line)
           
        elseif gap_count == 1 then
           -- 规则 2a: 1个空行 -> 硬换行 (Hard Break)
           table.insert(processed_parts, "  \n" .. line)
           
        else -- gap_count >= 2
           -- 规则 2b: 2+空行 -> 新段落
           table.insert(processed_parts, "\n\n\n" .. line)
        end
      end
      
      gap_count = 0
    end
  end

  local normalized_text = table.concat(processed_parts)
  return pandoc.read(normalized_text, "markdown", opts)
end