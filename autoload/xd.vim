" xd.vim - Installs external dependencies
" Author: Richie Tan <richietan2004@gmail.com>
" License: MIT License

if exists('g:loaded_xd')
  finish
endif
let g:loaded_xd = 1

let s:cpo_save = &cpo
set cpo&vim

let s:has_powershell = has('powershell')

function! xd#check_external_dependencies(external_dependencies, providers) abort
  let missing_external_dependency_list = []
  for [dependency_cmd, dependency] in items(a:external_dependencies)
    if !executable(dependency_cmd) && !empty(dependency[s:has_powershell])
      call add(missing_external_dependency_list, dependency[s:has_powershell])
    endif
  endfor

  let missing_provider_list = []
  for provider in a:providers
    if !has(provider)
      call add(missing_provider_list, provider)
    endif
  endfor

  let cmd_list = []
  if len(missing_external_dependency_list) > 0
    let missing_external_dependencies = join(missing_external_dependency_list)
    if s:has_powershell
      if !executable('scoop')
        call add(cmd_list, 'Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; iwr -useb get.scoop.sh | iex')
      endif
      call add(cmd_list, 'scoop install ' . missing_external_dependencies)
    else
      if !executable('brew')
        if !empty(glob('/home/linuxbrew/.linuxbrew'))
          call add(cmd_list, 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)')
        elseif !empty(glob('~/.linuxbrew'))
          call add(cmd_list, 'eval $(~/.linuxbrew/bin/brew shellenv)')
        else
          call add(cmd_list, 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"; { test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv); }; { test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv); }')
        endif
      endif
      call add(cmd_list, 'brew reinstall ' . missing_external_dependencies)
    endif
  endif

  " Ruby support for Neovim
  if index(missing_provider_list, 'ruby') >= 0
    call add(cmd_list, 'gem install neovim')
  endif

  " Get new $PATH
  if s:has_powershell
    call add(cmd_list, 'echo $env:PATH')
  else
    call add(cmd_list, 'echo $PATH')
  endif

  " Run commands and set new $PATH
  if !empty(cmd_list)
    let cmds = join(cmd_list, '; ')
    silent! let $PATH = systemlist(cmds)[-1]
  endif
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
