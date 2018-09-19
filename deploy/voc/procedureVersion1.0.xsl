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

    <xsl:template match="key[text()='code']">
        <xsl:element name="key">codes</xsl:element>
        <xsl:element name="array">
            <xsl:element name="dict">
                <xsl:element name="key">code</xsl:element>
                <xsl:element name="string"><xsl:attribute name="id">codestring</xsl:attribute><xsl:value-of select="following-sibling::string[1]/text()"/></xsl:element>
                <xsl:element name="key">scheme</xsl:element>
                <xsl:element name="integer"><xsl:value-of select="following-sibling::integer[1]/text()"/></xsl:element>
                <xsl:element name="key">qualifier</xsl:element>
                <xsl:element name="array"></xsl:element>
             </xsl:element>
        </xsl:element>
    </xsl:template>
    
    
    <xsl:template match="string[@id='code']">
    </xsl:template>
    
    <xsl:template match="key[text()='scheme']">
    </xsl:template>
    
    <xsl:template match="key[text()='qualifier']">
    </xsl:template>
    
    <xsl:template match="code">
    </xsl:template>
    
    <xsl:template match="integer">
    </xsl:template>
    
    <xsl:template match="array">
    </xsl:template>
    
</xsl:stylesheet>