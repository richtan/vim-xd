" xd.vim - Installs external dependencies
" Author: Richie Tan <richietan2004@gmail.com>
" License: MIT License

if exists('g:loaded_xd')
  finish
endif
let g:loaded_xd = 1

let s:cpo_save = &cpo
set cpo&vim

let s:has_powershell = executable('powershell')
let s:cmd_list = []

function! s:run_cmd() abort
  let path_cmd_list = []

  " Confirm install
  let cmds = join(s:cmd_list, '; ')
  let install_confirmed = !empty(cmds) && confirm("Install missing external dependencies?\nCommands: " . cmds, "&Yes\n&no", 1) == 1

  " Get previous $PATH
  if s:has_powershell
    call add(path_cmd_list, "$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')")
    call add(s:cmd_list, "$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')")
  elseif !executable('brew')
    if !empty(glob('/home/linuxbrew/.linuxbrew'))
      call add(path_cmd_list, 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)')
      call add(s:cmd_list, 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)')
    elseif !empty(glob('~/.linuxbrew'))
      call add(path_cmd_list, 'eval $(~/.linuxbrew/bin/brew shellenv)')
      call add(s:cmd_list, 'eval $(~/.linuxbrew/bin/brew shellenv)')
    endif
  endif

  " Get new $PATH
  if s:has_powershell
    call add(path_cmd_list, 'echo $env:PATH')
  else
    call add(path_cmd_list, 'echo $PATH')
  endif

  " Run commands and set new $PATH
  let path_cmds = join(path_cmd_list, '; ')
  let cmds = join(s:cmd_list, '; ')
  if install_confirmed
    execute '!' . cmds
  endif
  silent! let $PATH = systemlist(path_cmds)[-1]

  " Reset cmd_list
  let s:cmd_list = []
endfunction

function! xd#check_external_dependencies(external_dependencies, providers) abort
  " Setup shell
  let shell_save = &shell
  let shellcmdflag_save = &shellcmdflag
  let shellquote_save = &shellquote
  let shellxquote_save = &shellxquote

  if s:has_powershell
    set shell=powershell
  else
    set shell=sh
  endif
  set shellquote=
  set shellcmdflag=-c
  set shellxquote=

  silent! call s:run_cmd()

  " Check missing dependencies
  let missing_external_dependency_list = []
  for [dependency_cmd, dependency] in items(a:external_dependencies)
    if !executable(dependency_cmd) && !empty(dependency[s:has_powershell])
      call add(missing_external_dependency_list, dependency[s:has_powershell])
    endif
  endfor

  " Check missing providers
  let missing_provider_list = []
  let provider_installed_list = {
        \ 'ruby': executable('neovim-ruby-host'),
        \ 'python3': (has('nvim') ? system((executable('py') ? 'py -3' : 'python3') . ' -c ''import pkgutil; print(1 if pkgutil.find_loader("pynvim") else 0)''') == 1 : 0)
        \ }

  for provider in a:providers
    if !provider_installed_list[provider]
      call add(missing_provider_list, provider)
    endif
  endfor

  if len(missing_external_dependency_list) > 0
    let missing_external_dependencies = join(missing_external_dependency_list)
    if s:has_powershell
      if !executable('scoop')
        call add(s:cmd_list, 'Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; iwr -useb get.scoop.sh | iex')
      endif
      call add(s:cmd_list, 'scoop install ' . missing_external_dependencies)
    else
      if !executable('brew')
        call add(s:cmd_list, 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"; { test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv); }; { test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv); }')
      endif
      call add(s:cmd_list, 'brew reinstall ' . missing_external_dependencies)
    endif
  endif

  if has('nvim')
    " Ruby support for Neovim
    if index(missing_provider_list, 'ruby') >= 0
      call add(s:cmd_list, 'gem install neovim')
    endif

    " Python3 support for Neovim
    if index(missing_provider_list, 'python3') >= 0
      call add(s:cmd_list, (executable('py') ? 'py -3' : 'python3') . ' -m pip install neovim')
    endif
  endif

  " Install missing external dependencies
  call s:run_cmd()

  " Revert shell
  let &shell = shell_save
  let &shellcmdflag = shellcmdflag_save
  let &shellquote = shellquote_save
  let &shellxquote = shellxquote_save
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
