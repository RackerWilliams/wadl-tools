<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:wadl="http://wadl.dev.java.net/2009/02" xmlns="http://wadl.dev.java.net/2009/02" xmlns:xsd="http://www.w3.org/2001/XMLSchema" version="2.0">

    <xsl:param name="base-uri">
        <xsl:value-of select="normalize-space(//processing-instruction('base-uri')[1])"/>
    </xsl:param>

    <xsl:output indent="yes"/>

    <xsl:key name="methods" match="wadl:method[@id]" use="@id"/>

    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="wadl:method[parent::wadl:resource and starts-with(@href,'#')]">
        <xsl:apply-templates select="key('methods',substring-after(@href,'#'))" mode="copy">
            <xsl:with-param name="generated-id" select="generate-id(.)"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="wadl:method[parent::wadl:resource and not(starts-with(@href,'#')) and contains(@href,'#')]">
        <xsl:comment>Method included from external wadl: <xsl:value-of select="concat($base-uri, substring-before(@href,'#'))"/></xsl:comment>
        <xsl:apply-templates select="document(concat($base-uri, substring-before(@href,'#')))//wadl:method[@id = substring-after(current()/@href,'#')]" mode="copy">
            <xsl:with-param name="generated-id" select="generate-id(.)"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="wadl:method" mode="copy">
        <xsl:param name="generated-id"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="id">
                <xsl:value-of select="concat(@id, '-', $generated-id)"/>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="wadl:method[not(parent::wadl:resource)]"/>

</xsl:stylesheet>