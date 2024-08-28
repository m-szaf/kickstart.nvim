-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

local js_languages = { 'typescript', 'javascript' }

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    dap.adapters.node2 = {
      type = 'executable',
      command = 'node',
      args = { vim.fn.stdpath 'data' .. '/mason/packages/node-debug2-adapter/out/src/nodeDebug.js' },
    }

    for _, language in ipairs(js_languages) do
      dap.configurations[language] = {
        {
          type = 'node2',
          request = 'attach',
          name = 'Attach MONOLITH',
          -- processId = function()
          --   return require('dap.utils').pick_process({ filter = 'node' }).pid
          -- end,
          port = 9231,
          cwd = '${workspaceFolder}',
          sourceMaps = true,
          protocol = 'inspector',
          restart = true,
        },
        {
          type = 'node2',
          request = 'attach',
          name = 'Attach IS',
          -- processId = function()
          --   return require('dap.utils').pick_process({ filter = 'node' }).pid
          -- end,
          port = 9290,
          cwd = '${workspaceFolder}',
          sourceMaps = true,
          protocol = 'inspector',
          restart = true,
        },
        {
          type = 'node2',
          request = 'attach',
          name = 'Attach IPS',
          -- processId = function()
          --   return require('dap.utils').pick_process({ filter = 'node' }).pid
          -- end,
          port = 9291,
          cwd = '${workspaceFolder}',
          sourceMaps = true,
          protocol = 'inspector',
          restart = true,
        },
        {
          type = 'node2',
          request = 'attach',
          name = 'Attach IOPS',
          -- processId = function()
          --   return require('dap.utils').pick_process({ filter = 'node' }).pid
          -- end,
          port = 9295,
          cwd = '${workspaceFolder}',
          sourceMaps = true,
          protocol = 'inspector',
          restart = true,
        },
      }
    end

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        -- 'delve',
        'node2',
      },
    }

    -- Basic debugging keymaps, feel free to change to your liking!
    vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<F11>', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<F10>', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<S-F11>', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>B', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'Debug: Set Breakpoint' })

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })
    -- vim.keymap.set('n', '<C-k>', dapui.eval, { desc = 'Debug: Evalute variable under cursor' })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    local sign = vim.fn.sign_define

    vim.api.nvim_set_hl(0, 'DapStopped', { ctermbg = 0, bg = '#eee8d5' })

    sign('DapBreakpoint', { text = '●', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    sign('DapBreakpointCondition', { text = '●', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
    sign('DapLogPoint', { text = '◆', texthl = 'DapLogPoint', linehl = '', numhl = '' })
    sign('DapStopped', { text = '➔', texthl = '', linehl = 'DapStopped', numhl = '' })

    -- Install golang specific config
    --   require('dap-go').setup {
    --     delve = {
    --       -- On Windows delve must be run attached or it crashes.
    --       -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
    --       detached = vim.fn.has 'win32' == 0,
    --     },
    --   }
  end,
}
