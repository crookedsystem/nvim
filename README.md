# 💤 LazyVim 설정

[LazyVim](https://github.com/LazyVim/LazyVim)을 위한 개인 설정 파일입니다.
자세한 설치 방법은 [공식 문서](https://lazyvim.github.io/installation)를 참고하세요.

## 🚀 새 머신 설치

```bash
git clone <your-repo> ~/.config/nvim
cd ~/.config/nvim
make install   # macOS / Ubuntu 자동 감지 (deps + mason)
nvim           # 첫 실행 시 Lazy → Mason이 나머지 LSP 자동 설치
```

| 타깃 | 하는 일 |
|------|---------|
| `make install` | `deps` + `mason` |
| `make deps` | 시스템 의존성만 설치 (아래 표) |
| `make mason` | Mason 레지스트리 갱신 + kotlin-lsp 재설치 |

`make deps`가 설치하는 시스템 의존성:

| 도구 | 용도 | macOS | Ubuntu |
|------|------|-------|--------|
| ripgrep / fd | 검색 | brew | apt |
| Node.js | vtsls, prismals 등 Mason LSP | brew | nodesource |
| Java 21+ (JDK) | jdtls, kotlin_lsp | temurin@21 cask | openjdk-21-jdk |
| uv | pylsp 실행 (`uv run --with ...`) | brew | astral.sh |

> **pylsp 참고**: Mason이 설치하지 않음 (`mason = false`). `uv run`이 실행 시점에 자동으로 패키지를 가져옴.

### Kotlin LSP

- `kotlin_lsp` — JetBrains **공식** 버전, 현재 사용 중
- `kotlin_language_server` — 커뮤니티 버전 (`fwcd/kotlin-language-server`), 현재 비활성화

Kotlin LSP는 프로젝트의 `org.gradle.java.home`, `.java-version`, `.sdkmanrc`, `.tool-versions`를 확인하고, 없으면 설치된 Java 21/17을 자동 선택합니다.

> **빌드 만료 주의**: `kotlin_lsp`의 실체인 JetBrains `intellij-server`는 빌드마다 만료일이 있습니다.
> 만료되면 서버가 기동 직후 `This build of intellij-server has expired`를 남기고 **exit code 7**로 죽어
> `Client kotlin_lsp quit with exit code 7`이 뜹니다. `ensure_installed`는 "설치돼 있으면 통과"라 갱신되지
> 않으므로, 이때는 `make mason`(= `:MasonUpdate` + `:MasonInstall kotlin-lsp`)으로 새 빌드를 받으세요.

---

## 🏗️ 커맨드

- **LazyExtras** : 새로운 플러그인 찾을 때 유용
  - x : 설치
  - / : 검색

## 🎯 핵심 단축키

| 기능              | 모드 | 키맵           | 설명                                           |
| ----------------- | ---- | -------------- | ---------------------------------------------- |
| **Oil 파일 관리** | n    | `oi`           | Oil 파일 탐색기                                |
| **편집**          | v    | `gc`           | 그렙한 라인 주석                               |
|                   | v    | `*` + :%s//foo | 선택한 라인 모두 찾아서 일괄 변경              |
| **탭 이동**       | n    | `<S-hl>`       | 왼쪽/오른쪽 탭으로 이동                        |
| **윈도우 이동**   | n    | `<C-hjkl>`     | 윈도우 이동                                    |
| **네비게이션**    | n    | `gd`           | 정의로 이동                                    |
|                   | n    | `<C-o>`        | 이전 포커스로 이동                             |
|                   | n    | `gr`           | 참조로 이동(cmd + b / cmd + 마우스클릭에 해당) |
|                   | n    | `gD`           | 선언으로 이동                                  |
| **LSP**           | n    | `<leader>ca`   | Code Action (Auto Import, Quick Fix 등)       |
|                   | n    | `<leader>cr`   | 심볼 이름 변경 (Rename)                        |
|                   | n    | `<leader>cf`   | 코드 포맷팅                                    |
|                   | n    | `K`            | Hover 문서 보기                                |
| **터미널**        | n    | `:term`        | 현재 창에서 터미널                             |
|                   | n    | `!{cmd}`       | 외부 명령어 실행                               |
|                   | t    | `<C-\><C-n>`   | 터미널 → 일반 모드                             |
| **검색**          | n    | `<leader>/`    | 저장소 문자열 검색 (특수문자 literal 검색)     |
|                   | pick | `<A-r>`        | literal/regex 검색 모드 전환                    |
| **검색/치환**     | n    | `<leader>sr`   | grug-far 열기 (여러 줄 붙여넣기 검색/치환)     |
|                   | v    | `<leader>sr`   | 선택 영역 안에서만 검색/치환 (GrugFarWithin)   |
| **디버깅**        | n    | `<leader>dp`   | 브레이크포인트 토글                            |
|                   | n    | `<leader>dc`   | 디버깅 시작/계속                               |
|                   | n    | `<leader>do`   | 스텝 오버                                      |
|                   | n    | `<leader>di`   | 스텝 인                                        |
|                   | n    | `<leader>dO`   | 스텝 아웃                                      |
|                   | n    | `<leader>dq`   | 디버깅 종료                                    |
|                   | n    | `<leader>du`   | 디버그 UI 토글                                 |
| **Fugitive**      | n    | `<leader>gD`   | Git status 버퍼 (변경 파일 목록·스테이징·커밋) |
|                   | n    | `<leader>gd`   | 현재 파일을 index/HEAD와 좌우 비교             |
|                   | n    | `<leader>gH`   | 현재 파일 커밋 이력 (quickfix)                 |
|                   | git  | `s` / `u`      | 커서 위치 파일·hunk 스테이지/언스테이지        |
|                   | git  | `=`            | 커서 위치 파일의 inline diff 펼치기/접기       |
|                   | git  | `cc`           | 커밋                                           |
|                   | diff | `]c` / `[c`    | 다음/이전 변경 hunk 이동                       |
|                   | diff | `do` / `dp`    | hunk 가져오기 / 반대편으로 보내기              |
|                   | git  | `g?`           | 현재 Fugitive 화면의 키맵 도움말               |
| **Claude Code**   | n    | `<leader>ac`   | Claude Code 토글                               |
|                   | n    | `<leader>af`   | Claude Code 포커스                             |
|                   | n    | `<leader>ar`   | Claude Code 재개 (Resume)                      |
|                   | n    | `<leader>aC`   | Claude Code 계속 (Continue)                    |
|                   | n    | `<leader>am`   | Claude 모델 선택                               |
|                   | n    | `<leader>ab`   | 현재 버퍼 추가                                 |
|                   | v    | `<leader>as`   | 선택 영역 Claude에 전송                        |
|                   | n    | `<leader>aa`   | Diff 승인                                      |
|                   | n    | `<leader>ad`   | Diff 거부                                      |
| **AI Copilot**    | n,v  | `<leader>aa`   | CopilotChat 토글                               |
|                   | n,v  | `<leader>ax`   | CopilotChat 대화 초기화                        |
|                   | n,v  | `<leader>aq`   | 빠른 질문 (Quick Chat)                         |
|                   | n,v  | `<leader>ap`   | 프롬프트 액션 선택                             |
|                   | chat | `<C-s>`        | 프롬프트 전송                                  |

## 🔍 Fugitive 사용 가이드

**사용 플러그인**: [tpope/vim-fugitive](https://github.com/tpope/vim-fugitive)

- **의존성**: 없음
- **요구사항**: Git (버전 제약 없음)
- **설정 파일**: `lua/plugins/fugitive.lua`

Neovim 안에서 Git을 그대로 실행하는 플러그인입니다. `:Git <아무 서브커맨드>`가 전부 동작하고, 인자 없는 `:Git`은 `git status`를 그대로 옮긴 **summary 버퍼**를 엽니다. 스테이징·diff·커밋·리베이스·스태시를 모두 그 한 버퍼 안에서 키 한두 개로 처리합니다. 2026-08-23에 `sindrets/diffview.nvim`을 대체하며 도입했습니다.

### diffview에서 무엇이 달라지는가

Fugitive는 diff 전용 뷰어가 아니라 Git 클라이언트입니다. diffview의 "왼쪽 파일 패널 + 한 탭에서 파일 순회" 화면은 없어지고, status 버퍼가 그 자리를 대신합니다. 화면 감각이 바뀌는 지점을 먼저 정리합니다.

| 예전 (diffview) | 지금 (fugitive) |
|---|---|
| `<leader>gD` → 파일 패널 + 우측 diff | `<leader>gD` → status 버퍼, `=`로 파일마다 inline diff 펼침 |
| 파일 패널에서 `<Tab>`으로 파일 순회 | status 버퍼에서 `]/` · `[/`로 파일 순회 |
| 파일 패널에서 `-` 스테이지 | status 버퍼에서 `s` · `u` · `-` (hunk 단위도 가능) |
| `<leader>co` · `<leader>ct` 충돌 해결 | `d2o` · `d3o` |
| `<leader>gH` → 전용 히스토리 패널 | `<leader>gH` → quickfix 리스트 |
| `:DiffviewOpen main...feature` | `:Git difftool -y main...feature` |
| `cc` 커밋 | `cc` 커밋 (동일) |

**얻은 것**: 스테이징 이후 커밋·리베이스·스태시·revert까지 같은 버퍼에서 끝나고, hunk 단위 스테이징(`s`를 diff 라인 위에서)이 별도 플러그인 없이 됩니다. 유지보수도 활발합니다.
**잃은 것**: 변경 파일 전체를 좌우 2-way 화면으로 훑는 전용 UI가 없습니다. 그 감각이 필요하면 아래 `:Git difftool -y`를 쓰세요.

### 시나리오별 사용법

**1) 저장소 전체 리뷰 — status 버퍼**

```
<leader>gD
```

`:Git`과 동일합니다. `git status`의 섹션 구조(Unstaged / Staged / Untracked / Unpushed / Unpulled)를 그대로 버퍼로 보여줍니다. 여기서 커서를 파일 위에 두고:

- `=` — 그 파일의 diff를 **파일 목록 사이에 펼쳐서** 보여줍니다. 다시 누르면 접힙니다.
- `dv` — 그 파일을 좌우 2-way diff 창으로 엽니다.
- `s` / `u` — 스테이지 / 언스테이지. diff를 펼친 상태에서 hunk 라인 위에 두고 누르면 **hunk 단위**로 처리됩니다. 비주얼 모드로 여러 줄을 잡으면 그 범위만 스테이징됩니다.
- `cc` — 커밋 메시지 편집기를 엽니다. 저장하고 닫으면 커밋됩니다.

버퍼를 닫을 때는 `gq`입니다. 이미 열려 있는 상태에서 `<leader>gD`를 다시 누르면 새로 열지 않고 그 창으로 포커스만 이동합니다.

**2) 현재 파일만 빠르게 검토**

```
<leader>gd
```

`:Gvdiffsplit`과 동일합니다. 지금 버퍼를 index(스테이징 영역) 버전과 좌우로 비교합니다. 작업본은 항상 오른쪽에 놓입니다. 여기서는 Vim 기본 diff 키가 그대로 쓰입니다.

- `]c` / `[c` — 다음/이전 hunk로 이동
- `do` — 반대편 hunk를 이쪽으로 가져오기 (diff obtain)
- `dp` — 이쪽 hunk를 반대편으로 보내기 (diff put). index 쪽으로 보내면 그게 곧 부분 스테이징입니다.
- `:Gdiffsplit HEAD` — index가 아니라 HEAD와 비교하고 싶을 때
- `:Gdiffsplit HEAD~3` — 특정 커밋 시점과 비교

diff 창을 정리할 때는 `dq`(모든 diff 창을 닫고 `diffoff!`)를 씁니다.

**3) 특정 커밋/브랜치 범위 비교**

diffview의 파일 순회에 가장 가까운 형태입니다. 변경된 파일을 **각각 새 탭**으로 열고 파일마다 diff 창을 띄웁니다.

| 명령 | 설명 |
|------|------|
| `:Git difftool -y` | 변경 파일을 전부 탭으로 열고 각각 diff |
| `:Git difftool -y HEAD~2` | HEAD~2와 작업본 비교 |
| `:Git difftool -y main...feature` | 두 브랜치 변경분 비교 (merge-base 기준) |
| `:Git difftool -y HEAD -- lua/plugins` | 특정 경로로 범위 한정 |
| `:Git difftool` | `-y` 없이 쓰면 탭 대신 **quickfix**에 hunk 단위로 적재 |

탭 사이 이동은 `gt` / `gT`입니다. `-y` 없는 형태는 hunk마다 quickfix 항목이 하나씩 생기므로, 변경 지점을 `]q` / `[q`로 하나씩 훑고 싶을 때 유용합니다.

**4) 파일 히스토리(커밋 로그) 탐색**

```
<leader>gH
```

`:0Gclog`와 동일합니다. 현재 파일을 건드린 커밋들을 quickfix 리스트에 적재하고, 각 항목은 그 커밋의 첫 diff hunk를 가리킵니다.

- `:Gclog` — 저장소 전체 커밋 이력
- `:{range}Gclog` — 선택한 줄 범위에 영향을 준 커밋만 (`git log -L`)
- `:Gllog` — quickfix 대신 location list 사용

> quickfix는 항목이 많아지면 눈에 띄게 느려집니다. 저장소 전체 이력을 넓게 훑을 때는 `:Git log --oneline`으로 로그를 버퍼에 띄우고 커밋 해시 위에서 `<CR>`을 눌러 들어가는 편이 빠릅니다.

**5) blame으로 이 줄이 왜 이렇게 됐는지 추적**

```
:Git blame
```

현재 파일의 blame을 스크롤이 연동된 좌측 세로 분할로 엽니다.

| 키 | 설명 |
|------|------|
| `<CR>` | blame을 닫고 그 줄을 만든 커밋의 patch로 이동 |
| `o` / `O` | 커밋을 가로 분할 / 새 탭으로 열기 |
| `p` | preview 창으로 열기 |
| `-` | 커서 위치 커밋 시점으로 다시 blame (reblame) |
| `A` / `C` / `D` | author / commit / date 컬럼 너비에 맞춰 리사이즈 |
| `gq` | blame 닫고 작업본으로 복귀 |

한 줄의 유래를 계속 파고들 때는 `-`로 reblame을 반복하는 대신, `<CR>`로 커밋에 들어가서 해당 `-` 라인 위에서 `<CR>`을 두 번 더 누르는 쪽이 정확합니다. 그래야 그 줄이 왜 바뀌었는지 맥락까지 같이 보입니다.

비주얼 모드로 범위를 잡고 `:'<,'>Git blame`을 하면 그 범위만 blame합니다.

### Status 버퍼 키맵

`<leader>gD`로 연 버퍼에서 쓰는 키입니다. 전체 목록은 그 버퍼에서 `g?`를 누르면 나옵니다.

**스테이징**

| 키 | 설명 |
|------|------|
| `s` | 커서 위치 파일·hunk 스테이지 (`git add`) |
| `u` | 커서 위치 파일·hunk 언스테이지 (`git reset`) |
| `-` | 스테이지/언스테이지 토글 |
| `U` | 전부 언스테이지 |
| `X` | 커서 위치 변경 버리기 (`checkout`/`clean`). 되돌리는 명령이 echo되므로 `:messages`로 확인 가능 |
| `=` | 커서 위치 파일의 inline diff 토글 |
| `>` / `<` | inline diff 펼치기 / 접기 |
| `I` | `git add --patch` / `reset --patch` 대화형 실행 |
| `gI` | `.git/info/exclude`에 커서 위치 파일 추가 (count를 주면 `.gitignore`) |

**이동**

| 키 | 설명 |
|------|------|
| `]c` / `[c` | 다음/이전 hunk (inline diff 자동으로 펼침) |
| `]/` `]m` / `[/` `[m` | 다음/이전 **파일** (inline diff 자동으로 접음) |
| `)` / `(` | 다음/이전 파일·hunk·리비전 |
| `]]` / `[[` | 다음/이전 섹션 |
| `gu` / `gs` | Unstaged / Staged 섹션으로 점프 |
| `gp` / `gP` | Unpushed / Unpulled 섹션으로 점프 |
| `<CR>` | 커서 위치 파일 열기 |
| `o` / `gO` / `O` / `p` | 가로 분할 / 세로 분할 / 새 탭 / preview로 열기 |
| `dd` / `dv` / `dh` | 커서 위치 파일을 분할 diff / 좌우 diff / 상하 diff로 열기 |
| `dq` | 모든 diff 창 닫기 |
| `gq` | status 버퍼 닫기 |

**커밋**

| 키 | 설명 |
|------|------|
| `cc` | 커밋 |
| `ca` | 직전 커밋 amend + 메시지 편집 |
| `ce` | 직전 커밋 amend (메시지 그대로) |
| `cw` | 직전 커밋 메시지만 수정 (reword) |
| `cf` / `cs` | 커서 위치 커밋에 대한 `fixup!` / `squash!` 커밋 생성 |
| `cF` / `cS` | 위와 동일하되 곧바로 autosquash 리베이스 실행 |
| `crc` | 커서 위치 커밋 revert |
| `c<Space>` | 명령행에 `:Git commit ` 채워넣기 |

**브랜치 · 스태시**

| 키 | 설명 |
|------|------|
| `coo` | 커서 위치 커밋 체크아웃 |
| `co<Space>` / `cb<Space>` | 명령행에 `:Git checkout ` / `:Git branch ` 채워넣기 |
| `czz` | 스태시 push (count 1이면 `--include-untracked`, 2면 `--all`) |
| `czw` | 작업본만 스태시 (`--keep-index`) |
| `czP` / `czp` | 최상단 스태시 pop (뒤쪽은 index 보존) |
| `czA` / `cza` | 최상단 스태시 apply (뒤쪽은 index 보존) |

**리베이스**

| 키 | 설명 |
|------|------|
| `ri` | 커서 위치 커밋의 부모를 기준으로 대화형 리베이스 |
| `ru` / `rp` | `@{upstream}` / `@{push}` 기준 대화형 리베이스 |
| `rf` | todo 편집 없이 autosquash 리베이스 |
| `rr` / `rs` / `ra` | 진행 중인 리베이스 계속 / 현재 커밋 건너뛰기 / 중단 |
| `rw` / `rm` / `rd` | 커서 위치 커밋을 reword / edit / drop으로 지정해 리베이스 |

### Merge/Rebase 충돌 해결 (3-way)

충돌이 나면 `<leader>gD`의 status 버퍼에 `Unmerged` 섹션이 생깁니다. 해결 흐름은 다음과 같습니다.

먼저 충돌 파일을 열고 3-way diff를 띄웁니다.

```
:Gdiffsplit!
```

인자 없는 `!` 형태는 모든 직계 조상과 diff하므로, 충돌 중에는 **ours / theirs 두 조상 + 작업본** 3창이 뜹니다. 포커스는 작업본에 남습니다.

| 키 | 설명 |
|------|------|
| `d2o` | 커서 위치 hunk를 **ours**(현재 브랜치) 쪽으로 확정 |
| `d3o` | 커서 위치 hunk를 **theirs**(들어오는 브랜치) 쪽으로 확정 |
| `]c` / `[c` | 다음/이전 충돌 hunk로 이동 |
| `dq` | diff 창 정리 |

파일 전체를 한쪽으로 통째로 밀어버릴 때는 status 버퍼에서 `2X`(= `checkout --ours`) 또는 `3X`(= `checkout --theirs`)를 씁니다.

충돌 파일이 여러 개면 quickfix로 몰아서 처리할 수 있습니다.

```
:Git mergetool
```

`:Git difftool`과 같은 방식으로 충돌 지점을 quickfix에 적재합니다. `-y`를 붙이면 파일마다 탭 + 3-way diff로 엽니다.

해결이 끝난 파일은 `:Gwrite`(= `git add`)로 스테이지하고, 전부 끝나면 status 버퍼에서 `cc`로 커밋합니다.

### 임의 git 명령 실행

Fugitive의 본질은 `:Git`이 곧 `git`이라는 점입니다. 서브커맨드에 따라 결과를 다루는 방식만 달라집니다.

| 명령 | 설명 |
|------|------|
| `:Git push` | 그대로 실행하고 출력을 보여줌 (pty를 쓰므로 진행률 표시도 나옴) |
| `:Git! push` | 백그라운드로 실행하고 출력을 preview 창에 스트리밍 |
| `:Git -p log -p` | 출력을 임시 파일로 받아 분할 창에 띄움 (`diff`/`log`는 자동으로 이 모드) |
| `:{range}Git! -p log --oneline` | 명령 출력을 현재 버퍼의 `{range}` 뒤에 삽입 |

커밋 메시지처럼 명령이 편집기를 요구하면 분할 창으로 열리고, 그 창을 닫으면 명령이 이어서 진행됩니다.

### 명령어 요약

| 명령 | 설명 |
|------|------|
| `:Git` (`:G`) | status summary 버퍼 열기 |
| `:Git {args}` | 임의 git 명령 실행 |
| `:Gvdiffsplit [object]` | 좌우 2-way diff |
| `:Ghdiffsplit [object]` | 상하 2-way diff |
| `:Gdiffsplit! [object]` | 모든 직계 조상과 diff (충돌 시 3-way) |
| `:Git difftool [-y] [args]` | 변경분을 quickfix로 (`-y`면 탭 + diff) |
| `:Git mergetool [-y] [args]` | 충돌 지점을 quickfix로 (`-y`면 탭 + 3-way) |
| `:Gclog [args]` / `:0Gclog` | 커밋 이력을 quickfix로 (`:0Gclog`는 현재 파일 전체) |
| `:Git blame [flags]` | 스크롤 연동 blame 열기 |
| `:Gedit [object]` | 특정 리비전의 파일 열기 (`:Gedit HEAD~2:%`) |
| `:Gread [object]` | 현재 버퍼를 특정 리비전 내용으로 교체 (디스크에는 안 씀) |
| `:Gwrite` | 현재 파일을 저장하고 스테이지 (`git add`) |
| `:Ggrep [args]` | `git grep` 결과를 quickfix로 |
| `:GMove` / `:GRename` / `:GDelete` | `git mv` / `git rm` 후 버퍼까지 정리 |
| `:Gcd` / `:Glcd` | 저장소 루트 기준으로 `:cd` / `:lcd` |

`:Gedit`·`:Gread` 등이 받는 `object`는 `HEAD`, `HEAD~2:%`, `:0:%`(index 버전), `main:README.md` 같은 Git 리비전 표기를 그대로 씁니다. 명령행에서 `<C-R><C-G>`를 누르면 현재 버퍼의 object 경로가 삽입됩니다.

## 🧭 Config

### Claude Code

**사용 플러그인**: [coder/claudecode.nvim](https://github.com/coder/claudecode.nvim)

- **의존성**: folke/snacks.nvim
- **요구사항**: Claude Code CLI 설치 필요

**설정 확인**:

```vim
# Claude Code 연결 상태 확인
:ClaudeCodeStatus

# 디버그 로깅 활성화 (필요시)
# lua/plugins/claude-code.lua 파일에 추가:
opts = {
  log_level = "debug",
}
```

**사용 팁**:

1. `<leader>ab`로 현재 버퍼를 Claude에 추가
2. Visual 모드에서 코드 선택 후 `<leader>as`로 전송
3. Oil이나 NvimTree에서 `<leader>as`로 파일 추가
4. Diff 제안이 나타나면 `<leader>aa`로 승인 또는 `<leader>ad`로 거부

### grug-far.nvim (여러 줄/특수문자 검색 및 치환)

**사용 플러그인**: [MagicDuck/grug-far.nvim](https://github.com/MagicDuck/grug-far.nvim)

Snacks/fzf 계열 피커의 검색창은 항상 버퍼 1번째 줄만 검색어로 읽기 때문에, 여러 줄 코드를 붙여넣으면 첫 줄 이후가 조용히 버려집니다. grug-far는 검색/치환 입력이 일반 멀티라인 버퍼라 이 문제가 애초에 없고, 기본으로 여러 줄 검색·치환(Multiline search & replace)을 지원합니다. 내부적으로 `rg`(기본) 또는 `ast-grep` 엔진을 그대로 사용하고, 결과가 잘못되면 `rg`/`ast-grep`의 실제 에러 메시지를 그대로 보여줍니다.

**사용법**:

1. `<leader>sr`로 grug-far 버퍼 열기 (`GrugFar`)
2. 비주얼 모드에서 `<leader>sr`을 누르면 선택 영역으로만 범위를 좁혀서 검색/치환 (`GrugFarWithin`)
3. `Search:` 입력에 검색어(여러 줄 붙여넣기 가능)를 채우면 디바운스로 자동 검색
4. `Replace:` 입력을 채우면 diff가 표시되고, `<localleader>r`(Replace)로 실제 치환 실행
5. 결과 줄 위에서 `<enter>`(Goto)로 해당 위치로 이동, `<localleader>o`(Open)는 커서를 유지한 채 열기
6. `<localleader>c`로 grug-far 버퍼 닫기

> `<localleader>`를 별도로 설정하지 않았다면 기본값은 `\`입니다 (예: `<localleader>r` = `\r`).

**자주 쓰는 키맵** (buftype이 grug-far인 버퍼 안에서, normal 모드):

| 키맵 | 설명 |
|------|------|
| `<localleader>r` | Replace 실행 |
| `<localleader>s` | 결과 영역 편집 내용을 원본 파일에 동기화 (Sync Locations) |
| `<localleader>e` | 검색 엔진 전환 (ripgrep / astgrep / astgrep-rules) |
| `<localleader>w` | 실행되는 전체 CLI 커맨드 표시 토글 |
| `<localleader>t` | 검색 히스토리 열기 |
| `<localleader>q` | 결과를 quickfix 리스트로 열기 |
| `<localleader>c` | grug-far 버퍼 닫기 |
| `g?` | grug-far 키맵 도움말 |

**특수문자를 리터럴로 검색하고 싶을 때**: `Flags:` 입력에 `--fixed-strings`를 추가하면 `{`, `(` 등을 정규식으로 해석하지 않고 그대로 매치합니다. 반대로 정말 여러 줄에 걸친 블록을 원본과 동일한 개행까지 포함해 정확히 매치하려면 `--multiline`을 함께 추가하세요(단, `--multiline` 사용 시 Sync/quickfix 액션은 비활성화되고 `Replace` 액션만 동작합니다).

**설정 파일**: `lua/plugins/grug-far.lua`

### Python

**사용 플러그인**: pylsp (Python Language Server Protocol)

- **기본 설정**: `uv add pylsp, pylsp-mypy, mypy, ruff`
- **주요 기능**:
  - **rope_autoimport**: 자동 import 제안 (Code Action 통합)
  - **ruff**: 빠른 linting 및 import 정리
  - **mypy**: 강력한 타입 체킹
  - **rope**: 리팩토링 및 auto-import 기능

**Auto Import 사용법**:

1. 정의되지 않은 심볼(예: 함수, 클래스)에 커서를 위치
2. `<leader>ca` 키로 Code Action 메뉴 열기
3. "Import ..." 옵션 선택하여 자동으로 import 문 추가

**주요 설정** (`lua/plugins/nvim-lspconfig.lua`):

```lua
rope_autoimport = {
  enabled = true,
  code_actions = true,  -- Code Action으로 자동 import 제공
}
```

### TypeScript/JavaScript

**사용 플러그인**: tsserver (TypeScript Language Server)

- **기본 설정**: LazyVim extras (`lang.typescript`) 자동 설치
- **주요 기능**:
  - **Auto Import**: 자동 import 제안 및 추가
  - **Organize Imports**: import 문 자동 정리
  - **Quick Fix**: 타입 에러 자동 수정 제안
  - **Code Actions**: 리팩토링 및 코드 개선 제안

**Auto Import 사용법**:

1. **Code Action 방식**:
   - 정의되지 않은 심볼에 커서 위치
   - `<leader>ca` 키로 Code Action 메뉴 열기
   - "Import ..." 옵션 선택하여 자동으로 import 문 추가

2. **자동 완성 방식**:
   - 코드 작성 중 자동완성 메뉴에서 심볼 선택
   - tsserver가 자동으로 import 문 추가

3. **Import 정리**:
   - `<leader>ca` 후 "Organize Imports" 선택
   - 사용하지 않는 import 제거 및 정렬

**추가 기능**:
- `<leader>co`: Source Action (Organize Imports, Remove Unused 등)
- `<leader>cR`: 파일 이름 변경 및 import 경로 자동 업데이트

### Java

**사용 플러그인**: [nvim-java](https://github.com/nvim-java/nvim-java)

- **기본 설정**: nvim-java가 jdtls를 자동 관리
- **요구사항**: Java 17 이상 필요
- **자동 설치**: JDK, Java Test, Debug Adapter 자동 설치 지원

**주요 기능**:

- LSP (언어 서버): 자동 완성, 오류 검사, 리팩토링
- 테스트 실행: Java Test 통합
- 디버깅: nvim-dap 통합 디버그 어댑터
- Spring Boot: Spring Boot Tools 지원

**설치 후 확인**:

```bash
# Mason 설치 확인
:MasonLog
# Java 프로젝트에서 LSP 상태 확인
:LspInfo
```

**Lombok 문제 해결**:

```bash
# lombok.jar 다운로드 및 설치 (필요시)
curl -L https://projectlombok.org/downloads/lombok.jar -o /tmp/lombok.jar
cp /tmp/lombok.jar ~/.local/share/nvim/mason/packages/jdtls/lombok.jar
```

## 🔧 트러블슈팅

### Java/Lombok 에러

**에러**: `Error opening zip file or JAR manifest missing : lombok.jar`

**원인**:

- lombok.jar 파일 경로 오류
- 파일 손상 또는 불완전한 다운로드
- JDTLS와 Lombok 버전 호환성 문제

**해결 방법**:

1. **Lombok JAR 파일 재설치**:

```bash
# 기존 파일 삭제
rm ~/.local/share/nvim/mason/packages/jdtls/lombok.jar

# 최신 버전 다운로드
curl -L https://projectlombok.org/downloads/lombok.jar -o /tmp/lombok.jar

# Mason jdtls 디렉토리에 복사
cp /tmp/lombok.jar ~/.local/share/nvim/mason/packages/jdtls/lombok.jar

# 파일 권한 확인
chmod 644 ~/.local/share/nvim/mason/packages/jdtls/lombok.jar
```

2. **JAR 파일 무결성 확인**:

```bash
# JAR 파일이 유효한지 확인
jar tf ~/.local/share/nvim/mason/packages/jdtls/lombok.jar | head
```

3. **Neovim 완전 재시작**:

- Neovim을 완전히 종료하고 다시 시작
- `:LspRestart` 명령어로 LSP 서버 재시작

4. **Mason 재설치** (극단적인 경우):

```bash
# Mason 캐시 초기화
rm -rf ~/.local/share/nvim/mason
```

### Copilot.lua 에러

**에러**: `BugIndicatingError: Assertion Failed: unexpected state`

**원인**:

- Copilot.lua 플러그인 내부 상태 동기화 문제
- LSP 클라이언트와 Copilot 서비스 간 통신 오류
- 플러그인 버전 호환성 문제

**해결 방법**:

1. **플러그인 업데이트**:

```vim
:Lazy sync
```

2. **Copilot 재인증**:

```vim
:Copilot auth
```

3. **LSP 클라이언트 상태 확인**:

```vim
:lua print(vim.inspect(require("copilot.client").status()))
```

4. **Copilot 서비스 재시작**:

```vim
:Copilot disable
:Copilot enable
```

5. **디버그 로깅 활성화** (설정 파일에 추가):

```lua
require("copilot").setup({
  panel = { enabled = true },
  suggestion = { enabled = true },
  copilot_node_command = "node",
  server_opts_overrides = {
    trace = "verbose",
    settings = {
      advanced = {
        listCount = 10,
        inlineSuggestCount = 3,
      }
    }
  }
})
```

6. **완전한 초기화** (극단적인 경우):

```bash
# Copilot 관련 캐시 및 설정 삭제
rm -rf ~/.config/github-copilot
rm -rf ~/.local/share/nvim/copilot
```

### 일반적인 해결 방법

1. **Neovim 버전 확인 및 업데이트**:

```bash
nvim --version
# 최신 버전으로 업데이트 권장 (0.10+ 필요)
```

2. **플러그인 의존성 확인**:

```vim
:checkhealth
```

3. **로그 파일 확인**:

```vim
:messages
:LspLog
```

## 📚 핵심 개념

### CMP (Completion Engine)

**자동완성 엔진**으로, 사용자가 코드를 작성할 때 실시간으로 완성 제안을 제공합니다.

- **역할**: LSP, Copilot, 버퍼, 경로 등 다양한 소스의 완성 제안을 통합하여 UI로 표시
- **현재 사용**: **blink.cmp** (LazyVim 2025년 기본값)
- **주요 소스**:
  - `lsp`: LSP 서버의 자동완성
  - `copilot`: GitHub Copilot AI 제안
  - `buffer`: 현재 버퍼의 텍스트
  - `path`: 파일 경로
  - `snippets`: 코드 스니펫

### LSP (Language Server Protocol)

**언어 서버 프로토콜**은 에디터와 언어 서버 간의 표준 프로토콜입니다.

- **주요 기능**:
  - 자동완성 (Autocompletion)
  - 정의로 이동 (Go to Definition)
  - 참조 찾기 (Find References)
  - 진단 (Diagnostics - 오류/경고)
  - 코드 액션 (Code Actions)
  - 리팩토링 (Refactoring)

## 🔍 현재 설정 분석

### Completion Engine

**blink.cmp**를 사용 중이며, 다음과 같이 통합되어 있습니다:

```lua
sources = { "lsp", "path", "snippets", "buffer", "copilot" }
```

- ✅ **중복 없음**: nvim-cmp는 사용하지 않음 (example.lua는 비활성화됨)
- ✅ **Copilot 통합**: blink.cmp의 source로 완벽하게 통합
  - suggestion/panel 비활성화하여 모든 제안이 blink.cmp를 통해 표시
  - ghost text 없이 completion menu에서 일관된 UI 제공

### LSP 서버 상세

현재 활성화된 LSP 서버와 설정:

| 언어 | LSP 서버 | 추가 도구 | 특징 |
|------|---------|----------|------|
| **Python** | pylsp | ruff (linting), mypy (타입 체킹), rope (auto-import) | uv 런타임 사용, pyright 비활성화 |
| **Java** | jdtls | Java Test, Debug Adapter, Spring Boot Tools | nvim-java가 자동 관리 |
| **TypeScript/JS** | tsserver | - | LazyVim extras |
| **JSON** | jsonls | schemastore | LazyVim extras |
| **YAML** | yamlls | - | LazyVim extras |
| **Docker** | dockerls | - | LazyVim extras |
| **Kotlin** | kotlin_lsp | - | `lua/plugins/kotlin.lua` |
| **Scala** | metals | - | LazyVim extras |
| **TOML** | taplo | - | LazyVim extras |

## 📊 2025 트렌드 비교

### blink.cmp vs nvim-cmp

**현재 사용**: blink.cmp ✅

| 비교 항목 | blink.cmp (사용 중) | nvim-cmp (레거시) |
|----------|---------------------|-------------------|
| **성능** | 0.5-4ms (키 입력당) | 60ms debounce + 2-50ms hitches |
| **Fuzzy Matcher** | Rust 기반 frizbee (fzf 대비 6배 빠름) | fzf 스타일 |
| **기본 소스** | LSP, buffer, path, snippets 내장 | 모두 외부 플러그인 필요 |
| **Fuzzy Matching** | Typo-resistant (오타 허용) | 표준 fuzzy |
| **Scoring** | Frecency + Proximity | Proximity + 선택적 Recency |
| **트렌드** | 2025년 LazyVim 기본값 | 호환성 유지 (Neovim 0.9) |

**참고 자료**:
- [blink.cmp GitHub](https://github.com/Saghen/blink.cmp)
- [LazyVim Discussion: How to replace blink.cmp with nvim-cmp?](https://github.com/LazyVim/LazyVim/discussions/6388)
- [kickstart.nvim Issue: Use blink.cmp over nvim-cmp?](https://github.com/nvim-lua/kickstart.nvim/issues/1331)

### Python LSP: pyright vs pylsp

**현재 사용**: pylsp + ruff + mypy ✅

| 비교 항목 | pyright (일반적 선택) | pylsp (사용 중) |
|----------|----------------------|-----------------|
| **속도** | 빠름 | 보통 |
| **타입 체킹** | 강력한 내장 타입 체킹 | mypy 통합으로 보완 |
| **의존성** | Node.js 필요 | Python만 필요 |
| **유연성** | 설정 옵션 적음 | 매우 유연한 플러그인 시스템 |
| **ML 라이브러리** | 일부 지원 부족 (opencv 등) | 플러그인으로 확장 가능 |
| **Auto-import** | 내장 | rope 플러그인 필요 |
| **LazyVim 기본값** | pyright (또는 basedpyright) | - |

**현재 설정의 장점**:
- ✅ Node.js 의존성 없음
- ✅ ruff로 빠른 linting
- ✅ mypy로 강력한 타입 체킹
- ✅ rope로 auto-import 기능
- ✅ 높은 확장성

**참고 자료**:
- [LazyVim Python LSP](https://www.lazyvim.org/extras/lang/python)
- [nvimdots Discussion: pyright vs pylsp](https://github.com/ayamir/nvimdots/discussions/708)
- [Getting the Best Python LSP for Neovim](https://toxigon.com/neovim-best-python-lsp)

### 결론

**✅ 현재 설정은 2025년 트렌드에 부합합니다:**

1. **blink.cmp**: LazyVim의 최신 기본값 사용 중
2. **LSP 서버**: 각 언어별 표준 또는 우수한 대안 사용
3. **Python**: pylsp가 pyright보다 덜 일반적이지만, ruff + mypy 통합으로 동등한 기능 제공
4. **중복 없음**: 모든 도구가 명확한 역할 분담

**개선 고려 사항** (선택적):
- Python에서 더 빠른 타입 체킹을 원하면 pyright로 전환 고려
- 하지만 현재 pylsp + ruff + mypy 조합도 충분히 효율적

## 🔌 설치된 플러그인 및 도구

### LazyVim Extras

현재 활성화된 LazyVim extras 목록:

- **formatting.prettier** - Prettier 포맷터
- **lang.docker** - Docker 파일 지원
- **lang.java** - Java 개발 환경
- **lang.json** - JSON 지원
- **lang.kotlin** - Kotlin 개발 환경
- **lang.markdown** - Markdown 지원
- **lang.python** - Python 개발 환경
- **lang.scala** - Scala 개발 환경
- **lang.toml** - TOML 파일 지원
- **lang.typescript** - TypeScript/JavaScript 개발 환경
- **lang.yaml** - YAML 파일 지원

### 커스텀 플러그인

| 플러그인 | 용도 | 설정 파일 |
|---------|------|-----------|
| **zbirenbaum/copilot.lua** | GitHub Copilot AI 자동완성 | `lua/plugins/copilot.lua` |
| **fang2hou/blink-copilot** | Copilot blink.cmp 통합 | `lua/plugins/copilot.lua` |
| **CopilotChat.nvim** | Copilot 대화형 AI | `lua/plugins/copilot-chat.lua` |
| **coder/claudecode.nvim** | Claude Code 통합 | `lua/plugins/claude-code.lua` |
| **stevearc/oil.nvim** | 파일 탐색기 | `lua/plugins/oil.lua` |
| **nvim-java** | Java 개발 환경 | `lua/plugins/java.lua` |
| **nvim-dap** | 디버깅 지원 | `lua/plugins/dap.lua` |
| **tpope/vim-fugitive** | Neovim 내장 Git 클라이언트 (status·diff·blame·리베이스) | `lua/plugins/fugitive.lua` |
| **MagicDuck/grug-far.nvim** | 여러 줄/특수문자 포함 검색·치환 (Find & Replace) | `lua/plugins/grug-far.lua` |

### LSP 서버

| 언어 | LSP 서버 | 추가 도구 | 설정 |
|------|---------|----------|------|
| **Python** | pylsp | ruff (linting), mypy (타입 체킹), rope (auto-import) | `lua/plugins/nvim-lspconfig.lua` |
| **Java** | jdtls | Java Test, Debug Adapter, Spring Boot Tools | `lua/plugins/java.lua` |
| **TypeScript/JavaScript** | tsserver | - | LazyVim extras |
| **JSON** | jsonls | schemastore | LazyVim extras |
| **YAML** | yamlls | - | LazyVim extras |
| **Docker** | dockerls | - | LazyVim extras |
| **Kotlin** | kotlin_lsp | - | `lua/plugins/kotlin.lua` |
| **Scala** | metals | - | LazyVim extras |
| **TOML** | taplo | - | LazyVim extras |
| **Markdown** | ❌ 비활성화 | - | `lua/plugins/markdown.lua` |

### Linter & Formatter

LazyVim은 기본적으로 다음 도구들을 사용합니다:

- **conform.nvim** - 코드 포맷팅
  - Python: ruff
  - TypeScript/JavaScript: prettier
  - JSON: prettier
  - Markdown: ❌ 비활성화
  
- **nvim-lint** - 코드 린팅
  - Python: ruff + mypy (pylsp 통합)
  - Markdown: ❌ 비활성화

### Copilot 설정

**사용 플러그인**:
- [zbirenbaum/copilot.lua](https://github.com/zbirenbaum/copilot.lua)
- [fang2hou/blink-copilot](https://github.com/fang2hou/blink-copilot)

**설정 방식**:
- Copilot 제안이 blink.cmp completion menu에 통합되어 표시
- Ghost text(회색 텍스트) 비활성화
- 모든 제안이 completion dialog에서 일관되게 표시
- LazyVim의 기본 completion 엔진인 blink.cmp와 완벽하게 통합

**로그인 방법**:

```vim
# Neovim에서 Copilot 인증
:Copilot auth
```

브라우저가 열리고 GitHub 인증 코드 입력 화면이 나타납니다.
화면의 안내에 따라 인증 코드를 입력하면 로그인이 완료됩니다.

**상태 확인**:

```vim
# Copilot 상태 확인
:Copilot status

# Copilot 비활성화/활성화
:Copilot disable
:Copilot enable
```

**사용 방법**:

1. Insert 모드에서 코드를 작성하면 자동으로 Copilot 제안이 completion menu에 표시됩니다
2. `<C-n>` / `<C-p>` 키로 제안 항목 간 이동
3. `<Tab>` 또는 `<CR>`로 선택한 제안 적용
4. `<C-e>`로 completion menu 닫기

**설정 파일**: `lua/plugins/copilot.lua`
