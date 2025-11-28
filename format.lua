-- md_fixer.lua

-- 判断一行是否被视为空行（只包含空格、制表符等）
local function is_empty_line(line)
    -- 匹配从头到尾只有空白字符的情况
    return line:match("^%s*$") ~= nil
end

-- 核心处理函数
local function format_markdown(content_lines)
    local output = {}
    local last_text = nil
    local gap_count = 0

    for _, line in ipairs(content_lines) do
        if is_empty_line(line) then
            -- 规则 3: 将只有不可见字符的行视为空行
            -- 如果已经有上一行文本，开始统计空行数量
            if last_text then
                gap_count = gap_count + 1
            end
        else
            -- 当前行是正文
            if last_text then
                -- 根据中间隔了多少空行，决定如何输出上一行
                if gap_count == 0 then
                    -- 情况：紧邻的两行文本
                    -- 规则 4: 原样保留，直接输出上一行
                    table.insert(output, last_text)
                
                elseif gap_count == 1 then
                    -- 规则 2a: 一个空行 -> 标准格式的“行末两空格”断句
                    -- 检查上一行是否已经有两个空格，如果没有则加上
                    if not last_text:match("  $") then
                        last_text = last_text .. "  "
                    end
                    table.insert(output, last_text)
                    
                else -- gap_count >= 2
                    -- 规则 2b: 两个及以上空行 -> 标准格式的新段落（中间一个空行）
                    table.insert(output, last_text)
                    table.insert(output, "") -- 插入标准的一个空行
                end
            end

            -- 更新状态，当前行成为待处理的“上一行”
            last_text = line
            gap_count = 0
        end
    end

    -- 处理文件末尾的最后一行
    if last_text then
        table.insert(output, last_text)
    end

    -- return output
    local merged = table.concat(output)
    return merged
end

function solve_evernote(f_in)
    print("solve_evernote")
    -- 读取文件
    local lines = {}

    for line in f_in:lines() do
        -- 移除行末的回车符（兼容 Windows/Linux）
        line = line:gsub("[\r\n]", "")
        table.insert(lines, line)
    end
    f_in:close()

    print("write_to_file")
    write_to_file("xxx.md")

    -- 执行转换
    return table.concat(format_markdown(lines))
end

function Reader(input, reader)
    print("Reader")
    local merged = solve_evernote(input)
    return pandoc.read(merged, "markdown")
end

function write_to_file(output_file)
    local f_out = io.open(output_file, "w")
    if not f_out then
        print("Error: Cannot open output file: " .. output_file)
        return
    end
    f_out:write(table.concat(formatted_lines, "\n"))
    f_out:close()
    print("Success! Saved to " .. output_file)
end

-- 文件读取与写入工具函数
local function main()
	if type(arg) ~= "table"  then
		return
	end

    -- 检查参数
    local input_file = arg[1]
    local output_file = arg[2]

    if not input_file then
        print("Usage: lua format.lua <input_file> [output_file]")
        return
    end

    local f_in = io.open(input_file, "r")
    if not f_in then
        print("Error: Cannot open input file: " .. input_file)
        return
    end

    local formatted_lines = solve_evernote(f_in)

    -- 输出结果
    if output_file then
        local f_out = io.open(output_file, "w")
        if not f_out then
            print("Error: Cannot open output file: " .. output_file)
            return
        end
        f_out:write(table.concat(formatted_lines, "\n"))
        f_out:close()
        print("Success! Saved to " .. output_file)
    else
        -- 如果没有指定输出文件，打印到控制台
        print(table.concat(formatted_lines, "\n"))
    end
end

main()