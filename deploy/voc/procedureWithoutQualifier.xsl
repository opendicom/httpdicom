<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns="http://www.opendicom.com/xsd/plist/procedure.xsd"
    xpath-default-namespace="http://www.opendicom.com/xsd/plist/procedure.xsd"
    exclude-result-prefixes="xs"
    version="2.0"   >
    
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="dict[1]/dict/array">
        <xsl:element name="dict">
            <xsl:element name="key"><xsl:value-of select="normalize-space(dict/integer/text())"/></xsl:element>
            <xsl:element name="string"><xsl:attribute name="id">code</xsl:attribute><xsl:value-of select="normalize-space(dict/string/text())"/></xsl:element>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="key[text()='procedurescheme']">
        <xsl:element name="key">scheme</xsl:element>
    </xsl:template>
    
</xsl:stylesheet>