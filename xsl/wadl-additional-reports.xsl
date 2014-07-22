<?xml version="1.0" encoding="UTF-8"?>

<!--
   Extends schematron checks with additonal reports.  These additional
   reports are not nessesarly errors, but rather hints that further
   error checking is needed.  We place these reports here to keep
   wadl.sch clean since these reports will always be treated like
   errors with tools such as Oxygen.
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:wadl="http://wadl.dev.java.net/2009/02"
    xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
    xmlns:rax="http://docs.rackspace.com/api"
    xmlns:xsdxt="http://docs.rackspacecloud.com/xsd-ext/v1.0"
    xmlns="http://docs.rackspace.com/api"
    exclude-result-prefixes="xs wadl"
    version="2.0">

    <!--
        Report an unparsed reference in wadl:include.
    -->
    <xsl:template match="wadl:include/@href" mode="additionalReports">
        <xsl:variable name="baseDocURI"
                      select="string-join(tokenize(base-uri(..),'/')[position() ne last()], '/')"/>
        <xsl:variable name="refURI" select="resolve-uri(.,base-uri(..))"/>
        <xsl:if test="unparsed-text-available($refURI)">
            <xsl:call-template name="report">
                <xsl:with-param name="test">unparsed-text-available($refURI)</xsl:with-param>
                <xsl:with-param name="role">unparsedReference</xsl:with-param>
                <xsl:with-param name="docRef" select="$refURI"/>
                <xsl:with-param name="node" select="."/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!--
        Report an include reference for code examples
    -->
    <xsl:template match="xsdxt:code/@href" mode="additionalReports">
        <xsl:variable name="baseDocURI"
                      select="string-join(tokenize(base-uri(..),'/')[position() ne last()], '/')"/>
        <xsl:variable name="refURI" select="resolve-uri(.,base-uri(..))"/>
        <xsl:if test="unparsed-text-available($refURI) or doc-available($refURI)">
            <xsl:call-template name="report">
                <xsl:with-param name="test">unparsed-text-available($refURI) or doc-available($refURI)</xsl:with-param>
                <xsl:with-param name="role">includeReference</xsl:with-param>
                <xsl:with-param name="docRef" select="$refURI"/>
                <xsl:with-param name="node" select="."/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!--
       A Simple XML reference
    -->
    <xsl:template match="xsd:import/@schemaLocation |
                         xsd:include/@schemaLocation |
                         xsl:import-schema/@schemaLocation |
                         rax:preprocess/@href |
                         xsl:import/@href |
                         xsl:include/@href" mode="additionalReports">
        <xsl:variable name="baseDocURI" select="string-join(tokenize(base-uri(..),'/')[position() ne last()], '/')"/>
        <xsl:variable name="refURI"     select="resolve-uri(.,base-uri(..))"/>
        <xsl:call-template name="checkXMLReference">
            <xsl:with-param name="docRef" select="$refURI"/>
        </xsl:call-template>
    </xsl:template>

    <!--
        A WADL reference
    -->
    <xsl:template name="WADLReference" match="wadl:link/@resource_type |
                                              wadl:method/@href |
                                              wadl:representation/@href |
                                              wadl:param/@href" mode="additionalReports">
        <xsl:param name="node" select="." as="node()"/>
        <xsl:param name="parent" select=".." as="node()"/>
        <xsl:param name="WADLRef" select="$node" as="xs:string"/>
        <xsl:variable name="doc" select="substring-before($WADLRef,'#')"/>
        <xsl:if test="string-length($doc) != 0">
            <xsl:variable name="baseDocURI" select="string-join(tokenize(base-uri($parent),'/')[position() ne last()], '/')"/>
            <xsl:variable name="refURI"     select="resolve-uri($doc,base-uri($parent))"/>
            <xsl:call-template name="checkXMLReference">
                <xsl:with-param name="docRef" select="$refURI"/>
                <xsl:with-param name="node" select="$node"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!--
       A list of WADL references
    -->
    <xsl:template match="wadl:resource/@type" mode="additionalReports">
        <xsl:variable name="node" as="node()" select="."/>
        <xsl:variable name="parent" as="node()" select=".."/>
        <xsl:variable name="refs" as="xs:string*" select="tokenize(normalize-space(.), ' ')"/>
        <xsl:for-each select="$refs">
            <xsl:call-template name="WADLReference">
                <xsl:with-param name="node" select="$node"/>
                <xsl:with-param name="parent" select="$parent"/>
                <xsl:with-param name="WADLRef" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!--
        Given an absolute URL to what should be an XML document, if
        unparsed text available returns true, then report that
        additional error checking is required.
    -->
    <xsl:template name="checkXMLReference">
        <xsl:param name="docRef" as="xs:anyURI"/>
        <xsl:param name="node" as="node()" select="."/>
        <xsl:if test="not(doc-available($docRef)) and unparsed-text-available($docRef)">
            <xsl:call-template name="report">
                <xsl:with-param name="test">unparsed-text-available($docRef)</xsl:with-param>
                <xsl:with-param name="role">checkReference</xsl:with-param>
                <xsl:with-param name="docRef" select="$docRef"/>
                <xsl:with-param name="node" select="$node"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template name="report">
        <xsl:param name="test" as="xs:string"/>
        <xsl:param name="role" as="xs:string"/>
        <xsl:param name="docRef" as="xs:string"/>
        <xsl:param name="node" as="node()"/>
        <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="{$test}" role="{$role}">
            <xsl:attribute name="location">
                <xsl:apply-templates select="$node" mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text><xsl:value-of select="$docRef"/></svrl:text>
        </svrl:successful-report>
    </xsl:template>
</xsl:stylesheet>
