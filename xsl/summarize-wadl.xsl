<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rax="http://docs.rackspace.com/api"
    xmlns:wadl="http://wadl.dev.java.net/2009/02"
    version="2.0" exclude-result-prefixes="wadl">
    
    <xsl:import href="normalizeWadl1.xsl"/>
    
    <xsl:param name="pathto">@@PATH_TO@@/</xsl:param>
    <xsl:param name="format">path-format</xsl:param>
    <xsl:param name="wadl2docbook">0</xsl:param>
    <xsl:param name="resource_types">omit</xsl:param>
    <xsl:param name="wadlname" select="replace(base-uri($root),'(.*/)(.*\.wadl)', '$2')"/>
    <xsl:param name="flattenXsds">false</xsl:param>
    
    
    <xsl:template match="/">
        
        <xsl:apply-templates select="$normalizeWadl5.xsl" mode="summarize"/>

    </xsl:template>
    
    <xsl:template match="rax:types|rax:responses|rax:resources|@rax:original-wadl" mode="summarize"/>
    
    <xsl:template match="wadl:application" mode="summarize">
       <html>
           <head>
               <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
           </head>
           <body>
               <h1>Wadl: <xsl:value-of select="$wadlname"/></h1>
               <p><b>WADL Location: </b><xsl:value-of select="base-uri($root)"/></p>
               <ul>
                <xsl:apply-templates select="wadl:resources" mode="toc"/>
               </ul>
                <xsl:apply-templates select="wadl:resources" mode="summarize"/>
           </body>
           <link href='http://alexgorbatchev.com/pub/sh/current/styles/shCore.css' rel='stylesheet' type='text/css' />
           <link href='http://alexgorbatchev.com/pub/sh/current/styles/shThemeDefault.css' rel='stylesheet' type='text/css' />
           <script src='http://alexgorbatchev.com/pub/sh/current/scripts/shCore.js' type='text/javascript'>&#160;</script>
           <script src='http://alexgorbatchev.com/pub/sh/current/scripts/shAutoloader.js' type='text/javascript'>&#160;</script>
           <script src='http://alexgorbatchev.com/pub/sh/current/scripts/shBrushXml.js' type='text/javascript'>&#160;</script>
           <script src='http://alexgorbatchev.com/pub/sh/current/scripts/shBrushCss.js' type='text/javascript'>&#160;</script>
           <script type="text/javascript">
               SyntaxHighlighter.config.space = '&#32;';
               SyntaxHighlighter.defaults['smart-tabs'] = false;
               SyntaxHighlighter.defaults['auto-links'] = false;
               SyntaxHighlighter.all()
  </script>
       </html>
    </xsl:template>
    
    <xsl:template match="wadl:resources" mode="summarize toc">
        <xsl:apply-templates select="wadl:resource" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="wadl:resource" mode="summarize toc">
        <xsl:apply-templates select="wadl:method|wadl:resource" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="wadl:method[not(@href)]" mode="toc">
        <xsl:param name="id" select="ancestor::wadl:resource/@id"/>
        <xsl:param name="title">
            <xsl:choose>
                <xsl:when test="wadl:doc/@title"><xsl:value-of select="wadl:doc/@title"/> (<xsl:value-of select="ancestor::wadl:resource/@path"/>)</xsl:when>
                <xsl:otherwise><xsl:value-of select="concat(ancestor::wadl:resource[last()]/@path, ' method id: ', @id)"/></xsl:otherwise>
            </xsl:choose>
        </xsl:param>
        <xsl:param name="methodid" select="if(@rax:id) then @rax:id else @id"/> 
        <li><a href="#{$id}_{$methodid}"><xsl:value-of select="$title"/></a></li>
    </xsl:template>
    
    <xsl:template match="wadl:method[not(@href)]" mode="summarize">
        <xsl:param name="id" select="ancestor::wadl:resource/@id"/>
        <xsl:param name="title">
            <xsl:choose>
                <xsl:when test="wadl:doc/@title"><xsl:value-of select="wadl:doc/@title"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="concat(ancestor::wadl:resource[last()]/@path, ' method id: ', @id)"/></xsl:otherwise>
            </xsl:choose>
        </xsl:param>
        <xsl:param name="methodid" select="if(@rax:id) then @rax:id else @id"/>
        <h2><xsl:value-of select="$title"/></h2>
        <anchor id="{$id}_{$methodid}"/>
        <pre class="brush: xml; highlight: [3, 4]">
            &lt;resources xmlns="http://wadl.dev.java.net/2009/02"&gt;
            &lt;!-- Path: <xsl:value-of select="ancestor::wadl:resource[last()]/@path"/> --&gt;
             &lt;resource href="<xsl:value-of select="concat($pathto, $wadlname)"/>#<xsl:value-of select="$id"/>"&gt;
               &lt;method href="<xsl:value-of select="$methodid"/>">
                 &lt;wadl:doc xmlns:wadl="http://wadl.dev.java.net/2009/02" xmlns="http://docbook.org/ns/docbook">
                    &lt;!-- DocBook Markup is legal here -->
                    <xsl:if test="wadl:doc">&lt;!-- <xsl:if test="wadl:doc/@title"><xsl:value-of select="wadl:doc/@title"/>: </xsl:if><xsl:value-of select="substring(normalize-space(wadl:doc[1]),1,140)"/><xsl:if test="string-length(normalize-space(wadl:doc[1])) &gt; 140">...</xsl:if> --&gt;</xsl:if>
                 &lt;/wadl:doc>
               &lt;/method&gt;
             &lt;/resource&gt;
           &lt;/resources&gt;
        </pre>
    </xsl:template>
    
</xsl:stylesheet>