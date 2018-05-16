-- dep
local lfs = require 'lfs'

-- gin
local Gin = require 'gin.core.gin'


local function create_dirs(necessary_dirs)
    for _, dir in pairs(necessary_dirs) do
        lfs.mkdir(dir)
    end
end

local function create_nginx_conf(nginx_conf_file_path, nginx_conf_content)
    local fw = io.open(nginx_conf_file_path, "w")
    fw:write(nginx_conf_content)
    fw:close()
end

local function remove_nginx_conf(nginx_conf_file_path)
    os.remove(nginx_conf_file_path)
end

local function directive_string(env)
    local directive = ""
    if env ~= nil then directive = directive.." \"env GIN_ENV=" .. env .. ";\"" end
    if Gin.settings.daemon_off then directive = directive.." \"daemon off;\"" end
    if directive:len() > 0 then directive = " -g "..directive end
    return directive
end

local function nginx_command(env, nginx_conf_file_path, nginx_signal)
    local devnull_logs = ""
    if GIN_TRACE == false then devnull_logs = " 2>/dev/null" end

    local nginx_directives = directive_string(env)
    local pwd = io.popen( "pwd" ):read( '*l' )

    local cmd = "openresty " .. nginx_signal .. " " .. nginx_directives .. " -p "..pwd.."/ -c " .. nginx_conf_file_path .. devnull_logs

    if GIN_TRACE == true then
        print(cmd)
    end

    return os.execute(cmd)
end

local function start_nginx(env, nginx_conf_file_path)
    return nginx_command(env, nginx_conf_file_path, '')
end

local function stop_nginx(env, nginx_conf_file_path)
    return nginx_command(env, nginx_conf_file_path, '-s stop')
end


local BaseLauncher = {}
BaseLauncher.__index = BaseLauncher

function BaseLauncher.new(nginx_conf_content, nginx_conf_file_path)
    local necessary_dirs = Gin.app_dirs

    local instance = {
        nginx_conf_content = nginx_conf_content,
        nginx_conf_file_path = nginx_conf_file_path,
        necessary_dirs = necessary_dirs
    }
    setmetatable(instance, BaseLauncher)
    return instance
end

function BaseLauncher:start(env)
    create_dirs(self.necessary_dirs)
    create_nginx_conf(self.nginx_conf_file_path, self.nginx_conf_content)

    return start_nginx(env, self.nginx_conf_file_path)
end

function BaseLauncher:stop(env)
    result = stop_nginx(env, self.nginx_conf_file_path)
    remove_nginx_conf(self.nginx_conf_file_path)

    return result
end


return BaseLauncher
