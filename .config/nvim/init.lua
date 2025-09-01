-- Use System Clipboard

vim.env.XDG_RUNTIME_DIR = "/run/user/1000"
vim.env.WAYLAND_DISPLAY = "wayland-1"

vim.o.tabstop = 2
vim.o.smartindent = true
vim.o.shiftwidth = 2
vim.o.expandtab = true
-- delete without copying into register
vim.keymap.set({'n', 'v'}, 'x', '"_x')
vim.keymap.set({'n', 'v'}, 'd', '"_d')

vim.keymap.set('x', '<C-S-C>', '"+y') -- yank to clipboard register ("+)
vim.keymap.set('n', '<C-S-C>', '"+y') -- yank to clipboard register ("+)
vim.keymap.set('x', '<C-S-X>', '"+d') -- cut to clipboard register ("+)


vim.wo.number = true
vim.o.clipboard = 'unnamedplus'
vim.opt.scrolloff = 10
vim.opt.inccommand = "split"
vim.opt.incsearch = true

vim.g.clipboard = {
  name = "wl-clipboard",
  copy = {
    ["+"] = { "wl-copy", "--foreground", "--type", "text/plain" },
    ["*"] = { "wl-copy", "--foreground", "--type", "text/plain" },
  },
  paste = {
    ["+"] = { "wl-paste", "--no-newline" },
    ["*"] = { "wl-paste", "--no-newline" },
  },
  cache_enabled = 1
}
