<?xml version="1.0" encoding="UTF-8"?>
<!-- 

This XSLT flattens or expands the path in the path attributes of the resource elements in the wadl. 

-->
<!--
   Copyright 2011 Rackspace US, Inc.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:wadl="http://wadl.dev.java.net/2009/02" xmlns="http://wadl.dev.java.net/2009/02" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:raxf="http://docs.rackspace.com/functions" xmlns:rax="http://docs.rackspace.com/api" exclude-result-prefixes="wadl xsd raxf rax" version="2.0">

    <xsl:output indent="yes"/>

    <xsl:param name="resource_types">keep</xsl:param>

    <xsl:param name="format">-format</xsl:param>
    <!-- path or tree -->
    
    <xsl:variable name="paths-tokenized">
        <xsl:apply-templates select="$normalizeWadl2" mode="tokenize-paths"/>
    </xsl:variable>

    <!-- keep-format mode means we don't touch the formatting -->
    <xsl:template match="node() | @*" mode="keep-format">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="keep-format"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@path[(starts-with(.,'/') or ends-with(.,'/')) and not(. = '/')]" mode="keep-format">
        <xsl:attribute name="path"><xsl:value-of select="replace(replace(.,'^(.+)/$','$1'),'^/(.+)$','$1')"/></xsl:attribute>
    </xsl:template>

    <!--  prune-params mode: one final pass in tree-format mode where we prune redundant params  -->
    <xsl:template match="node() | @*" mode="prune-params">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="prune-params"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="wadl:resource_type|wadl:link[@resource_type]" mode="keep-format tree-format path-format">
      <xsl:if test="$resource_types = 'keep'">
	<xsl:copy>
	  <xsl:apply-templates select="@*|node()" mode="#current"/>
	</xsl:copy>      
      </xsl:if>
    </xsl:template>    

    <xsl:template 
        match="wadl:param" 
        mode="prune-params">
        <xsl:variable name="name" select="@name"/>
        <xsl:choose>
            <xsl:when test="parent::wadl:resource[ancestor::wadl:resource/wadl:param[(@style = 'template' or @style = 'header' or @style='matrix') and @name = $name]]"/>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="prune-params"/>
                </xsl:copy>
            </xsl:otherwise>                
        </xsl:choose>
    </xsl:template>

    <!-- Begin tree-format templates   -->

    <xsl:template match="node() | @*" mode="tree-format">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="tree-format"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="wadl:resources" mode="tree-format">
        <resources>
            <xsl:copy-of select="@*"/>
            <xsl:call-template name="group">
                <xsl:with-param name="token-number" select="1"/>
                <xsl:with-param name="resources" select="wadl:resource"/>
            </xsl:call-template>
        </resources>
    </xsl:template>

    <xsl:template match="wadl:resource" mode="tree-format">
      <xsl:param name="token-number">1</xsl:param>
      <xsl:param name="resources"/>
      <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:call-template name="group">
                <xsl:with-param name="token-number" select="$token-number + 1"/>
                <xsl:with-param name="resources" select="wadl:resource"/>
            </xsl:call-template>
	    <xsl:apply-templates select="*" mode="tree-format">
	      <xsl:with-param name="path" select="@path"/>	      
	    </xsl:apply-templates>
      </xsl:copy>
    </xsl:template>

    <xsl:template match="wadl:param" mode="tree-format">
      <xsl:param name="path"/>
      <xsl:variable name="opencurly">{</xsl:variable>
      <xsl:variable name="closecurly">}</xsl:variable>
      <xsl:choose>
	<xsl:when test="@style = 'template' and 
			not(concat($opencurly,@name,$closecurly) = $path )">
 	</xsl:when>
	<xsl:otherwise>
	  <xsl:copy  copy-namespaces="yes">
        <xsl:if test="@type and not(contains(@type,':'))">
	      <xsl:namespace name="" select="namespace-uri-from-QName(resolve-QName(@type, .))"/> 
        </xsl:if>
	    <xsl:apply-templates select="node() | @*[not(name(.) = 'rax:id')]" mode="tree-format"/>
	  </xsl:copy>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:template>

    <xsl:template name="group">
        <xsl:param name="token-number"/>
        <xsl:param name="resources"/>
        <xsl:for-each-group select="$resources" group-by="wadl:tokens/wadl:token[$token-number]">
            <resource path="{current-grouping-key()}">
                <!-- Copy all attributes except for special cases: @path, @id, and @rax:roles -->
                <xsl:copy-of select="self::wadl:resource/@*[not(local-name(.) = 'path') and not(local-name(.) = 'id') and not(name(.) = 'rax:roles')]"/>
                <xsl:choose>
                    <xsl:when test="@id and not($token-number = 1)"><xsl:attribute name="id" select="concat(@id,'-', $token-number )"/></xsl:when>
                    <xsl:when test="@id"><xsl:attribute name="id" select="@id"/></xsl:when>	
                    <xsl:when test="count(wadl:tokens/wadl:token) = $token-number"><xsl:attribute name="id" select="raxf:generate-resource-id(.)"/></xsl:when>
                </xsl:choose>
                <xsl:if test="count(wadl:tokens/wadl:token) = $token-number">
                <!-- Only copy @rax:roles if we're on the leaf of the tree of wadl:resource elements -->
                    <xsl:copy-of select="@rax:roles"/>
                </xsl:if>
                <xsl:apply-templates select="wadl:param[@style = 'template']" mode="tree-format">
                    <xsl:with-param name="path" select="current-grouping-key()"/>
                </xsl:apply-templates>	      
                <xsl:if test="count(wadl:tokens/wadl:token) = $token-number">
                    <xsl:apply-templates select="current-group()[count(wadl:tokens/wadl:token) = $token-number]/*[not(self::wadl:resource) and 
                                                                                                                  not(self::wadl:param[@style = 'template']) and
                                                                                                                  namespace-uri() = 'http://wadl.dev.java.net/2009/02']" mode="tree-format"/>    
                    <xsl:call-template name="group">
                        <xsl:with-param name="token-number" select="1"/>
                        <xsl:with-param name="resources" select="wadl:resource"/>
                    </xsl:call-template>
                </xsl:if>
                <xsl:call-template name="group">
                    <xsl:with-param name="token-number" select="$token-number + 1"/>
                    <xsl:with-param name="resources" select="current-group()"/>
                </xsl:call-template>
                <xsl:apply-templates select="*[not(namespace-uri() = 'http://wadl.dev.java.net/2009/02')]" mode="tree-format">
                    <xsl:with-param name="path" select="current-grouping-key()"/>
                </xsl:apply-templates>	      
            </resource>
        </xsl:for-each-group>
    </xsl:template>

    <xsl:template match="wadl:tokens" mode="tree-format">
      <xsl:if test="$debug != 0">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="tree-format"/>
        </xsl:copy>
      </xsl:if>
    </xsl:template>

    <xsl:template match="node() | @*" mode="tokenize-paths">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="tokenize-paths"/>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:template match="wadl:resources" mode="tokenize-paths">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="tokenize-paths">
                <!-- Sort so that we don't miss any methods when a/b comes before a -->
                <xsl:sort select="@path"/> 
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="wadl:resource" mode="tokenize-paths">
        <resource>
            <xsl:copy-of select="@*"/>
            <tokens>
	      <xsl:choose>
		<xsl:when test="@path = '/'">
		  <token>/</token>
		</xsl:when>
		<xsl:otherwise>
		  <xsl:for-each select="tokenize(replace(replace(@path,'^(.+)/$','$1'),'^/(.+)$','$1'),'/')">
                    <token>
		      <xsl:value-of select="."/>
                    </token>
		  </xsl:for-each>
		</xsl:otherwise>
	      </xsl:choose>
            </tokens>
            <xsl:apply-templates select="node()" mode="tokenize-paths">
                <!-- Sort so that we don't miss any methods when a/b comes before a -->
                <xsl:sort select="@path"/> 
            </xsl:apply-templates>
        </resource>
    </xsl:template>

    <!-- Begin path-format templates -->

    <xsl:template match="node() | @*" mode="path-format">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="path-format"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="node() | @*" mode="copy">
        <xsl:param name="rax-roles"/>
        <xsl:variable name="rax-roles-method">
            <xsl:choose>
                <xsl:when test="distinct-values(tokenize(normalize-space(concat(@rax:roles, ' ', string-join($rax-roles, ' '))), ' ')) = '#all'">#all</xsl:when>
                <xsl:otherwise><xsl:value-of select="distinct-values(tokenize(normalize-space(concat(@rax:roles, ' ', string-join($rax-roles, ' '))), ' '))"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="copy"/>  
            <xsl:if test="$rax-roles-method != ''">
                <xsl:attribute name="rax:roles" select="$rax-roles-method"/>
            </xsl:if>
            <xsl:apply-templates select="node()" mode="copy"/>  
        </xsl:copy>
    </xsl:template>

    <xsl:template match="wadl:method[parent::wadl:resource]|wadl:param[ancestor::wadl:resource]" mode="path-format"/>

    <xsl:template match="wadl:resource[not(child::wadl:method)]" mode="path-format">
        <xsl:apply-templates select="wadl:resource" mode="path-format"/>
    </xsl:template>

    <xsl:template match="wadl:resource[wadl:method]" mode="path-format">
        <xsl:variable name="rax-roles" select="for $roles in (ancestor-or-self::*/@rax:roles) return concat($roles, ' ') "/>

        <resource>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="path">
                <xsl:for-each select="ancestor-or-self::wadl:resource">
                    <xsl:sort order="ascending" select="position()"/>
                    <xsl:value-of select="replace(replace(@path,'^(.+)/$','$1'),'^/(.+)$','$1')"/>
                    <xsl:if test="not(position() = last()) and not(@path = '/')">/</xsl:if>
                </xsl:for-each>
            </xsl:attribute>
            <xsl:attribute name="id">
      		    <xsl:choose>
      			   <xsl:when test="@id"><xsl:value-of select="@id"/></xsl:when>
      			   <xsl:otherwise><xsl:value-of select="raxf:generate-resource-id(.)"/></xsl:otherwise>
      		    </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates select="wadl:doc" mode="copy"/>
            <xsl:apply-templates select="ancestor-or-self::wadl:resource/wadl:param[@style = 'template' or @style = 'header']|wadl:param[@style = 'query']" mode="copy"/>
            <xsl:apply-templates select="wadl:method" mode="copy">
                <xsl:with-param name="rax-roles" select="$rax-roles"/>
            </xsl:apply-templates>
        </resource>
        <xsl:apply-templates mode="path-format"/>
    </xsl:template>

    <xsl:template match="processing-instruction('base-uri')|wadl:doc" mode="path-format"/>

    <xsl:function name="raxf:generate-resource-id" >
        <xsl:param name="current-node"/>
        <xsl:variable name="paths" select="for $path in $current-node/ancestor-or-self::wadl:resource/@path return concat($path,'-')"/>
        <xsl:variable name="id">rax-<xsl:for-each select="$paths"><xsl:value-of select="translate(.,'{}/','__-')"/></xsl:for-each><xsl:value-of select="count($current-node/preceding::wadl:resource)"/></xsl:variable> 
        <xsl:value-of select="replace($id,'-+','-')"/>
     </xsl:function>

</xsl:stylesheet>
