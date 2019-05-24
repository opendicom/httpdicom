<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0"
    >
    
    <xsl:template match="/root">
        <plist 
            version="1.0"
            object="procedure"
            objectversion="1.0"
            >
            <!-- add to product
            xmlns="http://www.opendicom.com/xsd/plist/procedure.xsd"
            xmlns:xsi="htt//www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="htt//www.opendicom.com/xsd/plist/procedure.xsd ../procedure.xsd"
            -->
            <dict oid="1.3.6.1.4.1.23650.152.0.2.677281" title="CDS">
                <xsl:apply-templates select="row" xpath-default-namespace=""/>
            </dict>
        </plist>
    </xsl:template>

    <xsl:template match="row" xpath-default-namespace="">
        <key><xsl:value-of select="normalize-space(CodigoInterno)" /></key>
        <dict>
            <key>fullname</key>
            <string id="fullname"><xsl:value-of select="normalize-space(Descripcion)"/></string>
            <key>shortname</key>
            <string id="shortname"><xsl:value-of select="''"/></string>
            <key>procedurescheme</key>
            <integer>6</integer>
            <key>modality</key>
            <string id="modality"><xsl:value-of select="''"/></string>
            <key>category</key>
            <string id="category"><xsl:value-of select="concat(normalize-space(EspecialidadCodigo),'^^',normalize-space(EspecialidadDescripcion))"/></string>
            <key>codes</key>
            <array>
                <dict>
                    <key>code</key>
                    <string id="codestring"><xsl:value-of select="CodigoFonasa"/></string>
                    <key>scheme</key>
                    <integer>4</integer>
                    <key>qualifier</key>
                    <array/>
                </dict>
            </array>
        </dict>
    </xsl:template>    
</xsl:stylesheet>
