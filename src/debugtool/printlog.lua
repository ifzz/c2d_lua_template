--
-- Author: Chen
-- Date: 2017-09-12 17:06:47
-- Brief: 
--



local fileutils    = cc.FileUtils:getInstance()
local writablePath = device.writablePath
local old_print    = print

gDirRoot          = device.writablePath .. "pntlogs/" --// 日志根目录
gDir              = nil --// 当前目录
gCurLogFilePath   = nil --// 当前log路径
gCurFilesListPath = nil --// 当前保存log文件列表的路径
gCurOpFile        = nil --// 当前操作的文件
gCurDate          = ""

local function getLogDir()
    local date = os.date("%Y%m%d")
    gCurDate = date
    local dir = gDirRoot ..date .."/"
    if not fileutils:isDirectoryExist(dir) then
        fileutils:createDirectory(dir)

        local f = io.open(gDirRoot .."datelogs.txt", "a+")
        if f then
            f:write(date .."\n")
            f:close()
        end
    end

    return dir
end

local function checkArgType(arg)
    if type(arg) == "table" then
        local result = dump(arg, "table_table", 10, 10086)
        arg = table.concat(result, "\n")
    else
        arg = tostring(arg)
    end

    return arg
end

local function concat(...)
    local tb = {}
    for i=1, select('#', ...) do
        local arg = select(i, ...)  

        tb[#tb + 1] = checkArgType(arg)
    end
    return table.concat(tb, "\t")
end

local function writeToFile(szStr)
    if not gCurOpFile then
        local fileName = string.format("%s.log", os.date("%H-%M-%S"))
        gCurOpFile = io.open(getLogDir() ..fileName, "a+")
        gDir = getLogDir()
        gCurLogFilePath = gDir ..fileName

        local f = io.open(getLogDir() .."filesList.txt", "a+")
        if f then
            gCurFilesListPath = getLogDir() .."filesList.txt"
            f:write(fileName .."\n")
            f:close()
        end
    end
    
    local f = gCurOpFile
    if f then
        f:write(szStr)
        f:flush()
    else
        old_print("文件不存在")
    end
end

function print(...)
    if IS_WRITE_TO_FILE then
        local pntRet = os.date("[%H:%M:%S] ") .. concat(...) .. "\n"
        writeToFile(pntRet)
    end

    old_print(...)
end

local color      = import(".color")
local colorPrint = color.colorPrint
local colors = {color.BLUE, color.CYAN, color.GREEN, color.YELLOW, color.RED, color.PURPLE}

local methods    = {"trace", "debug", "info", "warn", "error", "fatal"}
local levels = {ALL = 0}

logger = {}

local funcs = {}
local nop = function() end

for i, name in ipairs(methods) do
    local level_name = string.upper(name)
    levels[level_name] = i
    local tag = '['..level_name..']'
    funcs[name] = function(...)
        colorPrint(colors[i], tag, ...)
    end
end

function logger.setLevel(lv)
    for i, funcname in ipairs(methods) do
        if i < lv then
            logger[funcname] = nop
        else
            logger[funcname] = funcs[funcname]
        end
    end
end