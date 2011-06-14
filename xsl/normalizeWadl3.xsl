<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:wadl="http://wadl.dev.java.net/2009/02" 
    xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
    version="2.0">
                
    <xsl:output indent="yes"/>
    
    <xsl:param name="format"/>
    
    <xsl:template match="/">
        <xsl:message>
            format=<xsl:value-of select="$format"/>
        </xsl:message>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="processing-instruction('base-uri')"/>
        
</xsl:stylesheet>