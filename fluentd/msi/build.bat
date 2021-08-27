SET SRC_DIR=%~dp0
CALL "%SRC_DIR%env.bat"

tar xvf "%SRC_DIR%..\%PACKAGE%-%VERSION%.tar.gz"
cd "%PACKAGE%-%VERSION%"
rake msi:selfbuild TD_AGENT_STAGING_PATH="C:/opt/td-agent" TD_AGENT_MSI_OUTPUT_PATH="%SRC_DIR%\repositories"
