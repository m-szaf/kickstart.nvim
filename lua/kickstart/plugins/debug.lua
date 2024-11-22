-- debug.lu
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)
--

local js_languages = { 'typescript', 'javascript' }
return {

  {
    'rcarriga/nvim-dap-ui',
    dependencies = { 'nvim-neotest/nvim-nio' },
    -- stylua: ignore
    keys = function(_, keys)
    local dapui = require 'dapui'

    local dap = require 'dap'

    dap.adapters.node2 = {
      type = 'executable',
      command = 'node',
      args = { vim.fn.stdpath 'data' .. '/mason/packages/node-debug2-adapter/out/src/nodeDebug.js' },
    }

    -- Function to capture inspection ports and process context
    local function get_node_inspection_ports()
	    local handle = io.popen("lsof -i -P -n | grep node | grep LISTEN | awk '{print $2, $9}'")
	    local result = handle:read("*a")
	    handle:close()

	    local ports = {}
	    for line in result:gmatch("[^\r\n]+") do
		    local pid, address = line:match("(%d+)%s+[%[%]*]*([%d%.%:]+)")
		    local port = address:match(":(%d%d%d%d)$")
		    if pid and port then
			    local cmd_handle = io.popen("ps -p " .. pid .. " -o args=")
			    local cmd = cmd_handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
			    cmd_handle:close()
			    table.insert(ports, { port = port, cmd = cmd })
		    end
	    end
	    return ports
    end

    -- Function to show selection menu and run debugger
    local function select_and_debug_node_process()
	    local ports = get_node_inspection_ports()
	    if #ports == 0 then
		    print("No Node.js processes with active inspection ports found. (0000-9999)")
		    return
	    end

	    local port_contexts = {
            ["9290"] = "inbox-service",
            ["9291"] = "inbox-processing-service",
            ["9295"] = "inbox-outbound-push-service",
		    ["9231"] = "monolith",
            ["9277"] = "chat-service",
            ["9475"] = "emoji-service",
		    ["4444"] = "comment-service",
	    }

	    local known_ports = {}
	    local unknown_ports = {}
	    for i, entry in ipairs(ports) do
		    local context = port_contexts[entry.port] and (" (" .. port_contexts[entry.port] .. ")") or ""
		    local choice = string.format("Port: %s%s", entry.port, context)
		    if port_contexts[entry.port] then
			    table.insert(known_ports, choice)
		    else
			    table.insert(unknown_ports, choice)
		    end
	    end
	    local choices = {}
	    local choice_to_port = {}
	    for i, entry in ipairs(ports) do
		    local context = port_contexts[entry.port] and (" (" .. port_contexts[entry.port] .. ")") or ""
		    local choice = string.format("Port: %s%s", entry.port, context)
		    table.insert(choices, choice)
		    choice_to_port[choice] = entry.port
	    end

	    vim.ui.select(choices, { prompt = 'Select Node.js Process' }, function(choice, idx)
	        if choice then
		    local selected_port = choice_to_port[choice]
	            print("Selected port: " .. selected_port)
	            dap.run({
	                type = 'node2',
	                request = 'attach',
	                name = 'Attach to Node.js process',
	                port = tonumber(selected_port),
	                cwd = '${workspaceFolder}',
	                sourceMaps = true,
	                protocol = 'inspector',
	                restart = true,
	            })
	        else
	            print("No Node.js process selected.")
	        end
	    end)
    end


    ---@param config {args?:string[]|fun():string[]?}
    local function get_args(config)
	    local args = type(config.args) == 'function' and (config.args() or {}) or config.args or {}
	    config = vim.deepcopy(config)
	    ---@cast args string[]
	    config.args = function()
		    local new_args = vim.fn.input('Run with args: ', table.concat(args, ' ')) --[[@as string]]
		    return vim.split(vim.fn.expand(new_args) --[[@as string]], ' ')
	    end
	    return config
    end



    return {
      { '<leader>dp', function() select_and_debug_node_process() end, desc = 'Debug: Attach to Node.js process'},
      { '<leader>du', function() vim.cmd.Neotree 'close' dapui.toggle {} end, desc = 'Dap UI' },
      { '<leader>de', function() dapui.eval() end, desc = 'Eval', mode = {'n', 'v'} },
      { '<F5>', dap.continue, desc = 'Debug: Start/Continue' }, { '<F1>', dap.step_into, desc = 'Debug: Step Into' },
      { '<F2>', dap.step_over, desc = 'Debug: Step Over' },
      { '<F3>', dap.step_out, desc = 'Debug: Step Out' },
      { '<leader>b', dap.toggle_breakpoint, desc = 'Debug: Toggle Breakpoint' },
      {
        '<leader>B',
        function()
          dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'Debug: Set Breakpoint',
      },
      -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      { '<F7>', dapui.toggle, desc = 'Debug: See last session result.' },

      { '<leader>d', '', desc = '+debug', mode = { 'n', 'v' } },
      {
        '<leader>dB',
        function()
          dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'Breakpoint Condition',
      },
      {
	'<leader>dl',
	function()
		dap.set_breakpoint(nil, nil, vim.fn.input('Log Point Msg: '))
	end,
	desc = 'Log Point', 

      },
      {
        '<leader>db',
        function()
          dap.toggle_breakpoint()
        end,
        desc = 'Toggle Breakpoint',
      },
      {
        '<leader>dc',
        function()
	  vim.cmd.Neotree 'close'
          dap.continue()
        end,
        desc = 'Continue',
      },
      {
        '<leader>da',
        function()
          dap.continue { before = get_args }
        end,
        desc = 'Run with Args',
      },
      {
        '<leader>dC',
        function()
          dap.run_to_cursor()
        end,
        desc = 'Run to Cursor',
      },
      {
        '<leader>dg',
        function()
          dap.goto_()
        end,
        desc = 'Go to Line (No Execute)',
      },
      {
        '<leader>di',
        function()
          dap.step_into()
        end,
        desc = 'Step Into',
      },
      {
        '<leader>dj',
        function()
          dap.down()
        end,
        desc = 'Down',
      },
      {
        '<leader>dk',
        function()
          dap.up()
        end,
        desc = 'Up',
      },
      {
        '<leader>dL',
        function()
          dap.run_last()
        end,
        desc = 'Run Last',
      },
      {
        '<leader>dO',
        function()
          dap.step_out()
        end,
        desc = 'Step Out',
      },
      {
        '<leader>do',
        function()
          dap.step_over()
        end,
        desc = 'Step Over',
      },
      {
        '<leader>dP',
        function()
          dap.pause()
        end,
        desc = 'Pause',
      },
      {
        '<leader>dr',
        function()
          dap.repl.toggle()
        end,
        desc = 'Toggle REPL',
      },
      {
        '<leader>ds',
        function()
          dap.session()
        end,
        desc = 'Session',
      },
      {
        '<leader>dt',
        function()
          dap.terminate()
        end,
        desc = 'Terminate',
      },
      {
        '<leader>dw',
        function()
          require('dap.ui.widgets').hover()
        end,
        desc = 'Widgets',
      },

      unpack(keys),
    }
  end,
    opts = {},
    config = function(_, opts)
      local dap = require 'dap'
      local dapui = require 'dapui'

      dap.adapters.node2 = {
        type = 'executable',
        command = 'node',
        args = { vim.fn.stdpath 'data' .. '/mason/packages/node-debug2-adapter/out/src/nodeDebug.js' },
      }

      local dap_icons = {
        Stopped = { '󰁕 ', 'DiagnosticWarn', 'DapStoppedLine' },
        Breakpoint = { ' ', 'DapBreakpointSymbol' },
        BreakpointCondition = ' ',
        BreakpointRejected = { ' ', 'DiagnosticError' },
        LogPoint = '.>',
      }

      for name, sign in pairs(dap_icons) do
        sign = type(sign) == 'table' and sign or { sign }
        vim.fn.sign_define('Dap' .. name, { text = sign[1], texthl = sign[2] or 'DiagnosticInfo', linehl = sign[3], numhl = sign[3] })
      end

      dapui.setup {
        layouts = {
          {
            elements = {
              {
                id = 'scopes',
                size = 0.5,
              },
              {
                id = 'stacks',
                size = 0.3,
                open = '<CR>',
                expand = 'o',
              },
              {
                id = 'breakpoints',
                size = 0.1,
              },
              {
                id = 'watches',
                size = 0.1,
              },
            },
            position = 'left',
            size = 80,
          },
        },
      }

      vim.api.nvim_set_hl(0, 'DapBreakpointSymbol', { default = true, fg = '#f38ba8' })
      vim.api.nvim_set_hl(0, 'DapStoppedLine', { default = true, bg = '#3E3E3E', ctermbg = 0 })

      dap.listeners.after.event_initialized['dapui_config'] = function()
        vim.cmd.Neotree 'close'
        dapui.open {}
      end
      dap.listeners.before.event_terminated['dapui_config'] = function()
        dapui.close {}
      end
      dap.listeners.before.event_exited['dapui_config'] = function()
        dapui.close {}
      end

      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
    end,
  },
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    'theHamsta/nvim-dap-virtual-text',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- vim.api.nvim_set_hl(0, 'DapStoppedLine', { default = true, link = 'Visual' })
    -- vim.api.nvim_set_hl(0, 'DapStopped', { link = 'Visual', bg = '#F9E2AF', ctermbg = 0 })
    -- vim.api.nvim_set_hl(0, 'DapStopped', { default = true, link = 'Visual', bg = '#F9E2AF', ctermbg = 0 })
    -- vim.api.nvim_set_hl(0, 'DapStopped', { bg = '#F9E2AF', ctermbg = 0 })
    -- vim.api.nvim_set_hl(0, 'DapStopped', { text = '', texthl = 'DapStopped', linehl = 'DapStopped', numhl = 'DapStopped' })

    -- vim.api.nvim_set_hl(0, 'DapStopped', { ctermbg = 0, bg = '#F9E2AF' })

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

    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })
  end,
}
