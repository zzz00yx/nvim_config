
vim.cmd("source ~/.vimrc")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set("i", "<A-h>", "<Left>")
vim.keymap.set("i", "<A-j>", "<Down>")
vim.keymap.set("i", "<A-k>", "<Up>")
vim.keymap.set("i", "<A-l>", "<Right>")

vim.keymap.set("n", "<A-h>", "<C-w>h")
vim.keymap.set("n", "<A-j>", "<C-w>j")
vim.keymap.set("n", "<A-k>", "<C-w>k")
vim.keymap.set("n", "<A-l>", "<C-w>l")
vim.cmd([[autocmd VimLeave * set guicursor= | call chansend(v:stderr, "\x1b[ q")]]) -- restore cursor shape

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    { "nvim-treesitter/nvim-treesitter" },
    { "neovim/nvim-lspconfig" },
    { "folke/tokyonight.nvim", lazy = false },
    { "hrsh7th/nvim-cmp",
      -- load cmp on InsertEnter
      event = "InsertEnter",
      -- these dependencies will only be loaded when cmp loads
      -- dependencies are always lazy-loaded unless specified otherwise
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
      },
    },
    { "nvim-telescope/telescope.nvim", tag = "0.1.8",
      dependencies = { "nvim-lua/plenary.nvim" }
    },
    { "smoka7/hop.nvim" },
    -- add your plugins here
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = false },
})
require("tokyonight").setup({ style = "storm", transparent = true })
vim.cmd([[colorscheme tokyonight]])

require("telescope").setup {
  defaults = {
    mappings = {
      i = {
        ["<Esc>"] = require("telescope.actions").close,
        ["<C-u>"] = false,
      }
    }
  }
}
vim.keymap.set("n", "<C-p>", require("telescope.builtin").find_files)
vim.keymap.set("n", "<C-l>", require("telescope.builtin").live_grep)

local hop = require("hop")
local directions = require("hop.hint").HintDirection
hop.setup {}
vim.keymap.set("n", "s", function() require("hop").hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = false }) end)
vim.keymap.set("n", "S", function() require("hop").hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = false }) end)

local cmp = require("cmp")
cmp.setup {
  sources = cmp.config.sources {
    { name = "nvim_lsp" },
    { name = "buffer" },
    { name = "path" },
  },
  mapping = cmp.mapping.preset.insert {
    ["<C-Space>"] = cmp.mapping.complete(),
  },
}

local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr, noremap = true, silent = true }
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
  vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
  vim.keymap.set("n", "<A-d>", function() vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end, opts)
  vim.keymap.set("n", "<space>f", vim.lsp.buf.format, opts)
  vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, opts)
end
local capabilities = require("cmp_nvim_lsp").default_capabilities()
require("lspconfig").pyright.setup {
  capabilities = capabilities,
  on_attach = on_attach,
  filetypes = { "python" },
}
require("lspconfig").clangd.setup {
  capabilities = capabilities,
  on_attach = function(_, bufnr)
    on_attach(_, bufnr)
    local opts = { buffer = bufnr, noremap = true, silent = true }
    vim.keymap.set("n", "<A-o>", ":ClangdSwitchSourceHeader<CR>", opts)
  end,
  filetypes = { "c", "cpp" },
}

-- Better to put nvim-treesitter beneath the lsp configs, or it may block autostarting of lsp
require("nvim-treesitter.configs").setup {
  ensure_installed = { "c", "cpp", "lua", "vim", "vimdoc", "query" },
  highlight = { enable = true }
}

