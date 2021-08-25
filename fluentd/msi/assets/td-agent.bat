@echo off
set TD_AGENT_TOPDIR=%~dp0\..
set PATH="%~dp0";%PATH%
set FLUENT_CONF=%TD_AGENT_TOPDIR%\etc\td-agent\td-agent.conf
set FLUENT_PLUGIN=%TD_AGENT_TOPDIR%\etc\td-agent\plugin
set TD_AGENT_VERSION=%TD_AGENT_TOPDIR%\bin\td-agent-version.rb
for %%p in (%*) do (
    if "%%p"=="--version" (
        ruby "%TD_AGENT_VERSION%"
        goto last
    )
)
"%TD_AGENT_TOPDIR%\bin\fluentd" %*

:last
