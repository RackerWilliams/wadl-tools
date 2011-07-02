<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:wadl="http://wadl.dev.java.net/2009/02" xmlns="http://wadl.dev.java.net/2009/02" xmlns:xsd="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs wadl" version="2.0">

    <xsl:param name="base-uri">
        <xsl:value-of select="normalize-space(//processing-instruction('base-uri')[1])"/>
    </xsl:param>

    <!-- Need this to re-establish context within for-each -->
    <xsl:variable name="root" select="/"/>

    <xsl:output indent="yes"/>

    <xsl:key name="ids" match="wadl:*[@id]" use="@id"/>

    <xsl:variable name="processed">
        <xsl:apply-templates/>
    </xsl:variable>

    <xsl:template match="/">
        <!-- Now we prune the generated id that is appended to all ids where we can do it safely -->
        <xsl:apply-templates select="$processed" mode="strip-ids"/>
    </xsl:template>

    <xsl:template match="node() | @*" mode="strip-ids">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="strip-ids"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@xml:id]" mode="strip-ids">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="strip-ids"/>
            <xsl:choose>
                <xsl:when test="//*[
                    not(parent::wadl:application) and 
                    not(generate-id(.) = generate-id(current()) ) and 
                    @xml:id = current()/@xml:id]">
                    <xsl:message>[INFO] Modifying repeated id: <xsl:value-of select="@xml:id"/> to <xsl:value-of select="@id"/></xsl:message>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="id">
                        <xsl:value-of select="@xml:id"/>
                    </xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates mode="strip-ids"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="wadl:method[parent::wadl:application]|wadl:param[parent::wadl:application]|wadl:representation[parent::wadl:application]|wadl:resource_type" mode="strip-ids"/>

    <xsl:template match="@xml:id" mode="strip-ids"/>

    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="wadl:method[@href]|wadl:param[@href]|wadl:representation[@href]">
        <xsl:choose>
            <xsl:when test="starts-with(@href,'#')">
                <xsl:apply-templates select="key('ids',substring-after(@href,'#'))" mode="copy">
                    <xsl:with-param name="generated-id" select="generate-id(.)"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment><xsl:value-of select="local-name(.)"/> included from external wadl: <xsl:value-of select="concat($base-uri, substring-before(@href,'#'))"/></xsl:comment>
                <xsl:variable name="doc">
                    <xsl:choose>
                        <xsl:when test="starts-with(normalize-space(@href),'http://') or starts-with(normalize-space(@href),'file://')">
                            <xsl:value-of select="substring-before(normalize-space(@href),'#')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat($base-uri, substring-before(normalize-space(@href),'#'))"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="included-wadl">
                    <xsl:apply-templates select="document($doc,.)/*"/>
                </xsl:variable>
                <xsl:apply-templates select="$included-wadl//wadl:*[@id = substring-after(current()/@href,'#')]" mode="copy">
                    <xsl:with-param name="generated-id" select="generate-id(.)"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="wadl:method|wadl:param|wadl:representation" mode="copy">
        <xsl:param name="generated-id"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="xml:id" select="@id"/>
            <xsl:attribute name="id">
                <xsl:value-of select="concat(@id, '-', $generated-id)"/>
            </xsl:attribute>
            <xsl:apply-templates select="*|comment()|processing-instruction()|text()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="wadl:resource[@type]">
        <resource>
            <xsl:copy-of select="@*[name() != 'type']"/>
            <xsl:for-each select="tokenize(normalize-space(@type),' ')">
                <xsl:variable name="id" select="substring-after(normalize-space(.),'#')"/>
                <xsl:variable name="doc">
                    <xsl:choose>
                        <xsl:when test="starts-with(normalize-space(.),'http://') or starts-with(normalize-space(.),'file://')">
                            <xsl:value-of select="substring-before(normalize-space(.),'#')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat($base-uri, substring-before(normalize-space(.),'#'))"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="starts-with(normalize-space(.),'#')">
                        <xsl:for-each select="$root/*[1]">
                            <xsl:apply-templates select="key('ids',$id)/*"/>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="included-wadl">
                            <xsl:apply-templates select="document($doc,$root)/*"/>
                        </xsl:variable>
                        <xsl:apply-templates select="$included-wadl//*[@id = $id]/*"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
            <xsl:apply-templates/>
        </resource>
    </xsl:template>

</xsl:stylesheet>