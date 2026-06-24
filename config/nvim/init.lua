-- Minimal Neovim 0.12 config. One plugin, zero build steps.

vim.g.mapleader = ' '

-- Sensible defaults
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.undofile = true
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.confirm = true
vim.o.termguicolors = true  -- 24-bit colour; required for the theme to look right

-- Use the system clipboard for all yanks/puts.
vim.api.nvim_create_autocmd('UIEnter', {
  callback = function() vim.o.clipboard = 'unnamedplus' end,
})

-- Over SSH there is no pbcopy/xsel/wl-copy on the remote box, so route the
-- system clipboard through OSC 52 escape sequences instead. These are
-- terminal-agnostic and pass through tmux when 'set-clipboard on' is set, so a
-- yank in remote Neovim lands in your *local* terminal's clipboard. Paste is
-- served from the unnamed register (the last yank) to avoid a slow/blocked
-- terminal round-trip; paste text from elsewhere with your terminal's own
-- paste (it arrives as a normal keystroke stream). Local (non-SSH) sessions
-- keep the native provider (pbcopy on macOS), which is faster and supports
-- paste-back.
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  local osc52 = require('vim.ui.clipboard.osc52')
  local function paste() return vim.split(vim.fn.getreg('"'), '\n') end
  vim.g.clipboard = {
    name = 'OSC 52',
    copy  = { ['+'] = osc52.copy('+'),  ['*'] = osc52.copy('*') },
    paste = { ['+'] = paste,            ['*'] = paste },
  }
end
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function() vim.hl.on_yank() end,
})

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Plugins (Neovim 0.12 native manager). Pure Lua, zero build steps.
vim.pack.add({
  { src = 'https://github.com/echasnovski/mini.nvim' },
  { src = 'https://github.com/nvim-lualine/lualine.nvim' },
  { src = 'https://github.com/AlexvZyl/nordic.nvim' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'master' },
  { src = 'https://github.com/HiPhish/rainbow-delimiters.nvim' },
  -- LSP + tooling
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/mason-org/mason.nvim' },
  { src = 'https://github.com/mason-org/mason-lspconfig.nvim' },
  { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim' },
  -- Completion, formatting, git, editing aids
  { src = 'https://github.com/saghen/blink.cmp' },
  { src = 'https://github.com/stevearc/conform.nvim' },
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  { src = 'https://github.com/folke/which-key.nvim' },
  { src = 'https://github.com/NMAC427/guess-indent.nvim' },
  { src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim' },
})

require('mini.pick').setup()        -- fuzzy finder
require('mini.completion').setup()  -- insert-mode completion
require('mini.pairs').setup()       -- auto-close brackets/quotes
require('mini.icons').setup()       -- filetype/glyph icons (used by render-markdown)

-- Colorscheme.
require('nordic').setup({
  bold_keywords = false,
  italic_comments = true,
  reduced_blue = true,        -- false for a bluer, more classic Nord look
  transparent = { bg = true, float = false },  -- use the terminal background
})
vim.cmd.colorscheme('nordic')

-- Bottom bar (statusline). Uses nordic's lualine theme.
-- Powerline separators below need a Nerd Font in your terminal; if you see
-- broken glyphs, set both *_separators to '' for a plain look.
require('lualine').setup({
  options = {
    theme = 'nordic',
    section_separators = { left = '', right = '' },
    component_separators = { left = '', right = '' },
    globalstatus = true,  -- one bar across all splits
  },
})

-- Treesitter: real syntax highlighting (distinct colors per token type).
-- Pinned to the `master` branch (classic API): parsers compile from grammar
-- sources with a C compiler (cc/gcc/clang) on first launch. This avoids the
-- `main` branch's hard dependency on the external tree-sitter CLI, whose only
-- prebuilt binaries need a very recent glibc. A C compiler is a far more
-- portable contract (build-essential on Linux, Xcode CLT on macOS).
-- Add languages to ensure_installed as needed; install is idempotent.
require('nvim-treesitter.configs').setup({
  ensure_installed = {
    'python', 'lua', 'typescript', 'javascript', 'tsx', 'rust',
    'markdown', 'markdown_inline', 'yaml', 'json', 'toml',
    'bash', 'html', 'css', 'vim', 'vimdoc', 'diff', 'gitcommit',
  },
  auto_install = false,           -- only compile the languages listed above
  highlight = { enable = true },  -- treesitter-based highlighting
  indent = { enable = true },     -- treesitter-based '=' indentation
})

-- In-buffer Markdown rendering: headings, code blocks, lists, tables, and
-- callouts drawn via treesitter (markdown + markdown_inline parsers, already
-- installed above). Raw source shows on the cursor line and in insert mode, so
-- editing is unaffected. Toggle with :RenderMarkdown toggle.
require('render-markdown').setup({})

-- Rainbow brackets: color-match (){}[] by nesting depth. Treesitter-driven.
require('rainbow-delimiters.setup').setup({})

-- Indentation auto-detection per file (tabs vs spaces, width).
require('guess-indent').setup({})

-- Git gutter signs + hunk navigation/staging. Core of the diff-review loop.
require('gitsigns').setup({
  on_attach = function(buf)
    local gs = require('gitsigns')
    local function map(l, r, desc) vim.keymap.set('n', l, r, { buffer = buf, desc = desc }) end
    map(']c', function() gs.nav_hunk('next') end, 'Next git hunk')
    map('[c', function() gs.nav_hunk('prev') end, 'Prev git hunk')
    map('<leader>hp', gs.preview_hunk,            'Preview hunk')
    map('<leader>hs', gs.stage_hunk,              'Stage hunk')
    map('<leader>hr', gs.reset_hunk,              'Reset hunk')
    map('<leader>hb', gs.blame_line,              'Blame line')
    map('<leader>hd', gs.diffthis,                'Diff against index')
  end,
})

-- Keybinding discovery popup. Shows available mappings as you type a prefix.
require('which-key').setup({})

-- Completion engine. Pure-Lua fuzzy matcher (no Rust toolchain / prebuilt binary).
require('blink.cmp').setup({
  fuzzy = { implementation = 'lua' },
  keymap = { preset = 'default' },  -- <C-y> accept, <C-space> open, <C-n>/<C-p> cycle
  signature = { enabled = true },
})

-- LSP. nvim-lspconfig ships the server configs under lsp/; we enable them via
-- the native vim.lsp API (Neovim 0.11+). Mason installs the server binaries.
require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {
    'pyright', 'ruff',        -- python: types + lint/format
    'ts_ls',                  -- typescript / javascript
    'rust_analyzer',          -- rust
    'lua_ls',                 -- lua
    'jsonls', 'yamlls', 'taplo',  -- json / yaml / toml
    'marksman',               -- markdown
    'bashls',                 -- bash
  },
  -- automatic_enable (default true) runs vim.lsp.enable() for installed servers.
})

-- Formatters (installed via Mason, run via conform).
require('mason-tool-installer').setup({
  ensure_installed = { 'stylua', 'prettier' },
})

-- Broadcast blink's completion capabilities to every server.
vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })

-- Diagnostics presentation.
vim.diagnostic.config({
  virtual_text = true,
  severity_sort = true,
  float = { border = 'rounded' },
})

-- Buffer-local LSP keymaps, set only when a server actually attaches.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local function map(l, r, desc) vim.keymap.set('n', l, r, { buffer = ev.buf, desc = desc }) end
    map('grd', vim.lsp.buf.definition,     'Go to definition')
    map('grr', vim.lsp.buf.references,     'References')
    map('gri', vim.lsp.buf.implementation, 'Implementation')
    map('grn', vim.lsp.buf.rename,         'Rename symbol')
    map('gra', vim.lsp.buf.code_action,    'Code action')
    map('K',   vim.lsp.buf.hover,          'Hover docs')
    map('<leader>e', vim.diagnostic.open_float, 'Line diagnostics')
    map('[d', function() vim.diagnostic.jump({ count = -1 }) end, 'Prev diagnostic')
    map(']d', function() vim.diagnostic.jump({ count = 1 }) end,  'Next diagnostic')
  end,
})

-- Formatting on save (and <leader>f). Falls back to LSP formatting if no formatter.
require('conform').setup({
  formatters_by_ft = {
    python = { 'ruff_format' },
    javascript = { 'prettier' }, typescript = { 'prettier' },
    javascriptreact = { 'prettier' }, typescriptreact = { 'prettier' },
    json = { 'prettier' }, jsonc = { 'prettier' },
    yaml = { 'prettier' }, markdown = { 'prettier' },
    css = { 'prettier' }, html = { 'prettier' },
    lua = { 'stylua' },
    rust = { 'rustfmt' },  -- requires a rust toolchain (rustup); no-ops if absent
    toml = { 'taplo' },
  },
  format_on_save = { timeout_ms = 1000, lsp_format = 'fallback' },
})
vim.keymap.set('n', '<leader>f', function() require('conform').format({ async = true, lsp_format = 'fallback' }) end, { desc = 'Format buffer' })

vim.keymap.set('n', '<leader>ff', '<cmd>Pick files<CR>',     { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', '<cmd>Pick grep_live<CR>', { desc = 'Grep' })
vim.keymap.set('n', '<leader>fb', '<cmd>Pick buffers<CR>',   { desc = 'Buffers' })
