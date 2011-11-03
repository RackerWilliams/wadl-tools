<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
    version="1.0">
    <p:input port="source"/>
    <p:output port="secondary" primary="false" sequence="true"/>
    
    <p:variable name="input-base" select="replace(base-uri(/*), '^(.*/)?([^/]+)$', '$1')"/>
    <p:variable name="input-name" select="replace(base-uri(/*), '^(.*/)?([^/]+)$', '$2')"/>
    <p:variable name="output-wadl" select="resolve-uri(concat('normalized/',$input-name), $input-base)"/>
    
    <p:validate-with-xml-schema assert-valid="true" mode="strict" name="validate">
        <p:input port="schema">
            <p:document  href="../xsd/wadl.xsd"/>
        </p:input>
    </p:validate-with-xml-schema>

    <p:xslt name="style" version="2.0">
        <p:input port="source">
            <p:pipe step="validate" port="result"/>
        </p:input>
        <p:input port="stylesheet">
            <p:document href="../xsl/normalizeWadl.xsl"/>
        </p:input>
        <p:input port="parameters">
            <p:empty/>
        </p:input>
    </p:xslt>

    <p:validate-with-xml-schema assert-valid="true" mode="strict" name="post-validate">
        <p:input port="schema">
            <p:document  href="../xsd/wadl.xsd"/>
        </p:input>
    </p:validate-with-xml-schema>

    <p:store>
        <p:with-option name="href" select="$output-wadl"/>
    </p:store>
    
    <p:for-each>
        <p:iteration-source>
            <p:pipe step="style" port="secondary"/>
        </p:iteration-source>
        <p:store encoding="utf-8" indent="true" omit-xml-declaration="false">
            <p:with-option name="href" select="resolve-uri(concat('normalized/',replace(base-uri(/*), '^(.*/)?([^/]+)$', '$2')),$input-base)"/>
        </p:store>        
    </p:for-each>
    
</p:declare-step>