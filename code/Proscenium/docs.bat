@echo off
SETLOCAL
set TARGET_PLAYER=11.1
if exist docs rmdir /S /Q docs
if not exist docs mkdir docs
"%FLEX_HOME%\bin\asdoc"^
 -source-path .\src^
 -doc-sources .\src^
 -output .\docs^
 -compiler.define "CONFIG::debug" "true"^
 -compiler.define "CONFIG::release" "false"^
 -compiler.define "CONFIG::genericBinaryLogging" "false"^
 -compiler.define "CONFIG::traceInstance3DOps" "false"^
 -external-library-path+="%FLEX_HOME%\frameworks\libs"^
 -external-library-path+="%FLEX_HOME%\frameworks\libs\player\%TARGET_PLAYER%\playerglobal.swc"^
 -library-path+=.\libs^
 -main-title "Proscenium Library Reference"^
 -footer "Copyright 2012 Adobe Systems Incorporated. All rights reserved."^
 -swf-version 13^
 -target-player %TARGET_PLAYER%
ENDLOCAL