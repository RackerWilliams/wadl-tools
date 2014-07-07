package com.rackspace.cloud.api.wadl.test

import scala.xml._
import org.junit.runner.RunWith
import org.scalatest.junit.JUnitRunner
import org.scalatest.matchers.ShouldMatchers._

import com.rackspace.cloud.api.wadl.WADLFormat._
import com.rackspace.cloud.api.wadl.XSDVersion._
import com.rackspace.cloud.api.wadl.RType._
import com.rackspace.cloud.api.wadl.Converters._

import org.xml.sax.SAXParseException

import com.typesafe.scalalogging.slf4j.LazyLogging

@RunWith(classOf[JUnitRunner])
class WADLKeepReportSpec extends BaseWADLSpec with LazyLogging {
  //
  //  Register some common prefixes, you'll need the for XPath
  //  assertions.
  //
  register ("xsd", "http://www.w3.org/2001/XMLSchema")
  register ("wadl","http://wadl.dev.java.net/2009/02")
  register ("svrl","http://purl.oclc.org/dsdl/svrl")

  feature ("The WADL normalizer should keep schematron report if it's told to do so") {

    scenario ("A WADL with no external links should still refernce itself in the report") {
	   Given("a WADL with no external links")
	   val inWADL = ("test://path/to/test/mywadl.wadl",
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <resources base="https://test.api.openstack.com">
                 <resource path="a/b">
                     <resource path="c">
                        <method name="GET"/>
                     </resource>
                 </resource>
             </resources>
        </application>)
      When("the WADL is normalized")
      val normWADL = wadl.normalize(inWADL, TREE, XSD11, true, KEEP, true)
      Then("The normalized wadl should contain a report with the correct document referenced")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/mywadl.wadl'")
    }

    scenario ("A WADL with an external link should have the link reported") {
	   Given("a WADL with an external link")
      register ("test://path/to/test/other.wadl",
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <resource_type id="foo">
                <method name="GET"/>
             </resource_type>
        </application>
      )
	   val inWADL = ("test://path/to/test/mywadl.wadl",
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <resources base="https://test.api.openstack.com">
                 <resource path="a/b">
                     <resource path="c" type="other.wadl#foo">
                     </resource>
                 </resource>
             </resources>
        </application>)
      When("the WADL is normalized")
      val normWADL = wadl.normalize(inWADL, TREE, XSD11, true, KEEP, true)
      Then("The normalized wadl should contain a report with the correct document referenced")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/mywadl.wadl'")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/other.wadl'")
    }

    scenario ("A WADL with an external link which itself has an external link be reported") {
	   Given("a WADL with an external link")
      register ("test://path/to/test/other.wadl",
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <resource_type id="foo">
                <method name="GET"/>
                <resource path="d" type="other2.wadl#bar"/>
             </resource_type>
        </application>
      )
      register ("test://path/to/test/other2.wadl",
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <resource_type id="bar">
                <method name="GET"/>
             </resource_type>
        </application>
      )
	   val inWADL = ("test://path/to/test/mywadl.wadl",
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <resources base="https://test.api.openstack.com">
                 <resource path="a/b">
                     <resource path="c" type="other.wadl#foo">
                     </resource>
                 </resource>
             </resources>
        </application>)
      When("the WADL is normalized")
      val normWADL = wadl.normalize(inWADL, TREE, XSD11, true, KEEP, true)
      Then("The normalized wadl should contain a report with the correct document referenced")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/mywadl.wadl'")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/other.wadl'")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/other2.wadl'")
    }

    scenario ("A WADL with an external link and an external XSD should have both links reported") {
	   Given("a WADL with an external link")
      register ("test://path/to/test/other.wadl",
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <resource_type id="foo">
                <method name="GET"/>
             </resource_type>
        </application>
      )
      register ("test://path/to/test/xsd/mytest.xsd",
                <schema elementFormDefault="qualified"
                        attributeFormDefault="unqualified"
                        xmlns="http://www.w3.org/2001/XMLSchema"
                        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                        targetNamespace="test://schema/a">
                    <element name="test" type="xsd:string"/>
                </schema>
      )
	   val inWADL = ("test://path/to/test/mywadl.wadl",
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <grammars>
                <include href="xsd/mytest.xsd"/>
             </grammars>
             <resources base="https://test.api.openstack.com">
                 <resource path="a/b">
                     <resource path="c" type="other.wadl#foo">
                     </resource>
                 </resource>
             </resources>
        </application>)
      When("the WADL is normalized")
      val normWADL = wadl.normalize(inWADL, TREE, XSD11, true, KEEP, true)
      Then("The normalized wadl should contain a report with the correct document referenced")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/mywadl.wadl'")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/other.wadl'")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/xsd/mytest.xsd'")
    }

    scenario ("A WADL with an external link and an multiple external XSD should have both links reported") {
	   Given("a WADL with an external link")
      register ("test://path/to/test/other.wadl",
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <resource_type id="foo">
                <method name="GET"/>
             </resource_type>
        </application>
      )
      register ("test://path/to/test/xsd/mytest.xsd",
                <schema elementFormDefault="qualified"
                        attributeFormDefault="unqualified"
                        xmlns="http://www.w3.org/2001/XMLSchema"
                        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                        targetNamespace="test://schema/a">
                    <include schemaLocation="mytest2.xsd"/>
                    <element name="test" type="xsd:string"/>
                </schema>
      )
      register ("test://path/to/test/xsd/mytest2.xsd",
                <schema elementFormDefault="qualified"
                        attributeFormDefault="unqualified"
                        xmlns="http://www.w3.org/2001/XMLSchema"
                        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                        targetNamespace="test://schema/a">
                    <import namespace="test://schema/a/other" schemaLocation="mytest-other.xsd"/>
                    <element name="test2" type="xsd:string"/>
                </schema>
      )
      register ("test://path/to/test/xsd/mytest-other.xsd",
                <schema elementFormDefault="qualified"
                        attributeFormDefault="unqualified"
                        xmlns="http://www.w3.org/2001/XMLSchema"
                        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                        targetNamespace="test://schema/a/other">
                    <element name="other" type="xsd:string"/>
                </schema>
      )
	   val inWADL = ("test://path/to/test/mywadl.wadl",
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <grammars>
                <include href="xsd/mytest.xsd"/>
             </grammars>
             <resources base="https://test.api.openstack.com">
                 <resource path="a/b">
                     <resource path="c" type="other.wadl#foo">
                     </resource>
                 </resource>
             </resources>
        </application>)
      When("the WADL is normalized")
      val normWADL = wadl.normalize(inWADL, TREE, XSD11, true, KEEP, true)
      Then("The normalized wadl should contain a report with the correct document referenced")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/mywadl.wadl'")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/other.wadl'")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/xsd/mytest.xsd'")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/xsd/mytest2.xsd'")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/xsd/mytest-other.xsd'")
    }

    scenario ("A WADL with an external link and an multiple external XSD referenced from interal XSD should have all links reported") {
	   Given("a WADL with an external link")
      register ("test://path/to/test/other.wadl",
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <resource_type id="foo">
                <method name="GET"/>
             </resource_type>
        </application>
      )
      register ("test://path/to/test/xsd/mytest2.xsd",
                <schema elementFormDefault="qualified"
                        attributeFormDefault="unqualified"
                        xmlns="http://www.w3.org/2001/XMLSchema"
                        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                        targetNamespace="test://schema/a">
                    <import namespace="test://schema/a/other" schemaLocation="mytest-other.xsd"/>
                    <element name="test2" type="xsd:string"/>
                </schema>
      )
      register ("test://path/to/test/xsd/mytest-other.xsd",
                <schema elementFormDefault="qualified"
                        attributeFormDefault="unqualified"
                        xmlns="http://www.w3.org/2001/XMLSchema"
                        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                        targetNamespace="test://schema/a/other">
                    <element name="other" type="xsd:string"/>
                </schema>
      )
	   val inWADL = ("test://path/to/test/mywadl.wadl",
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <grammars>
                 <schema elementFormDefault="qualified"
                        attributeFormDefault="unqualified"
                        xmlns="http://www.w3.org/2001/XMLSchema"
                        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                        targetNamespace="test://schema/a">
                    <include schemaLocation="xsd/mytest2.xsd"/>
                    <element name="test" type="xsd:string"/>
                </schema>
             </grammars>
             <resources base="https://test.api.openstack.com">
                 <resource path="a/b">
                     <resource path="c" type="other.wadl#foo">
                     </resource>
                 </resource>
             </resources>
        </application>)
      When("the WADL is normalized")
      val normWADL = wadl.normalize(inWADL, TREE, XSD11, true, KEEP, true)
      Then("The normalized wadl should contain a report with the correct document referenced")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/mywadl.wadl'")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/other.wadl'")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/xsd/mytest2.xsd'")
      assert(normWADL, "/wadl:application/svrl:schematron-output/svrl:active-pattern[@name='References']/@document = 'test://path/to/test/xsd/mytest-other.xsd'")
    }
  }
}
