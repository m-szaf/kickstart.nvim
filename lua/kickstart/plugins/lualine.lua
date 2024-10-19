return {
  'nvim-lualine/lualine.nvim',
  deps = { 'arkav/lualine-lsp-progress' },
  event = 'VeryLazy',
  init = function()
    vim.g.lualine_laststatus = vim.o.laststatus
    if vim.fn.argc(-1) > 0 then
      vim.o.statusline = ' '
    else
      vim.o.laststatus = 0
    end
  end,
  opts = function()
    local lualine_require = require 'lualine_require'
    lualine_require.require = require

    vim.o.laststatus = vim.g.lualine_laststatus
    local opts = {
      options = {
        theme = 'catppuccin',
        globalstatus = true,
        disabled_filetypes = {
          statusline = { 'dashboard', 'alpha', 'ministarter' },
          'dapui_watches',
          'dapui_breakpoints',
          'dapui_scopes',
          'dapui_console',
          'dapui_stacks',
          'dap-repl',
          'neo-tree',
        },
        ignore_focus = {
          'dapui_watches',
          'dapui_breakpoints',
          'dapui_scopes',
          'dapui_console',
          'dapui_stacks',
          'dap-repl',
          'neo-tree',
        },
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch' },

        lualine_c = {
          { 'filename', file_status = true, path = 1 },
          {
            'diagnostics',
          },
          { 'filetype', icon_only = true, separator = '', padding = { left = 1, right = 0 } },
        },
        lualine_x = {
          {
            'lsp_progress',
            display_components = { 'lsp_client_name', { 'percentage', 'message' } },
            separators = {
              message = { pre = '(', post = ')' },
              percentage = { pre = '', post = '%% ' },
              lsp_client_name = { pre = '[', post = ']' },
            },
            message = { commenced = 'Indexing...', completed = 'Done!' },
          },
          -- stylua: ignore
          {
            function() return require("noice").api.status.command.get() end,
            cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
          },
          -- stylua: ignore
          {
            function() return require("noice").api.status.mode.get() end,
            cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
          },
          -- stylua: ignore
          {
            function() return "  " .. require("dap").status() end,
            cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
          },
          -- stylua: ignore
          {
            require("lazy.status").updates,
            cond = require("lazy.status").has_updates,
          },
          {
            'diff',
            source = function()
              local gitsigns = require 'gitsigns'

              if gitsigns then
                return {
                  added = gitsigns.added,
                  modified = gitsigns.changed,
                  removed = gitsigns.removed,
                }
              end
            end,
          },
        },
        lualine_y = {
          -- 'lsp_progress',
          -- { 'progress', separator = ' ', padding = { left = 1, right = 0 } },
          {
            'harpoon2',
            icon = '󰀱',
            indicators = { 'h', 'j', 'k', 'l' },
            active_indicators = { 'H', 'J', 'K', 'L' },
            color_active = { fg = '#00ff00' },
            _separator = ' ',
            no_harpoon = 'Harpoon not loaded',
          },
        },
        lualine_z = {
          { 'location', padding = { left = 0, right = 1 } },
          -- function()
          --   return ' ' .. os.date '%R'
          -- end,
        },
      },
      extensions = { 'neo-tree', 'lazy' },
    }

    -- do not add trouble symbols if aerial is enabled
    -- And allow it to be overriden for some buffer types (see autocmds)
    -- local trouble = require 'trouble'
    -- local symbols = trouble.statusline {
    --   mode = 'symbols',
    --   groups = {},
    --   title = false,
    --   filter = { range = true },
    --   format = '{kind_icon}{symbol.name:Normal}',
    --   hl_group = 'lualine_c_normal',
    -- }
    -- table.insert(opts.sections.lualine_c, {
    --   symbols and symbols.get,
    --   cond = function()
    --     return vim.b.trouble_lualine ~= false and symbols.has()
    --   end,
    -- })

    return opts
  end,
}
