<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:wadl="http://wadl.dev.java.net/2009/02"
    xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx"
    xmlns:db="http://docbook.org/ns/docbook"
    xmlns:xsdxt="http://docs.rackspacecloud.com/xsd-ext/v1.0"
    exclude-result-prefixes="xs wadl db xsdxt"    
    version="2.0" 
    xpath-default-namespace="http://wadl.dev.java.net/2009/02">
    
    
    <xsl:output indent="yes"/>
    <!-- 
        TODOs:
            mode="xml2markdown"
            handle enumerations in params (grab from xsd)
                        
            Pipeline: 
                1. Run normalize.xsl in path format
                2. Run wadl2apiary-jsonx xsl
                3. Run jsonx2json xsl
    -->
    
    <xsl:param name="blueprint-version">1.0</xsl:param>
    
    <!--
        Taking the list of characters to escape from:
        http://stackoverflow.com/questions/983451/where-can-i-find-a-list-of-escape-characters-required-for-my-json-ajax-return-ty 
    -->
    <xsl:variable name="regexp">\\|\n|\r|\t|"|/</xsl:variable>
    <xsl:variable name="json-escapes">
        <esc j="\\" x="\"/>
        <esc j="\n" x="&#10;"/>
        <esc j="\&#34;" x="&#34;"/><!-- " -->
        <esc j="\t" x="&#09;"/>
        <esc j="\r" x="&#13;"/>     
        <esc j="\/"  x="/"/>
    </xsl:variable>
    
    <xsl:key name="json-escapes" match="*" use="@x"/>
    
    <xsl:template match="text()" mode="escape-json">
        <xsl:analyze-string select="." regex="{$regexp}">
            <xsl:matching-substring>
                <!-- This key() amounts to: $json-escapes/*[current() = @x]/@j 
                     but perhaps is a little faster. -->
                <xsl:value-of select="key('json-escapes', . ,$json-escapes)/@j"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
    <xsl:template match="application">
        <json:object
            xsi:schemaLocation="http://www.datapower.com/schemas/json jsonx.xsd"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx">
            <json:string name="_version"><xsl:value-of select="$blueprint-version"/></json:string>
            <json:object name="metadata">
                <json:object name="FORMAT">
                    <json:string name="value">1A</json:string>
                </json:object>
            </json:object>
            <json:string name="name"><xsl:value-of select="resources/doc/@title"/></json:string>
            <json:string name="description"><xsl:apply-templates select="resources/doc" mode="xml2markdown"/></json:string>
            <!-- TODO: Support some kind of grouping mechanism. Maybe an attr on each resource that assigns it to a group? -->
            <json:array name="resourceGroups">
                <json:object>
                    <json:string name="name">All Methods</json:string>
                    <json:string name="description"/>
                    <json:array name="resources">
                        <xsl:apply-templates select=".//resource[ancestor::resources and child::method]"/>
                    </json:array>
                </json:object>
            </json:array>
        </json:object>
    </xsl:template>    
        
    <xsl:template match="resource">           
        <json:object>
            <json:string name="name"><xsl:value-of select="normalize-space((doc/@title)[1])"/></json:string>
            <json:string name="description"><xsl:apply-templates select="doc" mode="xml2markdown"/></json:string>
            <json:string name="uriTemplate"><xsl:value-of select="if(normalize-space(@path) = '') then '/' else @path"/><xsl:for-each select=".//param[@style = 'query']"><xsl:if test="position() = 1">{?</xsl:if><xsl:value-of select="@name"/><xsl:if test="@repeating = 'true'">*</xsl:if><xsl:choose><xsl:when test="not(position() = last())">,</xsl:when><xsl:otherwise>}</xsl:otherwise></xsl:choose></xsl:for-each>
            </json:string>
            <json:object name="parameters">
                <xsl:apply-templates select="param[@style = 'template']"/>
            </json:object>
            <json:object name="headers">
                <xsl:apply-templates select="param[@style = 'header']"/>
            </json:object>
            <json:array name="actions">
                <xsl:apply-templates select="method"/>
            </json:array>
        </json:object>
    </xsl:template>
        
    <xsl:template match="param">
        <json:object name="{@name}">
            <json:string name="description"><xsl:apply-templates select="doc" mode="xml2markdown"/></json:string>
            <json:string name="type"><xsl:value-of select="@type"/></json:string>
            <json:string name="required"><xsl:value-of select="@required"/></json:string>
            <json:string name="default"><xsl:value-of select="@default"/></json:string>
            <json:string name="example"></json:string>
            <json:array name="values">
                <!-- TODO -->
                <xsl:apply-templates select="option"/>
            </json:array>            
        </json:object>
    </xsl:template>
    
    <xsl:template match="option">
        <json:string name="{@value}"/>
    </xsl:template>

    <xsl:template match="method">
        <json:object>
            <json:string name="method"><xsl:value-of select="normalize-space(@name)"/></json:string>
            <json:string name="name"><xsl:value-of select="normalize-space((doc/@title)[1])"/></json:string>
            <json:string name="description"><xsl:apply-templates select="doc" mode="xml2markdown"></xsl:apply-templates></json:string>
            <json:object name="parameters">
                <xsl:apply-templates select="param[@style = 'query']|ancestor::resource/param[@style = 'query']"/>
            </json:object>
            <json:object name="headers">
                <xsl:apply-templates select="param[@style = 'header']"/>
            </json:object>
            <json:array name="examples">
                <json:object>
                    <json:string name="name"></json:string>
                    <json:string name="description"></json:string>
                    <json:array name="requests">
                        <xsl:apply-templates select="request//xsdxt:sample|request[not(xsdxt:sample)]//xsdxt:code|request//db:example"/>
                        <xsl:apply-templates select="request/representation[not(.//xsdxt:code) and not(.//db:example)]"/>
                    </json:array>
                    <json:array name="responses">
                        <xsl:apply-templates select="response//xsdxt:sample|response[not(xsdxt:sample)]//xsdxt:code|response//db:example"/> 
                        <xsl:apply-templates select="response/representation[not(.//xsdxt:code) and not(.//db:example)]"/>
                    </json:array>
                </json:object>
            </json:array>
        </json:object>
    </xsl:template>
    
    <xsl:template match="representation">
        <json:object>
            <json:string name="name"><xsl:value-of select="if(parent::response/@status) then parent::response/@status 
                else if(wadl:doc/@title) then (wadl:doc/@title)[1]
                else if(ancestor::method/@title) then concat(ancestor::method/@title, 'TODO XML or JSON Request')
                else ''"/></json:string><!-- FIXME -->
            <json:string name="description"><xsl:apply-templates select="wadl:doc/node()" mode="xml2markdown"/></json:string>
            <json:object name="headers">
                <json:object name="Content-Type">
                    <json:string name="value"><xsl:value-of select="@mediaType"/></json:string>
                </json:object>
            </json:object>
            <json:string name="body"/>
            <json:string name="schema"/>
        </json:object>
    </xsl:template>
        
    <xsl:template match="xsdxt:sample|xsdxt:code|db:example">
        <json:object>
            <json:string name="name"><xsl:value-of select="if(ancestor::response/@status) then ancestor::response/@status 
                                                            else 
                                                             if(./xsdxt:code/@title) then ./xsdxt:code/@title else 
                                                             if(@title) then @title else 
                                                             if(ancestor::method/@title) then concat(ancestor::method/@title, 'TODO XML or JSON Request')
                                                            else ''"/></json:string><!-- FIXME -->
            <json:string name="description"><!-- FIXME --></json:string>
            <json:object name="headers"><!-- TODO -->
                <json:object name="Content-Type">
                    <json:string name="value"><xsl:value-of select="ancestor::representation/@mediaType"/></json:string>
                </json:object>
            </json:object>
            <json:string name="body">
                <xsl:apply-templates select=".//db:programlisting/node()" mode="escape-json"/>
            </json:string>
            <json:string name="schema"><!-- ??? --></json:string>   
        </json:object>
    </xsl:template>
    
    <xsl:template match="doc" mode="xml2markdown"><!-- TODO FIXME --><xsl:apply-templates select="node()" mode="escape-json"/></xsl:template>
   
</xsl:stylesheet>
