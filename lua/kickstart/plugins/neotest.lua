return {
  { 'nvim-neotest/neotest-plenary' },
  { 'nvim-neotest/nvim-nio' },
  { 'nvim-neotest/neotest-jest' },
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/neotest-jest',
      'nvim-neotest/neotest-plenary',
      'nvim-neotest/nvim-nio',
    },
    config = function()
      require('neotest').setup {
        adapters = {
          require 'neotest-jest' {
            jestCommand = './node_modules/.bin/jest',
            env = { CI = true },
            cwd = function(path)
              return vim.fn.getcwd()
            end,
          },
        },
        getJestConfig = function(file)
          local root_dir = vim.fn.getcwd()
          local apps_or_libs_pattern = '/(apps|libs)/'

          if string.find(file, apps_or_libs_pattern) then
            local match = string.match(file, '(.-/[^/]+/)src')
            if match then
              return match .. 'jest.config.ts'
            end
          end

          return root_dir .. '/jest.config.ts'
        end,
        diagnostic = {
          enabled = false,
        },
        floating = {
          border = 'rounded',
          max_height = 0.6,
          max_width = 0.6,
        },
        highlights = {
          adapter_name = 'NeotestAdapterName',
          border = 'NeotestBorder',
          dir = 'NeotestDir',
          expand_marker = 'NeotestExpandMarker',
          failed = 'NeotestFailed',
          file = 'NeotestFile',
          focused = 'NeotestFocused',
          indent = 'NeotestIndent',
          namespace = 'NeotestNamespace',
          passed = 'NeotestPassed',
          running = 'NeotestRunning',
          skipped = 'NeotestSkipped',
          test = 'NeotestTest',
        },
        icons = {
          child_indent = '│',
          child_prefix = '├',
          collapsed = '─',
          expanded = '╮',
          failed = '✖',
          final_child_indent = ' ',
          final_child_prefix = '╰',
          non_collapsible = '─',
          passed = '✔',
          running = '',
          skipped = 'ﰸ',
          unknown = '?',
        },
        output = {
          enabled = true,
          open_on_run = true,
        },
        run = {
          enabled = true,
        },
        status = {
          enabled = true,
        },
        strategies = {
          integrated = {
            height = 40,
            width = 120,
          },
        },
        summary = {
          enabled = true,
          expand_errors = true,
          follow = true,
          mappings = {
            attach = 'a',
            expand = { '<CR>', '<2-LeftMouse>' },
            expand_all = 'e',
            jumpto = 'i',
            output = 'o',
            run = 'r',
            short = 'O',
            stop = 'u',
          },
        },
      }
    end,
  },
}
