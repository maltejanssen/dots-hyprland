-- Use System Clipboard

vim.env.XDG_RUNTIME_DIR = "/run/user/1000"
vim.env.WAYLAND_DISPLAY = "wayland-1"

vim.o.clipboard = 'unnamedplus'
vim.o.mouse="v"
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
