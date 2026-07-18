if vim.g.loaded_meiro then
  return
end
vim.g.loaded_meiro = true

-- :Meiro コマンドの登録 (引数で easy, normal, hard を指定可能)
vim.api.nvim_create_user_command("Meiro", function(opts)
  require("meiro").start(opts.args)
end, {
  nargs = "?",
  desc = "Neovimの操作に慣れるための迷路ゲーム",
})

-- 小文字の :meiro でも起動できるようにコマンドラインエイリアスを設定
vim.cmd([[
  cnoreabbrev <expr> meiro ((getcmdtype() == ':' && getcmdline() ==# 'meiro') ? 'Meiro' : 'meiro')
]])
