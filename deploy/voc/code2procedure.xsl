<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="dict/dict">
        <dict>
            <key>displayname</key>
            <string id="displayname"><xsl:value-of select="string[1]/text()"/></string>
            <key>shortname</key>
            <string id="shortname"/>
            <key>scheme</key>
            <integer>7</integer>
            <key>modality</key>
            <string id="modality"><xsl:value-of select="string[2]/text()"/></string>
            <key>category</key>
            <string id="category"><xsl:value-of select="string[3]/text()"/></string>
            <key>codes</key>
            <dict><key>4</key><string id="code"><xsl:value-of select="preceding-sibling::key[1]/text()"/></string></dict>            
        </dict>
    </xsl:template>
    
</xsl:stylesheet>