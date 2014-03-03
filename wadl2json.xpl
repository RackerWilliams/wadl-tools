<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:l="http://xproc.org/library"
    xmlns:cxo="http://xmlcalabash.com/ns/extensions/osutils"
    xmlns:pos="http://exproc.org/proposed/steps/os"
    xmlns:cx="http://xmlcalabash.com/ns/extensions"
    xmlns:c="http://www.w3.org/ns/xproc-step" version="1.0">
    
    <!-- 
        Run like this: 
        java -Xmx1024m -jar /home/dcramer/applications/xmlcalabash-1.0.13-94/calabash.jar -i "source=path-to-file.wadl"  ~/rax/wadl-tools-dwcramer/wadl2json.xpl
        Where path-to-file.wadl is the wadl to convert. 
    -->
    
    <p:input port="source" primary="true" />
    <p:input port="parameters" kind="parameter" />

    <p:import href="library.xpl"/>
    <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
    
    <p:variable name="input-base" select="replace(base-uri(/*), '^(.*/)?([^/]+)$', '$1')"/>
    <p:variable name="input-name" select="concat(replace(base-uri(/*), '^(.*/)?([^/]+)(\.wadl)$', '$2'),'.json')"/>
    <!-- For some reason I can't get cwd() to work -->
    <!-- <p:variable name="output" select="concat(pos:cwd(),'/foobaz.json')"/> -->
    <p:variable name="output" select="concat($input-base,'/', $input-name)"/>
    
    <!-- <cx:message> -->
    <!--     <p:with-option name="message" select="concat('output = ',$input-base)"/> -->
    <!-- </cx:message> -->
    
    <l:normalizeWadl name="normalizeWadl"/>
    <l:wadl2apiary-jsonx name="wadl2apiary"/>
    <l:jsonx2json name="json"/>
    
    <p:store method="text">
        <p:with-option name="href" select="$output" />
    </p:store>
    
</p:declare-step>
