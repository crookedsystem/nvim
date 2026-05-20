-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- yank를 시스템 클립보드(+ 레지스터)와 자동 연동
-- 로컬: pbcopy/xclip 자동 감지, SSH: init.lua에서 OSC 52 provider 명시
vim.opt.clipboard = "unnamedplus"

-- UTF-8 인코딩 설정
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.fileencodings = "utf-8"

-- 절대 라인 번호 표시
vim.opt.number = true
vim.opt.relativenumber = false -- 상대 라인 번호 비활성화

-- Root 디렉토리를 현재 작업 디렉토리(cwd) 기준으로 설정
-- .git 폴더가 아닌 nvim을 실행한 폴더를 기준으로 함
vim.g.root_spec = { "cwd" }

-- 전역 autoformat 비활성화 (특정 파일타입만 autocmd로 활성화)
vim.g.autoformat = false

-- Soft wrap 설정
vim.opt.wrap = true -- 긴 줄을 화면에 맞게 wrap
vim.opt.linebreak = true -- 단어 중간이 아닌 공백에서 wrap
vim.opt.breakindent = true -- wrap된 줄도 들여쓰기 유지
vim.opt.showbreak = "↪ " -- wrap된 줄 앞에 표시할 문자

-- 터미널 키 프로토콜 문제 해결
-- Ctrl+w 등의 키가 잘못된 시퀀스로 입력되는 문제 수정
if vim.fn.has("nvim-0.10") == 1 then
  vim.opt.termpastefilter = "BS,HT,ESC,DEL"
end

-- 터미널에서 modifyOtherKeys 비활성화
vim.cmd([[
  let &t_TI = ""
  let &t_TE = ""
]])
