<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:output method="xml" indent="yes"/>
    <xsl:include href="hl7-common.xsl"/>
    <xsl:template match="/hl7">
        <dataset>
            <DicomAttribute tag="00080005" vr="CS"><Value number="1">ISO_IR 100</Value></DicomAttribute>
            <xsl:apply-templates select="MSH"/>
            <xsl:apply-templates select="PID"/>
            <xsl:apply-templates select="PV1"/>
            <xsl:apply-templates select="ORC[1]"/>
            <xsl:apply-templates select="OBR[1]"/>
            <!-- Scheduled Procedure Step Sequence -->
            <DicomAttribute tag="00400100" vr="SQ">
                <xsl:apply-templates select="ORC" mode="sps"/>
            </DicomAttribute>
            <xsl:apply-templates select="ZDS"/>
            <xsl:apply-templates select="IPC"/>
        </dataset>
    </xsl:template>
    <xsl:template match="PV1">
        <!-- 08 Referring Physican Name = Patient Insurance Short Name (for Order  put it also in StudyID)-->
        <xsl:call-template name="cn2pnAttr">
            <xsl:with-param name="tag" select="'00080090'"/>
            <xsl:with-param name="cn" select="field[8]"/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="ORC[1]">
        
        
        <!-- Placer Issuer^Number ... not used yet -->
        <xsl:call-template name="ei2attr">
            <xsl:with-param name="tag" select="'00402016'"/>
            <xsl:with-param name="ei" select="field[2]"/>
        </xsl:call-template>
        
        
        <!-- 
            03 Filler Issuer^Number AN(^ANLocal|^^ANUniversal^ANType)
            
            en lugar de
            
            <xsl:call-template name="ei2attr">
                <xsl:with-param name="tag" select="'00402017'"/>
                <xsl:with-param name="ei" select="field[3]"/>
            </xsl:call-template>        
        -->
        <xsl:variable name="an" select="substring-before(ORC[3],'^')"/>        
        <xsl:if test="string-length($an) > 0">
            <DicomAttribute tag="'00080050'" vr="SH">
                <Value number="1">
                    <xsl:value-of select="$an"/>
                </Value>
            </DicomAttribute>
            <DicomAttribute tag="'00402017'" vr="LO">
                <Value number="1">
                    <xsl:value-of select="$an"/>
                </Value>
            </DicomAttribute>
            <xsl:variable name="ORC3234" select="substring-after(ORC[3],'^')"/>
            <xsl:variable name="anlocal" select="substring-before($ORC3234,'^')"/>        
            <xsl:choose>
                <xsl:when test="string-length($anlocal) > 0">
                    <DicomAttribute tag="'00080051'" vr="SQ">
                        <Item number="1">
                            <DicomAttribute tag="'00400031'" vr="UT">
                                <Value number="1">
                                    <xsl:value-of select="$anlocal"/>
                                </Value>
                            </DicomAttribute>
                        </Item>
                    </DicomAttribute>
                    <DicomAttribute tag="'00402027'" vr="SQ">
                        <Item number="1">
                            <DicomAttribute tag="'00400031'" vr="UT">
                                <Value number="1">
                                    <xsl:value-of select="$anlocal"/>
                                </Value>
                            </DicomAttribute>
                        </Item>
                    </DicomAttribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="ORC334" select="substring-after($ORC3234,'^')"/>
                    <xsl:variable name="anuniversal" select="substring-before($ORC334,'^')"/>        
                    <xsl:variable name="ORC34" select="substring-after($ORC334,'^')"/>
                    <xsl:variable name="antype" select="substring-before($ORC34,'^')"/>        
                    <xsl:if test="(string-length($anuniversal) > 0) and ( ($antype = 'DNS') or ($antype = 'EUI64') or ($antype = 'ISO') or ($antype = 'URI') or ($antype = 'UUID') or ($antype = 'X400') or ($antype = 'X500') )">
                        <DicomAttribute tag="'00080051'" vr="SQ">
                            <Item number="1">
                                <DicomAttribute tag="'00400032'" vr="UT">
                                    <Value number="1">
                                        <xsl:value-of select="$anuniversal"/>
                                    </Value>
                                </DicomAttribute>
                                <DicomAttribute tag="'00400033'" vr="CS">
                                    <Value number="1">
                                        <xsl:value-of select="$antype"/>
                                    </Value>
                                </DicomAttribute>
                            </Item>
                        </DicomAttribute>
                        <DicomAttribute tag="'00402027'" vr="SQ">
                            <Item number="1">
                                <DicomAttribute tag="'00400032'" vr="UT">
                                    <Value number="1">
                                        <xsl:value-of select="$anuniversal"/>
                                    </Value>
                                </DicomAttribute>
                                <DicomAttribute tag="'00400033'" vr="CS">
                                    <Value number="1">
                                        <xsl:value-of select="$antype"/>
                                    </Value>
                                </DicomAttribute>
                            </Item>
                        </DicomAttribute>
                    </xsl:if>                    
                </xsl:otherwise>
            </xsl:choose>            
        </xsl:if>
            
        <!-- 07_ Priority -->
        <xsl:call-template name="procedurePriority">
            <xsl:with-param name="priority" select="string(field[7]/component[5]/text())"/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template name="procedurePriority">
        <xsl:param name="priority"/>
        <xsl:if test="normalize-space($priority)">
            <DicomAttribute tag="00401003" vr="CS">
                <Value number="1">
                <xsl:choose>
                    <xsl:when test="$priority = 'S'">STAT</xsl:when>
                    <xsl:when test="$priority = 'A' or $priority = 'P' or $priority = 'C' ">HIGH</xsl:when>
                    <xsl:when test="$priority = 'R'">ROUTINE</xsl:when>
                    <xsl:when test="$priority = 'T'">MEDIUM</xsl:when>
                </xsl:choose>
                </Value>
            </DicomAttribute>
        </xsl:if>
    </xsl:template>
    <xsl:template match="OBR[1]">
        <!-- 18 Accession Number read from ORC-3
        <xsl:call-template name="attr">
            <xsl:with-param name="tag" select="'00080050'"/>
            <xsl:with-param name="vr" select="'SH'"/>
            <xsl:with-param name="val" select="string(field[18]/text())"/>
        </xsl:call-template>-->
        <!-- 13 RelevantCLinicalInfo, Medical Alerts -->
        <xsl:call-template name="attr">
            <xsl:with-param name="tag" select="'00102000'"/>
            <xsl:with-param name="vr" select="'LO'"/>
            <xsl:with-param name="val" select="substring(field[13]/text(),1,64)"/>
        </xsl:call-template>
        <!-- 16 Requesting Physician -->
        <xsl:call-template name="cn2pnAttr">
            <xsl:with-param name="tag" select="'00321032'"/>
            <xsl:with-param name="cn" select="field[16]"/>
        </xsl:call-template>
        <!-- 44 Requested Procedure Description -->
        <xsl:call-template name="attr">
            <xsl:with-param name="tag" select="'00321060'"/>
            <xsl:with-param name="vr" select="'LO'"/>
            <xsl:with-param name="val" select="field[44]/component[1]"/>
        </xsl:call-template>
        <!-- 44 Requested Procedure Code Sequence -->
        <xsl:call-template name="codeItem">
            <xsl:with-param name="sqtag" select="'00321064'"/>
            <xsl:with-param name="code" select="string(field[44]/text())"/>
            <xsl:with-param name="scheme" select="string(field[44]/component[2]/text())"/>
            <xsl:with-param name="meaning" select="substring(field[44]/component[1]/text(),1,64)"/>
        </xsl:call-template>
        <!-- 12 DangerCode / Patient State -->
        <xsl:call-template name="attr">
            <xsl:with-param name="tag" select="'00380500'"/>
            <xsl:with-param name="vr" select="'LO'"/>
            <xsl:with-param name="val" select="substring(field[12]/text(),1,64)"/>
        </xsl:call-template>
        <!-- 19 Requested Procedure ID -->
        <xsl:call-template name="attr">
            <xsl:with-param name="tag" select="'00401001'"/>
            <xsl:with-param name="vr" select="'SH'"/>
            <xsl:with-param name="val" select="string(field[19]/text())"/>
        </xsl:call-template>
        <!-- 30 TransportationMode Patient Transport Arrangements -->
        <xsl:call-template name="attr">
            <xsl:with-param name="tag" select="'00401004'"/>
            <xsl:with-param name="vr" select="'LO'"/>
            <xsl:with-param name="val" select="substring(field[30]/text(),1,64)"/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="ORC" mode="sps">
        <xsl:variable name="scheduledProcedureStepStatus">
        <xsl:choose>
            <xsl:when test="field[1]='NW' and field[5]='SC'">SCHEDULED</xsl:when>
            <xsl:when test="field[1]='CA' and field[5]='CA'">CANCELLED</xsl:when>
            <xsl:when test="field[1]='DC' and field[5]='CA'">DISCONTINUED</xsl:when>
            <xsl:when test="field[1]='XO' and field[5]='SC'">SCHEDULED</xsl:when>
            <xsl:when test="field[1]='XO' and field[5]='CM'">COMPLETED</xsl:when>
        </xsl:choose>
        </xsl:variable>
        <Item number="1">
            <!-- Scheduled Procedure Step Start Date/Time -->
            <xsl:call-template name="attrDATM">
                <xsl:with-param name="datag" select="'00400002'"/>
                <xsl:with-param name="tmtag" select="'00400003'"/>
                <xsl:with-param name="val" select="string(field[7]/component[3]/text())"/>
            </xsl:call-template>
            <!-- Scheduled Procedure Step Status -->
            <xsl:call-template name="attr">
                <xsl:with-param name="tag" select="'00400020'"/>
                <xsl:with-param name="vr" select="'CS'"/>
                <xsl:with-param name="val" select="$scheduledProcedureStepStatus"/>
            </xsl:call-template>
            <xsl:apply-templates select="following-sibling::OBR[1]" mode="sps"/>
        </Item>
    </xsl:template>
    <xsl:template match="OBR" mode="sps">
        <!-- 24 Modality -->
        <xsl:call-template name="attr">
            <xsl:with-param name="tag" select="'00080060'"/>
            <xsl:with-param name="vr" select="'CS'"/>
            <xsl:with-param name="val" select="string(field[24]/text())"/>
        </xsl:call-template>
        <!-- 34 Technician / Scheduled Performing Physican Name -->
        <xsl:call-template name="cn2pnAttr">
            <xsl:with-param name="tag" select="'00400006'"/>
            <xsl:with-param name="cn" select="field[34]"/>
            <xsl:with-param name="cn26" select="field[34]/subcomponent"/>
        </xsl:call-template>
        <!-- 04 Scheduled Procedure Step Description -->
        <xsl:call-template name="attr">
            <xsl:with-param name="tag" select="'00400007'"/>
            <xsl:with-param name="vr" select="'LO'"/>
            <xsl:with-param name="val" select="substring(field[4]/component[4]/text(),1,64)"/>
        </xsl:call-template>
        <!-- 04 Scheduled Protocol Code Sequence -->
        <xsl:call-template name="codeItem">
            <xsl:with-param name="sqtag" select="'00400008'"/>
            <xsl:with-param name="code" select="string(field[4]/component[3]/text())"/>
            <xsl:with-param name="scheme" select="string(field[4]/component[5]/text())"/>
            <xsl:with-param name="meaning" select="substring(field[4]/component[4]/text(),1,64)"/>
        </xsl:call-template>
        <!-- 20 Scheduled Procedure Step ID -->
        <xsl:call-template name="attr">
            <xsl:with-param name="tag" select="'00400009'"/>
            <xsl:with-param name="vr" select="'SH'"/>
            <xsl:with-param name="val" select="string(field[20]/text())"/>
        </xsl:call-template>
        
        <!-- opendicom additions -->
        
        <!-- 21 StationAETitle -->
        <xsl:call-template name="attr">
            <xsl:with-param name="tag" select="'00400001'"/>
            <xsl:with-param name="vr" select="'AE'"/>
            <xsl:with-param name="val" select="string(field[21]/text())"/>
        </xsl:call-template>
        <!-- 31 ReasonForStudy -->
        <xsl:call-template name="attr">
            <xsl:with-param name="tag" select="'00401002'"/>
            <xsl:with-param name="vr" select="'LO'"/>
            <xsl:with-param name="val" select="string(field[31]/text())"/>
        </xsl:call-template>
        <!-- 32 NameOfPhysiciansReadingStudy (we accept only one, though the standard allows many)-->
        <xsl:call-template name="cn2pnAttr">
            <xsl:with-param name="tag" select="'00081060'"/>
            <xsl:with-param name="cn" select="field[32]"/>
            <xsl:with-param name="cn26" select="field[32]/subcomponent"/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="ZDS">
        <!-- Study Instance UID -->
        <xsl:call-template name="attr">
            <xsl:with-param name="tag" select="'0020000D'"/>
            <xsl:with-param name="vr" select="'UI'"/>
            <xsl:with-param name="val" select="string(field[1]/text())"/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="IPC">
        <!-- Study Instance UID -->
        <xsl:call-template name="attr">
            <xsl:with-param name="tag" select="'0020000D'"/>
            <xsl:with-param name="vr" select="'UI'"/>
            <xsl:with-param name="val" select="string(field[3]/text())"/>
        </xsl:call-template>
    </xsl:template>
</xsl:stylesheet>
