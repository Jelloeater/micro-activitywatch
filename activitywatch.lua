VERSION = "1.0.0"

local micro = import("micro")
local config = import("micro/config")
local util = import("micro/util")
local shell = import("micro/shell")
local filepath = import("filepath")
local http = import("http")
local ioutil = import("io/ioutil")
local os2 = import("os")
local runtime = import("runtime")
local strings = import("strings")

local userAgent = "micro/" .. util.SemVersion:String() .. " micro-activitywatch/" .. VERSION
local defaultApiUrl = "http://localhost:5600/api/0"
local lastFile = ""
local lastHeartbeat = 0
local bucketCreated = false

function init()
    config.MakeCommand("activitywatch.apiurl", promptForApiUrl, config.NoComplete)
    config.MakeCommand("activitywatch.status", showStatus, config.NoComplete)
    config.MakeCommand("activitywatch.test", testConnection, config.NoComplete)
    config.AddRuntimeFile("activitywatch", config.RTHelp, "help/activitywatch.md")

    micro.InfoBar():Message("ActivityWatch initializing...")
    micro.Log("Initializing ActivityWatch v" .. VERSION)

    ensureBucketExists()
end

function postinit()
    micro.InfoBar():Message("ActivityWatch initialized")
    micro.Log("ActivityWatch initialized")
end

function getApiUrl()
    local url = getSetting("settings", "api_url")
    if url == nil or url == "" then
        return defaultApiUrl
    end
    return url
end

function getBucketId()
    local hostname = getHostname()
    return "aw-watcher-micro_" .. hostname
end

function getConfigFile()
    return filepath.Join(os2.UserHomeDir(), ".activitywatch.cfg")
end

function getSetting(section, key)
    local config_data, err = ioutil.ReadFile(getConfigFile())
    if err ~= nil then
        return ""
    end

    local lines = util.String(config_data)
    local currentSection = ""

    for line in lines:gmatch("[^\r\n]+") do
        line = string.rtrim(line)
        if string.starts(line, "[") and string.ends(line, "]") then
            currentSection = string.lower(string.sub(line, 2, string.len(line) -1))
        elseif currentSection == section then
            local parts = string.split(line, "=")
            local currentKey = string.trim(parts[1])
            if currentKey == key then
                return string.trim(parts[2])
            end
        end
    end

    return ""
end

function setSetting(section, key, value)
    local config_data, err = ioutil.ReadFile(getConfigFile())
    local errStr = err and tostring(err) or nil
    if errStr ~= nil and string.find(errStr, "no such file") == nil then
        micro.InfoBar():Message("failed reading ~/.activitywatch.cfg")
        micro.Log("failed reading ~/.activitywatch.cfg")
        micro.Log(errStr)
        return
    end

    local contents = {}
    local currentSection = ""
    local lines = ""
    local found = false

    if config_data ~= nil and config_data ~= "" then
        lines = util.String(config_data)
    end

    for line in lines:gmatch("[^\r\n]+") do
        line = string.rtrim(line)
        if string.starts(line, "[") and string.ends(line, "]") then
            if currentSection == section and not found then
                table.insert(contents, key .. " = " .. value)
                found = true
            end

            currentSection = string.lower(string.sub(line, 2, string.len(line) -1))
            table.insert(contents, string.rtrim(line))
        elseif currentSection == section then
            local parts = string.split(line, "=")
            local currentKey = string.trim(parts[1])
            if currentKey == key then
                if not found then
                    table.insert(contents, key .. " = " .. value)
                    found = true
                end
            else
                table.insert(contents, string.rtrim(line))
            end
        else
            table.insert(contents, string.rtrim(line))
        end
    end

    if not found then
        if currentSection ~= section then
            table.insert(contents, "[" .. section .. "]")
        end

        table.insert(contents, key .. " = " .. value)
    end

    _, err = ioutil.WriteFile(getConfigFile(), table.concat(contents, "\n"), 0600)
    if err ~= nil then
        micro.InfoBar():Message("failed saving ~/.activitywatch.cfg")
        micro.Log("failed saving ~/.activitywatch.cfg")
        micro.Log(err)
        return
    end
end

function getHostname()
    local hostname = getSetting("internal", "hostname")
    if hostname ~= nil and hostname ~= "" then
        return hostname
    end

    local out, err = shell.ExecCommand("hostname")
    if err == nil and out ~= nil then
        hostname = string.rtrim(out)
        setSetting("internal", "hostname", hostname)
        return hostname
    end

    return "unknown"
end

function ensureBucketExists()
    if bucketCreated then
        return true
    end

    local bucketId = getBucketId()
    local apiUrl = getApiUrl()
    local createUrl = apiUrl .. "/buckets/" .. bucketId

    local bucketData = [[{"client": "aw-watcher-micro", "hostname": "]] .. getHostname() .. [[", "type": "app.editor.activity", "data": {}}]]

    local res, err = http.Post(createUrl, "application/json", strings.NewReader(bucketData))

    if err ~= nil then
        micro.Log("ActivityWatch: Failed to create bucket - " .. err)
        return false
    end

    if res.StatusCode == 200 or res.StatusCode == 201 or res.StatusCode == 304 then
        bucketCreated = true
        micro.Log("ActivityWatch: Bucket created/verified: " .. bucketId)
        return true
    end

    micro.Log("ActivityWatch: Failed to create bucket, status: " .. res.StatusCode)
    return false
end

function testConnection(bp)
    local apiUrl = getApiUrl()
    local res, err = http.Get(apiUrl .. "/buckets")

    if err ~= nil then
        micro.InfoBar():Message("ActivityWatch: Connection failed - " .. err)
        micro.Log("ActivityWatch: Connection failed - " .. err)
        return true
    end

    if res.StatusCode == 200 then
        micro.InfoBar():Message("ActivityWatch: Connected to " .. apiUrl)
        micro.Log("ActivityWatch: Connected to " .. apiUrl)
    else
        micro.InfoBar():Message("ActivityWatch: Connection failed, status: " .. res.StatusCode)
        micro.Log("ActivityWatch: Connection failed, status: " .. res.StatusCode)
    end

    return true
end

function showStatus(bp)
    local apiUrl = getApiUrl()
    local bucketId = getBucketId()

    local res, err = http.Get(apiUrl .. "/buckets/" .. bucketId)

    if err ~= nil then
        micro.InfoBar():Message("ActivityWatch: Unavailable - " .. err)
        return true
    end

    if res.StatusCode == 200 then
        micro.InfoBar():Message("ActivityWatch: Connected (" .. bucketId .. ")")
    elseif res.StatusCode == 404 then
        micro.InfoBar():Message("ActivityWatch: Bucket not found, will create on next event")
    else
        micro.InfoBar():Message("ActivityWatch: Status " .. res.StatusCode)
    end

    return true
end

function promptForApiUrl(bp)
    micro.InfoBar():Prompt("API URL: ", getApiUrl(), "api_url", function(input)
    end, function(input, canceled)
        if not canceled then
            if input ~= nil and input ~= "" then
                setSetting("settings", "api_url", input)
                micro.InfoBar():Message("ActivityWatch API URL set to: " .. input)
            end
        end
    end)
end

function getLanguageFromPath(filePath)
    local ext = string.lower(filepath.Ext(filePath))
    local langMap = {
        [".lua"] = "lua",
        [".py"] = "python",
        [".js"] = "javascript",
        [".ts"] = "typescript",
        [".go"] = "go",
        [".rs"] = "rust",
        [".c"] = "c",
        [".cpp"] = "cpp",
        [".h"] = "c",
        [".hpp"] = "cpp",
        [".java"] = "java",
        [".cs"] = "csharp",
        [".rb"] = "ruby",
        [".php"] = "php",
        [".swift"] = "swift",
        [".kt"] = "kotlin",
        [".scala"] = "scala",
        [".sh"] = "bash",
        [".bash"] = "bash",
        [".zsh"] = "bash",
        [".fish"] = "fish",
        [".ps1"] = "powershell",
        [".md"] = "markdown",
        [".json"] = "json",
        [".yaml"] = "yaml",
        [".yml"] = "yaml",
        [".xml"] = "xml",
        [".html"] = "html",
        [".css"] = "css",
        [".scss"] = "scss",
        [".sass"] = "sass",
        [".less"] = "less",
        [".sql"] = "sql",
        [".r"] = "r",
        [".scala"] = "scala",
        [".ex"] = "elixir",
        [".exs"] = "elixir",
        [".erl"] = "erlang",
        [".hs"] = "haskell",
        [".ml"] = "ocaml",
        [".clj"] = "clojure",
        [".cljs"] = "clojure",
        [".fs"] = "fsharp",
        [".fsx"] = "fsharp",
        [".vim"] = "vim",
        [".vimrc"] = "vim",
        [".toml"] = "toml",
        [".ini"] = "ini",
        [".cfg"] = "ini",
        [".conf"] = "ini",
        [".txt"] = "text",
    }
    return langMap[ext] or "text"
end

function getProjectFromPath(filePath)
    local dir = filepath.Dir(filePath)
    local home = os2.UserHomeDir()

    local function hasGitDir(path)
        if path == "" or path == "/" or path == home then
            return nil
        end
        local gitPath = filepath.Join(path, ".git")
        local _, err = os2.Stat(gitPath)
        if err == nil then
            return filepath.Base(path)
        end
        return hasGitDir(filepath.Dir(path))
    end

    return hasGitDir(dir) or "unknown"
end

function sendHeartbeat(filePath, isWrite)
    local apiUrl = getApiUrl()
    local bucketId = getBucketId()
    local heartbeatUrl = apiUrl .. "/buckets/" .. bucketId .. "/heartbeat?pulsetime=120"

    local file = string.gsub(filePath, '\\', '\\\\')
    file = string.gsub(file, '"', '\\"')
    local lang = getLanguageFromPath(filePath)
    local proj = getProjectFromPath(filePath)
    proj = string.gsub(proj, '\\', '\\\\')
    proj = string.gsub(proj, '"', '\\"')

    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    local jsonBody = string.format(
        '{"timestamp": "%s", "data": {"file": "%s", "language": "%s", "project": "%s", "isWrite": %s}}',
        timestamp, file, lang, proj, isWrite and "true" or "false"
    )

    local res, err = http.Post(heartbeatUrl, "application/json", strings.NewReader(jsonBody))

    if err ~= nil then
        micro.Log("ActivityWatch: Failed to send heartbeat - " .. err)
        return false
    end

    if res.StatusCode ~= 200 and res.StatusCode ~= 201 and res.StatusCode ~= 202 then
        micro.Log("ActivityWatch: Heartbeat failed with status " .. res.StatusCode)
        return false
    end

    return true
end

function enoughTimePassed(time)
    return lastHeartbeat + 120000 < time
end

function onEvent(filePath, isWrite)
    if not bucketCreated then
        ensureBucketExists()
    end
    local time = os.time() * 1000
    if isWrite or enoughTimePassed(time) or lastFile ~= filePath then
        sendHeartbeat(filePath, isWrite)
        lastFile = filePath
        lastHeartbeat = time
    end
end

function onSave(bp)
    onEvent(bp.buf.AbsPath, true)
    return true
end

function onSaveAll(bp)
    onEvent(bp.buf.AbsPath, true)
    return true
end

function onSaveAs(bp)
    onEvent(bp.buf.AbsPath, true)
    return true
end

function onOpenFile(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onPaste(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onSelectAll(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onDeleteLine(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onCursorUp(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onCursorDown(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onCursorPageUp(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onCursorPageDown(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onCursorLeft(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onCursorRight(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onCursorStart(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onCursorEnd(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onSelectToStart(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onSelectToEnd(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onSelectUp(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onSelectDown(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onSelectLeft(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onSelectRight(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onSelectToStartOfText(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onSelectToStartOfTextToggle(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onWordRight(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onWordLeft(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onSelectWordRight(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onSelectWordLeft(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onMoveLinesUp(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onMoveLinesDown(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onScrollUp(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function onScrollDown(bp)
    onEvent(bp.buf.AbsPath, false)
    return true
end

function string.starts(str, start)
    return str:sub(1,string.len(start)) == start
end

function string.ends(str, ending)
    return ending == "" or str:sub(-string.len(ending)) == ending
end

function string.trim(str)
    return (str:gsub("^%s*(.-)%s*$", "%1"))
end

function string.rtrim(str)
    local n = #str
    while n > 0 and str:find("^%s", n) do n = n - 1 end
    return str:sub(1, n)
end

function string.split(str, delimiter)
    t = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(t, match);
    end
    return t
end
