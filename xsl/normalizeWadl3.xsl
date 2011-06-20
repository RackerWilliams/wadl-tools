<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:wadl="http://wadl.dev.java.net/2009/02" 
    xmlns="http://wadl.dev.java.net/2009/02"     
    xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
    exclude-result-prefixes="xsd wadl xs xsl"
    version="2.0">

    <xsl:output indent="yes"/>

    <xsl:param name="format">path-format</xsl:param>
    <!-- path or tree -->

    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="$format = 'path-format' or $format = '-format'">
                <xsl:apply-templates mode="path-format"/>
            </xsl:when>
            <xsl:when test="$format = 'tree-format'">
                <xsl:apply-templates mode="tree-format"/>               
            </xsl:when>
            <xsl:otherwise>
                  <xsl:message terminate="yes">Invalid format! <xsl:value-of select="$format"/></xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Begin tree-format templates   -->

    <xsl:template match="node() | @*" mode="tree-format">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="tree-format"/>
        </xsl:copy>
    </xsl:template>
    

    <!-- Begin path-format templates -->

    <xsl:template match="node() | @*" mode="path-format">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="path-format"/>
        </xsl:copy>
    </xsl:template>


    <xsl:template match="node() | @*" mode="copy">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="copy"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="wadl:method" mode="path-format"/>

    <xsl:template match="wadl:resource[child::wadl:resource]" mode="path-format">
        <xsl:apply-templates select="wadl:resource" mode="path-format"/>
    </xsl:template>

    <xsl:template match="wadl:resource[not(child::wadl:resource)]" mode="path-format">
        <resource>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="path">
                <xsl:for-each select="ancestor-or-self::wadl:resource">
                    <xsl:sort order="ascending" select="position()"/>
                    <xsl:value-of select="@path"/>
                    <xsl:if test="not(position() = last())">/</xsl:if>
                </xsl:for-each>
            </xsl:attribute>
            <xsl:apply-templates select="wadl:param" mode="copy"/>
            <xsl:apply-templates select="wadl:method" mode="copy"/>
        </resource>
    </xsl:template>

    <xsl:template match="processing-instruction('base-uri')" mode="path-format"/>

</xsl:stylesheet>