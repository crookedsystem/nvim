#!/usr/bin/env bash
set -euo pipefail

set +e
output="$(
  nvim --headless "+lua \
    local should_open = require('config.oil_startup').should_open \
    local function check(desc, expected, argc, bufname, uis, line_count, first_line) \
      local actual = should_open(argc, bufname, uis, line_count, first_line) \
      assert(actual == expected, ('%s: expected %s, got %s'):format(desc, tostring(expected), tostring(actual))) \
    end \
    local tty_ui = { { stdout_tty = true, stdin_tty = true } } \
    local piped_ui = { { stdout_tty = true, stdin_tty = false } } \
    check('no args, empty buf, interactive tty', true, 0, '', tty_ui, 1, '') \
    check('file args present', false, 1, '', tty_ui, 1, '') \
    check('buffer already named', false, 0, '/tmp/foo.txt', tty_ui, 1, '') \
    check('no ui attached', false, 0, '', {}, 1, '') \
    check('piped stdin with content', false, 0, '', piped_ui, 2, 'hello') \
    check('piped stdin, single non-empty line', false, 0, '', piped_ui, 1, 'hello') \
    print('RESULT:oil-startup-predicate-verified') \
    vim.cmd('qa!')" 2>&1
)"
nvim_status=$?
set -e

if [[ "$nvim_status" -ne 0 ]]; then
  printf '%s\n' "$output" >&2
  exit "$nvim_status"
fi

grep -q "RESULT:oil-startup-predicate-verified" <<<"$output"
printf 'oil startup predicate verified\n'

# 실제 TTY에서 경로뿐 아니라 디렉터리 항목이 렌더링되는지도 확인한다.
python3 - <<'PY'
import os
import pty
import select
import signal
import tempfile
import time
from pathlib import Path

for args in ([], ["visible-marker.txt"]):
    with tempfile.TemporaryDirectory(prefix="oil-startup-") as temp:
        directory = Path(temp).resolve()
        result = directory / "result"
        (directory / "visible-marker.txt").write_text("file content\n")
        lua = """
vim.api.nvim_create_autocmd('VimEnter', { callback = function()
  vim.defer_fn(function()
    vim.fn.writefile({vim.api.nvim_buf_get_name(0), vim.bo.filetype,
      vim.fn.getcwd(), unpack(vim.api.nvim_buf_get_lines(0, 0, -1, false))}, %s)
    vim.cmd('qa!')
  end, 1000)
end })
""" % repr(str(result))
        pid, fd = pty.fork()
        if pid == 0:
            os.chdir(directory)
            os.execvp("nvim", ["nvim", "--cmd", "lua " + lua, *args])
        try:
            deadline = time.monotonic() + 20
            while time.monotonic() < deadline:
                ready, _, _ = select.select([fd], [], [], 0.1)
                if ready:
                    try:
                        os.read(fd, 65536)
                    except OSError:
                        break
                if os.waitpid(pid, os.WNOHANG)[0]:
                    pid = None
                    break
            else:
                raise RuntimeError("Neovim startup timed out")
        finally:
            os.close(fd)
            if pid is not None:
                try:
                    os.kill(pid, signal.SIGKILL)
                    os.waitpid(pid, 0)
                except ProcessLookupError:
                    pass
        lines = result.read_text().splitlines()
        assert lines[2] == str(directory), lines
        if not args:
            assert lines[0] == f"oil://{directory}/", lines
            assert lines[1] == "oil", lines
            assert any("visible-marker.txt" in line for line in lines[3:]), lines
        else:
            assert lines[0] == str(directory / args[0]), lines
            assert lines[3:] == ["file content"], lines
        print(f"verified interactive startup: {args or 'current directory listing'}")
PY
