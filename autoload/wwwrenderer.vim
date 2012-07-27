"File: wwwrenderer.vim
"Last Change: 27-Jul-2012.
"Version: 0.01
"
" *wwwrenderer.vim* www renderer for vim
"
" Author: Yasuhiro Matsumoto <mattn.jp@gmail.com>
" WebSite: http://mattn.kaoriya.net/
" Repository: http://github.com/mattn/wwwrenderer-vim
" License: BSD style license
" ===============================================================================
" CONTENTS                                                   *wwwrenderer-contents*
" Introduction           |wwwrenderer-intro|
" Install                |wwwrenderer-install|
" Install                |wwwrenderer-usage|
" For Reader             |wwwrenderer-todo|
"
" INTRODUCTION                                                  *wwwrenderer-intro*
"
"   This is vimscript like world wide web browser.
"
" INSTALL                                                     *wwwrenderer-install*
"
"   copy wwwrenderer.vim to rtp/autoload directory.
"   this script require curl command and webapi-vim.
"
"   see: http://github.com/mattn/webapi-vim
"
" USAGE                                                        *wwwrenderer-writer*
"
"   This is utility function. Then, you should call as below.
"
" >
"   echo wwwrenderer#render('http://eow.alc.co.jp/fusion/UTF-8/',
"       ['div', {'class': 'sas'}], ['div', {'id': 'resultsList'}])
" <
"
"   First parameter is URL to get.
"   Second and following parameters is scraping option.
"
" >
"   ['div', {'class': 'sas'}]
" <
"
"   A first of array is tag name. and second one is directory object that
"   specify attributes. Above line is meaning div[@class=sas] in saying XPath.
"
" ==============================================================================
" TODO                                                           *wwwrenderer-todo*
" * form/input/text ?
" ==============================================================================
" vim:tw=78:ts=8:ft=help:norl:noet:fen:fdl=0:
" ExportDoc: wwwrenderer.txt:5:-1
"
function! s:render(dom, pre, extra)
  let dom = a:dom
  if type(dom) == 0 || type(dom) == 1 || type(dom) == 5
    let html = webapi#html#decodeEntityReference(dom)
    let html = substitute(html, '\r', '', 'g')
    if a:pre == 0
      let html = substitute(html, '\n\+\s*', '', 'g')
    endif
    let html = substitute(html, '\t', '  ', 'g')
    return html
  elseif type(dom) == 3
    let html = ""
    for d in dom
      let html .= s:render(d, a:pre, a:extra)
      unlet d
    endfor
    return html
  elseif type(dom) == 4
    if empty(dom)
      return ""
    endif
    if dom.name != "script" && dom.name != "style" && dom.name != "head"
      let html = s:render(dom.child, a:pre || dom.name == "pre", a:extra)
      if dom.name =~ "^h[1-6]$" || dom.name == "br" || dom.name == "dt" || dom.name == "dl" || dom.name == "li" || dom.name == "p" || dom.name == "div"
        let html = "\n".html."\n"
      endif
      if dom.name == "pre" || dom.name == "blockquote"
        let html = "\n  ".substitute(html, '\n', '\n  ', 'g')."\n"
      endif
      if type(a:extra) == 3 && dom.name == "a"
        let lines = split(html, "\n", 1)
        let y = len(lines)
        let x = len(lines[-1])
        call add(a:extra, {"x": x, "y": y, "node": dom})
      endif
      return html
    endif
    return ""
  endif
endfunction

function! wwwrenderer#render_dom(dom)
  return s:render(a:dom, 0, 0)
endfunction

function! wwwrenderer#render(url, ...)
  let scrape = a:000
  let res = webapi#http#get(a:url)
  let enc = "utf-8"
  let mx = '.*charset="\?\([^;]\+\)'
  for h in res.header
    if h =~ "^Content-Type"
      let tmp = matchlist(h, mx)
      if len(tmp)
        let enc = tolower(tmp[1])
      endif
    endif
  endfor
  if res.content !~ '^\s*<?xml'
    let res.content = iconv(res.content, enc, &encoding)
  endif
  let dom = webapi#html#parse(res.content)
  if len(scrape) == 0
    let ret = dom
  else
    let ret = []
    for s in scrape
      call add(ret, dom.find(s[0], s[1]))
      call add(ret, "\n")
    endfor
  endif
  return s:render(dom, 0, 0)
endfunction

function! wwwrenderer#content(url, ...)
  let scrape = a:000
  let res = webapi#http#get(a:url)
  let enc = "utf-8"
  let mx = '.*charset="\?\([^;]\+\)'
  for h in res.header
    if h =~ "^Content-Type"
      let tmp = matchlist(h, mx)
      if len(tmp)
        let enc = tolower(tmp[1])
      endif
    endif
  endfor
  if res.content !~ '^\s*<?xml'
    let res.content = iconv(res.content, enc, &encoding)
  endif
  let dom = webapi#html#parse(res.content)
  if len(scrape) == 0
    let ret = dom
  else
    let ret = []
    for s in scrape
      call add(ret, dom.find(s[0], s[1]))
      call add(ret, "\n")
    endfor
  endif
  let extra = []
  let content = s:render(dom, 0, extra)
  return [content, extra]
endfunction

function! wwwrenderer#wrap(content)
  let lines = split(a:content, "\n")
  let idx = 0
  while idx < len(lines)
    let w = strdisplaywidth(lines[idx])
    if w >= &columns
      let indent = matchstr(lines[idx], '^\s*')
      let [line, ins] = ['', '']
      for c in split(lines[idx], '\zs')
        if strdisplaywidth(line . c) >= &columns
          let ins .= line . "\n"
          let line = indent
        endif
        let line .= c
      endfor
      let ins .= line . "\n"
      if idx == 0
        let lines = split(ins, "\n") + lines[idx+1:]
      else
        let lines = lines[0: idx-1] + split(ins, "\n") + lines[idx+1:]
      endif
    endif
    let idx += 1
  endwhile
  return join(lines, "\n")
endfunction
