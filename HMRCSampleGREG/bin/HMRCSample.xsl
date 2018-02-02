<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="xs xdt err fn ds chk" 
    version="2.0" 
    xmlns:err="http://www.w3.org/2005/xqt-errors" 
    xmlns:fn="http://www.w3.org/2005/xpath-functions" 
    xmlns:xdt="http://www.w3.org/2005/xpath-datatypes" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tns="http://uk.gov.hmrc/Canon" 
    xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
    xmlns:ds="http://ws.wso2.org/dataservice" 
    xmlns:chk="http://chakray.com"
    >
    
    <xsl:output indent="yes" method="xml"/>

    <xsl:param name="City"/>

    <xsl:template match="/tns:Sample/tns:Town">
        <tns:Weather>
            <tns:Summary><xsl:value-of select="$City" /> - Warm, Dry and Sunny</tns:Summary>
        </tns:Weather>
    </xsl:template>
</xsl:stylesheet>
