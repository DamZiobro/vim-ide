" GStreamer Vim syntax file

" Language:         /var/log/syslog file
" Maintainer:       Damian Ziobro <damian@xmementoit.com>
" Date:             2018-Mar-01

"
" Vim syntax file which outputs coloured logs for GStreamer logs forwarded to 
" /var/log/syslog (syslog-based) files
"
" Installation: 
"   1. Place gstreamer_highlight_syntax.vim file to your $HOME/.vim/syntax directory
"   2. Put following line somewhere into your $HOME/.vimrc file: 
"      au BufNewfile,BufRead syslog*.log set filetype=gstreamer_highlight_syntax
"
if exists("b:current_syntax")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

syn match   messagesBegin       display '^' nextgroup=messagesDate,messagesDateRFC3339

syn match   messagesDate        contained display '^\a\a\a *\d\{1,2} *'
                                \ nextgroup=messagesHour

syn match   messagesHour        contained display '\d\d:\d\d:\d\d\s*'
                                \ nextgroup=messagesHost

syn match   messagesDateRFC3339 contained display '\d\{4}-\d\d-\d\d'
                                \ nextgroup=messagesRFC3339T

syn match   messagesRFC3339T    contained display '\cT'
                                \ nextgroup=messagesHourRFC3339

syn match   messagesHourRFC3339 contained display '\c\d\d:\d\d:\d\d\(\.\d\+\)\=\([+-]\d\d:\d\d\|Z\)'
                                \ nextgroup=messagesHost

syn match   messagesHost        contained display '\S*\s*' contains=messagesPID
                                \ nextgroup=messagesLabel

syn match   messagesLabel       contained display '\s*[^:]*:\s*'
                                \ nextgroup=messagesText contains=messagesPID

syn match   messagesPID         contained display '\[\zs\d\+\ze\]'

syn match   messagesIP          '\d\+\.\d\+\.\d\+\.\d\+'

syn match   messagesURL         '\w\+://\S\+'

syn match   messagesText        contained display '.*'
                                \ contains=messagesNumber,
                                \ messagesIP,
                                \ messagesURL,
                                \ messagesError,
                                \ defaultKeyword,
                                \ errorKeyword,
                                \ warnKeyword,
                                \ infoKeyword,
                                \ debugKeyword,
                                \ fixmeKeyword,
                                \ timeKeyword,
                                \ bytesKeyword,
                                \ buffersKeyword,
                                \ srcmatch,
                                \ sinkmatch,
                                \ basesinkKeyword,
                                \ videoDecoderKeyword,
                                \ demuxMatch,
                                \ depayMatch,
                                \ decMatch,
                                \ encMatch,
                                \ binMatch,
                                \ muxmatch,
                                \ paymatch,
                                \ queuematch,
                                \ teematch,
                                \ capsfiltermatch,
                                \ convertmatch,
                                \ videoratematch,
                                \ parseMatch, 
                                \ splitmuxsinkmatch,
                                \
                                \ channelNameKeyword,
                                \ imageFormatKeyword,
                                \ frameTimestampKeyword,
                                \ widthHeightKeyword,
                                \ nfofmessagessentKeyword,
                                \ lastTimestampDiffKeyword,
                                \ gstreamerCodeKeyword,
                                \ gstreamerDiagnostics


syn match   messagesNumber      contained '0x[0-9a-fA-F]*\|\[<[0-9a-f]\+>\]\|\<\d[0-9a-fA-F]*'

syn match   messagesError       contained '\c.*\<\(SERIOUS\|LOG_ERR\|ERROR\|ERRORS\|FAILED\|FAILURE\|01mERROR\|last_timestamp_diff\:\ \d\{1,2\}$\).*'

hi def link messagesDate        Constant
hi def link messagesHour        Type
hi def link messagesDateRFC3339 Constant
hi def link messagesHourRFC3339 Type
hi def link messagesRFC3339T    Normal
hi def link messagesHost        Identifier
hi def link messagesLabel       Operator
hi def link messagesPID         Constant
hi def link messagesError       ErrorMsg
hi def link messagesIP          Constant
hi def link messagesURL         Underlined
hi def link messagesText        Normal
hi def link messagesNumber      Number

let b:current_syntax = "messages"

let &cpo = s:cpo_save
unlet s:cpo_save

"============================================================================== 

syn match   srcmatch       contained '[a-z0-9]\+src[0-9]*'
syn match   sinkmatch       contained '[a-z0-9]\+sink[0-9]*'
syn match   splitmuxsinkmatch       contained '\(splitmuxsink\|gstsplitmuxsink\)'
syn match parseMatch        contained '[a-z0-9]\+parse[0-9]*'
syn match demuxMatch       contained '[a-z0-9]\+demux[0-8]*'
syn match decMatch       contained '\(avdec_[a-z0-9]\+\|[a-z0-9]\+dec[0-9]*\)'
syn match encMatch       contained '\(avenc_[a-z0-9]\+\|[a-z0-9]\+enc[0-9]*\)'
syn match binMatch       contained '\([a-z0-9_]\+bin[0-9]*\)'
syn match depayMatch       contained '[a-z0-9]\+depay[0-9]*'
syn match muxmatch       contained '[a-z0-9]\+[a-ce-z0-9][a-df-suz0-9]mux[0-9]*'
syn match paymatch       contained '[a-z0-9]\+[a-ce-z0-9][a-df-suz0-9]pay[0-8]*'
syn match queuematch       contained '\(queue\|gstqueue\|multiqueue\|gstmultiqueue\|queue2\|gstqueue2\)'
syn match teematch       contained '\(tee\|gsttee\)'
syn match capsfiltermatch       contained '\(capsfilter\|gstcapsfilter\|caps\)'
syn match convertmatch       contained '\(videoconvert\|gstvideoconvert\|audioconvert\|gstaudioconvert\)'
syn match videoratematch       contained '\(videorate\|gstvideorate\)'
syn match   dumpPipeline       '.*\(gst_debug_bin_to_dot_file\).*'
syn keyword defaultKeyword   default
syn keyword basesinkKeyword        basesink gstbasesink
syn keyword videoDecoderKeyword          videodecoder gstvideodecoder
syn keyword buffersKeyword  buffers
syn keyword bytesKeyword   bytes
syn keyword timeKeyword         time
syn keyword errorKeyword         SERIOUS LOG_ERR ERR ERROR ERRORS FAILED FAILURE CRIT CRITICAL error errors err failed fatal crit critical deadlock DEADLOCK starvation disaster panic trouble inappropriate invalid cannot null NOT failure Unable unable Invalid panic 01mERROR
syn keyword warnKeyword          WARN CONCERN WARNING warn warning concern problem 01mWARN
syn keyword infoKeyword          INFO INFORMATION 36mINFO
syn keyword debugKeyword          DEBUG Debug debug 37mDEBUG
syn keyword fixmeKeyword          FIXME fixme TODO todo 01mFIXME

syn keyword channelNameKeyword         channelName CHANNEL_NAME channel_name CHANNELNAME 
syn keyword lastTimestampDiffKeyword          last_timestamp_diff LAST_TIMESTAMP_DIFF 
syn keyword imageFormatKeyword     imageFormat
syn keyword frameTimestampKeyword          frameTimestamp
syn keyword widthHeightKeyword     width height
syn keyword gstreamerCodeKeyword           gstreamerCode
syn keyword nfofmessagessentKeyword     nrOfMessagesSent
syn match   monitorFrames       '.*\(monitor_frames_sending\).*'
syn match   getLogs            '.*get-logs.sh.*'
syn match   startingDtvGrabber       '.*\(Starting dtv-grabber\|Configuration...config.file\|New pipeline name\|hls_uri\|http_uri\|digitalTVSystem\).*'
syn keyword gstreamerDiagnostics         gstreamerDiagnostics

" defining highilghts "

hi dumpPipeline       ctermbg=24  ctermfg=150 cterm=bold
hi parseMatch       ctermfg=152
hi splitmuxsinkmatch ctermfg=148 cterm=bold
hi muxmatch          ctermfg=168
hi paymatch          ctermfg=171
hi queuematch          ctermfg=181
hi teematch          ctermfg=193
hi capsfiltermatch          ctermfg=211
hi convertmatch          ctermfg=215
hi videoratematch          ctermfg=221
hi srcmatch      ctermfg=116 cterm=bold,underline
hi sinkmatch      ctermfg=118 cterm=bold,underline
hi demuxMatch     ctermfg=184 cterm=bold
hi depayMatch     ctermfg=187 cterm=bold
hi decMatch     ctermfg=192 cterm=bold
hi encMatch     ctermfg=195 cterm=bold
hi binMatch     ctermfg=199 cterm=bold
hi errorKeyword        ctermfg=1   cterm=bold,underline
hi warnKeyword         ctermfg=178 cterm=bold,underline
hi infoKeyword        ctermfg=101  
hi infoKeyword        ctermfg=101  
hi debugKeyword         ctermfg=35
hi fixmeKeyword         ctermfg=37, cterm=bold,underline
hi bytesKeyword  ctermfg=117
hi timeKeyword        ctermfg=140
hi buffersKeyword ctermfg=153 cterm=bold
hi defaultKeyword  ctermfg=97  cterm=bold
hi basesinkKeyword       ctermfg=127
hi videoDecoderKeyword         ctermfg=116

hi channelNameKeyword        ctermfg=11 cterm=bold
hi lastTimestampDiffKeyword         ctermfg=191 cterm=bold
hi imageFormatKeyword    ctermfg=134
hi frameTimestampKeyword         ctermfg=97
hi widthHeightKeyword    ctermfg=141
hi nfofmessagessentKeyword    ctermfg=123 cterm=bold,underline
hi gstreamerCodeKeyword          ctermfg=121
hi gstreamerDiagnostics        ctermfg=111
hi monitorFrames  ctermbg=18 ctermfg=192
hi getLogs       ctermbg=22 ctermfg=192
hi startingDtvGrabber       ctermbg=17  ctermfg=184 cterm=bold

"==============================================================================
