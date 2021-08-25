<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:wix="http://schemas.microsoft.com/wix/2006/wi"
    xmlns="http://schemas.microsoft.com/wix/2006/wi"
    version="1.0" 
    exclude-result-prefixes="xsl wix">

    <xsl:output method="xml" indent="yes" omit-xml-declaration="yes" />

    <xsl:strip-space elements="*" />

    <!-- By default, copy all elements and nodes into the output -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>

    <!-- Exclude patterns -->
    <xsl:key
        name="conf-search"
        match="wix:Component[wix:File/@Source = '$(var.ProjectSourceDir)\etc\td-agent\td-agent.conf']"
        use="@Id" />
    <xsl:template match="*[self::wix:Component or self::wix:ComponentRef][key('conf-search', @Id)]" />
    <xsl:key
        name="service-bat-search"
        match="wix:Component[wix:File/@Source = '$(var.ProjectSourceDir)\bin\td-agent.bat']"
        use="@Id" />
    <xsl:template match="*[self::wix:Component or self::wix:ComponentRef][key('service-bat-search', @Id)]" />
</xsl:stylesheet>
