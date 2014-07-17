<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
    xmlns="http://purl.oclc.org/dsdl/svrl"
    exclude-result-prefixes="xs"
    version="2.0">

    <xsl:param name="systemIds" as="xs:string*"/>

    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="svrl:schematron-output">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
            <xsl:for-each select="$systemIds">
                <svrl:successful-report role="includeReference">
                    <svrl:text><xsl:value-of select="."/></svrl:text>
                </svrl:successful-report>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="svrl:failed-assert">
        <xsl:variable name="msg" as="xs:string">
            <xsl:choose>
                <xsl:when test="preceding-sibling::svrl:active-pattern">
                    <xsl:value-of select="concat(preceding-sibling::svrl:active-pattern[1]/@document,' : ',svrl:text)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="svrl:text"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:message><xsl:value-of select="normalize-space(concat('[SE] ',$msg))"/></xsl:message>
    </xsl:template>

</xsl:stylesheet>
