<?xml version="1.0" encoding="UTF-8"?>
<p:library xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:cx="http://xmlcalabash.com/ns/extensions"
    xmlns:c="http://www.w3.org/ns/xproc-step"
    xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
    xmlns:ml="http://xmlcalabash.com/ns/extensions/marklogic"
    xmlns:ut="http://grtjn.nl/ns/xproc/util"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    version="1.0">
    
    <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>

    <p:declare-step 
        xmlns:p="http://www.w3.org/ns/xproc"
        xmlns:l="http://xproc.org/library"
        type="l:normalizeWadl"
        xmlns:c="http://www.w3.org/ns/xproc-step"
        version="1.0"
        name="normalizeWadl-step">
        
        <p:input port="source" primary="true"/>
        
        <p:output port="secondary" primary="false" sequence="true"/>
        <p:output port="result" primary="true" >
            <p:pipe step="normalizeWadl-xslt" port="result"/> 
        </p:output>
        
        <p:input port="parameters" kind="parameter"/>
        
        <p:xslt name="normalizeWadl-xslt">
            <p:input port="source"> 
                <p:pipe step="normalizeWadl-step" port="source"/> 
            </p:input> 
            <p:input port="stylesheet">
                <p:document href="xsl/normalizeWadl.xsl"/>
            </p:input>
            <p:input port="parameters" >
                <p:inline>
                    <c:param-set>
                        <c:param name="format" value="path-format"/>
                    </c:param-set>
                </p:inline>
                <!--<p:pipe step="normalizeWadl-step" port="parameters"/>-->
            </p:input>
        </p:xslt>
         
    </p:declare-step>
    
    <p:declare-step 
        xmlns:p="http://www.w3.org/ns/xproc"
        xmlns:l="http://xproc.org/library"
        type="l:wadl2apiary-jsonx"
        xmlns:c="http://www.w3.org/ns/xproc-step"
        version="1.0"
        name="wadl2apiary-jsonx-step">
        
        <p:input port="source" primary="true"/>
        
        <p:output port="secondary" primary="false" sequence="true"/>
        <p:output port="result" primary="true" >
            <p:pipe step="wadl2apiary-jsonx-xslt" port="result"/> 
        </p:output>
        
        <p:input port="parameters" kind="parameter"/>
        
        <p:xslt name="wadl2apiary-jsonx-xslt">
            <p:input port="source"> 
                <p:pipe step="wadl2apiary-jsonx-step" port="source"/> 
            </p:input> 
            <p:input port="stylesheet">
                <p:document href="xsl/wadl2apiary-jsonx.xsl"/>
            </p:input>
            <p:input port="parameters" >
                <p:pipe step="wadl2apiary-jsonx-step" port="parameters"/>
            </p:input>
        </p:xslt>
        
    </p:declare-step>
    
    <p:declare-step 
        xmlns:p="http://www.w3.org/ns/xproc"
        xmlns:l="http://xproc.org/library"
        type="l:jsonx2json"
        xmlns:c="http://www.w3.org/ns/xproc-step"
        version="1.0"
        name="jsonx2json-step">
        
        <p:input port="source" primary="true"/>
        
        <p:output port="secondary" primary="false" sequence="true"/>
        <p:output port="result" primary="true" >
            <p:pipe step="jsonx2json-xslt" port="result"/> 
        </p:output>
        
        <p:input port="parameters" kind="parameter"/>
        
        <p:xslt name="jsonx2json-xslt">
            <p:input port="source"> 
                <p:pipe step="jsonx2json-step" port="source"/> 
            </p:input> 
            <p:input port="stylesheet">
                <p:document href="xsl/jsonx2json.xsl"/>
            </p:input>
            <p:input port="parameters" >
                <p:pipe step="jsonx2json-step" port="parameters"/>
            </p:input>
        </p:xslt>
        
    </p:declare-step>
    
</p:library>
