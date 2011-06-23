<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:wadl="http://wadl.dev.java.net/2009/02" xmlns:xsd="http://www.w3.org/2001/XMLSchema" version="2.0">

    <xsl:output indent="yes"/>

    <xsl:variable name="wadl-uri" select="replace(base-uri(.),'(.*/).*\.wadl', '$1')"/>

    <xsl:variable name="catalog-wadl-xsds">
        <xsl:apply-templates mode="wadl-xsds"/>
    </xsl:variable>

    <xsl:variable name="catalog-imported-xsds">
        <xsl:for-each-group select="$catalog-wadl-xsds//xsd" group-by="@location">
            <xsl:apply-templates select="document(current-grouping-key())//xsd:import|document(current-grouping-key())//xsd:include" mode="catalog-imported-xsds"/>
        </xsl:for-each-group>
    </xsl:variable>

    <xsl:variable name="catalog">
        <xsl:for-each-group select="$catalog-wadl-xsds//*|$catalog-imported-xsds//*" group-by="@location">
            <xsd location="{current-grouping-key()}" name="{concat('xsd-',position(),'.xsd')}"/>
        </xsl:for-each-group>
    </xsl:variable>

    <xsl:template match="/">

        <xsl:for-each select="$catalog/xsd">
            <xsl:message>[INFO] Writing: <xsl:value-of select="@location"/> as <xsl:value-of select="@name"/></xsl:message>
            <xsl:result-document href="{concat('normalized/',@name)}">
                <xsl:comment>Original xsd: <xsl:value-of select="@location"/></xsl:comment>
                <xsl:apply-templates select="document(@location,.)/*" mode="flatten-xsd"/>
            </xsl:result-document>
        </xsl:for-each>

        <!-- Here we store the base-uri of this file so we can use it to find files relative to this file later -->
        <xsl:processing-instruction name="base-uri"><xsl:value-of select="replace(base-uri(.),'(.*/).*\.wadl', '$1')"/></xsl:processing-instruction>
        <xsl:apply-templates mode="process-wadl"/>
    </xsl:template>


    <xsl:template match="node() | @*" mode="process-wadl">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="process-wadl"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="wadl:grammars" mode="process-wadl">
        <wadl:grammars>
            <xsl:for-each select="$catalog-wadl-xsds//xsd">
                <xsl:comment>Original xsd: <xsl:value-of select="@location"/></xsl:comment>
                <wadl:include>
                    <xsl:attribute name="href">
                        <xsl:value-of select="$catalog//xsd[@location = current()/@location]/@name"/>
                    </xsl:attribute>
                </wadl:include>
            </xsl:for-each>
        </wadl:grammars>
    </xsl:template>

    <!-- Flatten xsds -->

    <xsl:template match="* | text()|comment()|processing-instruction() | @*" mode="flatten-xsd">
        <xsl:param name="stack"/>
        <xsl:copy>
            <xsl:apply-templates select="* | text()|comment()|processing-instruction() | @*" mode="flatten-xsd">
                <xsl:with-param name="stack" select="$stack"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xsd:import" mode="flatten-xsd">
        <xsl:variable name="schemaLocation" select="replace(concat(replace(base-uri(.),'(.*/).*\.xsd', '$1'),@schemaLocation),'/\./','/')"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="schemaLocation">
                <xsl:value-of select="$catalog//xsd[@location = $schemaLocation]/@name"/>
                <!-- todo: look up new schema name -->
            </xsl:attribute>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xsd:include" mode="flatten-xsd">
        <xsl:param name="stack"/>
        <xsl:choose>
            <xsl:when test="contains($stack,base-uri(document(@schemaLocation)))">
                <xsl:message>[INFO] Recursion detected, skipping: <xsl:value-of select="base-uri(document(@schemaLocation))"/></xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <!-- <xsl:message><xsl:value-of select="concat($stack, ' ', base-uri(document(@schemaLocation)))"/></xsl:message>-->
                <xsl:comment>Source (xsd:include): <xsl:value-of select="base-uri(document(@schemaLocation))"/></xsl:comment>
                <xsl:apply-templates select="document(@schemaLocation,.)/xsd:schema/*" mode="flatten-xsd">
                    <xsl:with-param name="stack">
                        <xsl:value-of select="concat($stack, ' ', base-uri(document(@schemaLocation)))"/>
                    </xsl:with-param>
                </xsl:apply-templates>
                <xsl:comment>End source: <xsl:value-of select="base-uri(document(@schemaLocation))"/></xsl:comment>
                <xsl:text>            
        </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Collect list of xsds included in the main wadl or in any included wadls   -->

    <xsl:template match="* | text()|comment()|processing-instruction() | @*" mode="wadl-xsds">
        <xsl:apply-templates select="* | text()|comment()|processing-instruction() | @*" mode="wadl-xsds"/>
    </xsl:template>

    <xsl:template match="wadl:include" mode="wadl-xsds">
        <xsd location="{concat($wadl-uri,@href)}"/>
    </xsl:template>

    <xsl:template match="@href[not(substring-before(.,'#') = '')]" mode="wadl-xsds">
        <xsl:apply-templates select="document(substring-before(.,'#'),.)/*" mode="wadl-xsds"/>
    </xsl:template>

    <!-- End section -->

    <!--  Find xsds imported into xsd or into any included xsd  -->

    <xsl:template match="xsd:include|xsd:import" mode="catalog-imported-xsds">
        <xsl:param name="stack"/>
        <xsl:if test="self::xsd:import">
            <xsd type="imported" location="{replace(concat(replace(base-uri(.),'(.*/).*\.xsd', '$1'),@schemaLocation),'/\./','/')}"/>
        </xsl:if>
        <xsl:if test="not(contains($stack,base-uri(.)))">
            <xsl:apply-templates select="document(replace(@schemaLocation,'^\./',''),.)//xsd:import|document(replace(@schemaLocation,'^\./',''),.)//xsd:include" mode="catalog-imported-xsds">
                <xsl:with-param name="stack">
                    <xsl:value-of select="concat($stack, ' ',base-uri(.))"/>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- Doesn't work. Gives "The context item is undefined" error:   -->
    <!--<xsl:function xmlns:f="http://www.rackspace.com/api" name="f:getImports" as="element(*)">
        <xsl:param name="schemaDocument" as="element(xsd:schema)"/>
        <xsl:sequence select="
            xsd:import | 
            (for $i in $schemaDocument//xsd:include return
            f:getImports(document($i/@schemaLocation)/xsd:schema))"/>
    </xsl:function>-->

</xsl:stylesheet>