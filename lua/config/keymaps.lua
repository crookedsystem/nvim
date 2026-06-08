-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Oil
vim.keymap.set("n", "oi", "<CMD>Oil<CR>", { desc = "Open Oil with file's current directory" })

-- Claude Code
vim.keymap.set("n", "<leader>cc", "<cmd>ClaudeCode<CR>", { desc = "Toggle Claude Code" })

-- Insert 모드에서 Ctrl+w로 단어 삭제 (터미널 키 시퀀스 문제 해결)
map("i", "<C-w>", "<C-w>", { noremap = true, desc = "Delete word backward" })
