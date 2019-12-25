if exists('g:loaded_xd')
  finish
endif
let g:loaded_xd = 1

function! xd#check_external_dependencies(external_dependencies) abort
  let missing_external_dependency_list = []
  for dependency in keys(a:external_dependencies)
    if !executable(dependency) && !empty(a:external_dependencies[dependency][executable('powershell') ? 0 : 1])
      call add(missing_external_dependency_list, a:external_dependencies[dependency][executable('powershell') ? 0 : 1])
    endif
  endfor

  if len(missing_external_dependency_list) > 0
    let missing_external_dependencies = join(missing_external_dependency_list)
    if executable('powershell')
      let scoop_cmd = executable('scoop') ? '' : 'Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; iwr -useb get.scoop.sh | iex; '
      let scoop_cmd ..= 'scoop install ' . missing_external_dependencies
      let @+ = scoop_cmd
      echom 'Run the copied commands in PowerShell to install missing external dependencies.'
    elseif executable('bash')
      if !executable('brew')
        if !empty(glob('/home/linuxbrew/.linuxbrew'))
          let brew_cmd = 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv); '
        elseif !empty(glob('~/.linuxbrew'))
          let brew_cmd = 'eval $(~/.linuxbrew/bin/brew shellenv); '
        else
          let brew_cmd = 'sh -c "$(curl -fsSL http//raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"; test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv); test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv); '
        endif
      else
        let brew_cmd = ''
      endif
      let brew_cmd ..= 'brew install ' . missing_external_dependencies
      let @+ = brew_cmd
      echom 'Run the copied commands in Bash to install missing external dependencies.'
    else
      let @+ = missing_external_dependencies
      echom 'Install these missing dependencies and add them to PATH (copied): ' . missing_external_dependencies
    endif
  endif
endfunction
