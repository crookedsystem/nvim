local nvim_011_commit = "7caec274fd19c12b55902a5b795100d21531391f"

local function reload_treesitter_modules()
  for name in pairs(package.loaded) do
    if name == "nvim-treesitter" or vim.startswith(name, "nvim-treesitter.") then
      package.loaded[name] = nil
    end
  end
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    commit = vim.fn.has("nvim-0.12") == 0 and nvim_011_commit or nil,
    build = function()
      -- Lazy can update the plugin while its previous Lua modules are still cached.
      -- Reload from the checked-out revision before synchronizing parser binaries.
      reload_treesitter_modules()
      require("nvim-treesitter").update(nil, { summary = true }):wait()
    end,
  },
}
