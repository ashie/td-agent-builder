@echo off
title Td-agent post install script
if not "%~dp0" == "C:\opt\td-agent\bin\" (
   "%~dp0gem" pristine --only-executables --all
)
