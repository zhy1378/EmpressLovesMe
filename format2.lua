-- md_reader.lua
-- 这是一个 Pandoc Custom Reader
-- 它的作用是在 Pandoc 解析 Markdown 语法之前，先按照你的特殊规则清洗文本

function Reader(input, opts)
  -- 将输入转换为字符串
  local content = tostring(input)
  local lines = {}
  
  -- 按行分割字符串 (兼容 Windows/Linux 换行符)
  for line in content:gmatch("([^\r\n]*)[\r\n]?") do
    table.insert(lines, line)
  end
  -- 清理 gmatch 可能产生的末尾空行
  if lines[#lines] == "" then table.remove(lines) end

  local processed_parts = {}
  local gap_count = 0
  local has_started = false

  for _, line in ipairs(lines) do
    -- 规则 3: 只有空白字符的行视为空行
    local is_empty = line:match("^%s*$")

    if is_empty then
      -- 只有当正文开始后，才开始统计空行
      if has_started then
        gap_count = gap_count + 1
      end
    else
      -- 当前行有内容
      if not has_started then
        -- 这是文件的第一行内容
        table.insert(processed_parts, line)
        has_started = true
      else
        -- 根据之前积累的空行数量决定连接方式
        if gap_count == 0 then
          -- 情况：没有空行
          -- 规则 4: 保留原格式。如果上一行末尾原本就有空格，这里接一个普通换行即可
          -- 在 Markdown 中，紧接着的换行会被视为 SoftBreak（也就是在同一段落中）
          table.insert(processed_parts, "\n" .. line)
          
        elseif gap_count == 1 then
          -- 情况：1 个空行
          -- 规则 2a: 转换为标准格式的“句末两空格”断句 (Hard Break)
          -- 我们在这一行前面加上 "  \n"，相当于给上一行末尾加了两个空格
          table.insert(processed_parts, "  \n" .. line)
          
        else -- gap_count >= 2
          -- 情况：2 个及以上空行
          -- 规则 2b: 转换为标准格式的新段落
          -- 插入两个换行符，产生标准的段落分隔
          table.insert(processed_parts, "\n\n" .. line)
        end
      end
      
      -- 重置计数器
      gap_count = 0
    end
  end

  -- 将处理后的文本拼接起来
  local normalized_text = table.concat(processed_parts)

  -- 最后，调用 Pandoc 内置的 markdown reader 将处理好的文本解析为 AST
  -- 这样可以保留正文里的加粗、链接等其他 Markdown 格式
  return pandoc.read(normalized_text, "markdown", opts)
end