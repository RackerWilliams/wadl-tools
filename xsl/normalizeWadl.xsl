<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:wadl="http://wadl.dev.java.net/2009/02" 
    xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
    version="2.0">

    <xsl:output indent="yes"/>

    <xsl:template match="/">
        <xsl:apply-templates/>
        <!-- Here we store the base-uri of this file so we can use it to find files relative to this file later -->
        <xsl:processing-instruction name="base-uri"><xsl:value-of select="replace(base-uri(.),'(.*/).*\.wadl', '$1')"/></xsl:processing-instruction>
    </xsl:template>

    <xsl:template match="* | text()|comment()|processing-instruction() | @*">
        <xsl:param name="stack"/>
        <xsl:copy>
            <xsl:apply-templates select="* | text()|comment()|processing-instruction() | @*">
                <xsl:with-param name="stack" select="$stack"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="wadl:include">
        <xsl:param name="stack"/>
        <xsl:message>Writing out xsd: <xsl:value-of select="concat(replace(base-uri(.),'(.*/).*\.wadl', '$1'), generate-id(),'.xsd')"/></xsl:message>
        <xsl:result-document href="{concat(replace(base-uri(.),'(.*/).*\.wadl', '$1'),generate-id(),'.xsd')}">
            <xsl:comment>Source (wadl:include): <xsl:value-of select="base-uri(document(@href))"/></xsl:comment>
            <xsl:apply-templates select="document(@href)/*">
                <xsl:with-param name="stack">
                    <xsl:value-of select="concat($stack, ' ', base-uri(document(@href)))"/>
                </xsl:with-param>
            </xsl:apply-templates>
            <xsl:comment>End source: <xsl:value-of select="base-uri(document(@href))"/></xsl:comment>
            <xsl:text>            
            </xsl:text>
        </xsl:result-document>        

        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>   
        </xsl:copy>
        
    </xsl:template>
    
    <xsl:template match="xsd:include">
        <xsl:param name="stack"/>
        <xsl:choose>
            <xsl:when test="contains($stack,base-uri(document(@schemaLocation)))">
                <xsl:message>[INFO] Recursion detected, skipping: <xsl:value-of select="base-uri(document(@schemaLocation))"/></xsl:message>
            </xsl:when>
            <xsl:otherwise>
               <!-- <xsl:message><xsl:value-of select="concat($stack, ' ', base-uri(document(@schemaLocation)))"/></xsl:message>-->
                <xsl:comment>Source (xsd:include): <xsl:value-of select="base-uri(document(@schemaLocation))"/></xsl:comment>
                <xsl:apply-templates select="document(@schemaLocation,.)/xsd:schema/*">
                    <xsl:with-param name="stack">
                        <xsl:value-of select="concat($stack, ' ', base-uri(document(@schemaLocation)))"/>
                    </xsl:with-param>
                </xsl:apply-templates>
                <xsl:comment>End source: <xsl:value-of select="base-uri(document(@schemaLocation))"/></xsl:comment><xsl:text>            
        </xsl:text>        
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
<!--    <xsl:template match="xsd:import">
        <xsl:param name="stack"/>
        <xsl:apply-templates select="document(@schemaLocation,.)/xsd:schema">
            <xsl:with-param name="stack">
                <xsl:value-of select="concat($stack, ' ', base-uri(document(@schemaLocation)))"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>-->

</xsl:stylesheet>