local Config = require('php-easy-nvim.any.config')

local M = {}

function M.docBlock()
    vim.fn.setreg('p', '/**\n * \n */\n')
    vim.cmd([[
        normal "pPj
        startinsert!
    ]])
end

function M.attribute()
    vim.fn.setreg('p', '#[]')
    vim.cmd([[
        normal! O
        normal! "pP^ll
        startinsert
    ]])
end

local function initObject(type)
    -- prepare name and path
    local file = vim.fn.expand('%:t:r')
    local path = vim.fn.fnamemodify(vim.fn.expand('%:p:h'), ':~:.')

    -- find psr4 in composer.json
    local psr4 = {}
    local composerPath = vim.fn.getcwd() .. '/composer.json'
    if vim.fn.filereadable(composerPath) == 1 then
        local content = table.concat(vim.fn.readfile(composerPath), "\n")
        local ok, composer = pcall(vim.json.decode, content)
        if ok and composer then
            -- get psr-4 from autoload and autoload-dev
            local autoload_paths = {}
            if composer.autoload and composer.autoload['psr-4'] then
                table.insert(autoload_paths, composer.autoload['psr-4'])
            end
            if composer['autoload-dev'] and composer['autoload-dev']['psr-4'] then
                table.insert(autoload_paths, composer['autoload-dev']['psr-4'])
            end

            for _, maps in ipairs(autoload_paths) do
                for ns, dir in pairs(maps) do
                    -- Ensure dir is treated as a literal string in gsub
                    -- and psr4 keys are the namespaces
                    psr4[ns] = dir
                end
            end
        end
    end

    -- fix by psr4
    if vim.tbl_count(psr4) > 0 then
        for value, key in pairs(psr4) do
            path = string.gsub(path, key, value)
        end
    end

    -- fix slashes
    path = path:gsub('/', '\\')

    if vim.fn.search("^namespace ", "w") == 0 then
        -- empty file
        vim.cmd([[
            normal! i<?php
            normal! o
            normal! odeclare(strict_types=1);
            normal! o
            normal! onamespace ]] .. path .. [[;
            normal! o
            normal! o]] .. type .. [[ ]] .. file
        );
        vim.cmd([[
            normal! o{
            normal! o}
        ]])
        vim.fn.search(type .. ' ' .. file, 'e')
    else
        -- fix exists data
        vim.cmd('normal! Cnamespace ' .. path .. ';')
        vim.fn.search(Config.regex.object, 'we')
        vim.cmd('normal! lcw' .. file)
    end
end

function M.initInterface()
    initObject('interface')
end

function M.initClass()
    initObject('final class')
end

function M.initAbstractClass()
    initObject('abstract class')
end

function M.initTrait()
    initObject('trait')
end

function M.initEnum()
    initObject('enum')
end

function M.implements()
    vim.fn.search(Config.regex.object, 'we')
    vim.cmd([[
        normal! A implements 
        startinsert!
    ]])
end

function M.extends()
    vim.fn.search(Config.regex.object, 'we')
    vim.cmd([[
        normal! A extends 
        startinsert!
    ]])
end

return M
