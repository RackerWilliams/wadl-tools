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

@RunWith(classOf[JUnitRunner])
class BadWADLSpec extends BaseWADLSpec {
  //
  //  Register some common prefixes, you'll need the for XPath
  //  assertions.
  //
  register ("xsd", "http://www.w3.org/2001/XMLSchema")
  register ("wadl","http://wadl.dev.java.net/2009/02")

  feature ("The WADL normalizer should fail when an invalid WADL is supplied") {
    scenario ("A WADL with a link not containing a #, should be reqected") {
	   given("a WADL with a link missing a #")
	   val inWADL =
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <resources base="https://test.api.openstack.com">
                 <resource path="a/b">
                     <resource path="c">
	                    <method href="foo"/>
                     </resource>
                 </resource>
             </resources>
             <method id="foo"/>
        </application>
      when("the WADL is normalized")
      val thrown = intercept[Exception] {
        val normWADL = wadl.normalize(inWADL, TREE)
      }
      then("An exception should be thrown with the words foo and #")
      assert(thrown.getMessage().contains("foo"))
      assert(thrown.getMessage().contains("#"))
    }

    scenario ("A WADL with a missing link should be rejected") {
	   given("a WADL with a link missing a #")
	   val inWADL =
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <resources base="https://test.api.openstack.com">
                 <resource path="a/b">
                     <resource path="c">
	                    <method href="#foo"/>
                     </resource>
                 </resource>
             </resources>
        </application>
      when("the WADL is normalized")
      val thrown = intercept[Exception] {
        val normWADL = wadl.normalize(inWADL, TREE)
      }
      then("An exception should be thrown with the words 'foo' and 'does not seem to exist'.")
      assert(thrown.getMessage().contains("foo"))
      assert(thrown.getMessage().contains("does not seem to exist"))
    }

    scenario ("A WADL with a missing include should be rejected") {
	   given("a WADL with a missing include")
	   val inWADL =
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <grammars>
               <include href="schema.xsd"/>
             </grammars>
             <resources base="https://test.api.openstack.com">
                 <resource path="a/b">
                     <resource path="c">
	                    <method href="#foo"/>
                     </resource>
                 </resource>
             </resources>
             <method id="foo"/>
        </application>
      when("the WADL is normalized")
      val thrown = intercept[Exception] {
        val normWADL = wadl.normalize(inWADL, TREE)
      }
      then("An exception should be thrown with the words 'schema.xsd' and 'is not available'.")
      assert(thrown.getMessage().contains("schema.xsd"))
      assert(thrown.getMessage().contains("is not available"))
    }

    scenario ("A WADL with a missing code sample should be rejected") {
	   given("a WADL with a missing code sample")
	   val inWADL =
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsdxt="http://docs.rackspacecloud.com/xsd-ext/v1.0"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <resources base="https://test.api.openstack.com">
                 <resource path="a/b">
                     <resource path="c">
	                    <method href="#foo"/>
                     </resource>
                 </resource>
             </resources>
             <method id="foo">
               <request>
                  <representation>
                    <doc xml:lang="EN">
                        <xsdxt:code href="missing_sample.xml"/>
                    </doc>
                  </representation>
               </request>
             </method>
        </application>
      when("the WADL is normalized")
      val thrown = intercept[Exception] {
        val normWADL = wadl.normalize(inWADL, TREE)
      }
      then("An exception should be thrown with the words 'missing_sample.xml' and 'is not available'.")
      assert(thrown.getMessage().contains("missing_sample.xml"))
      assert(thrown.getMessage().contains("is not available"))
    }

    scenario ("A WADL with a parameter reference, that does not point to a parameter should be rejected") {
	   given("a WADL with a parameter reference pointing to a method")
	   val inWADL =
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <resources base="https://test.api.openstack.com">
                 <resource path="a/b">
                     <resource path="c">
	                    <param href="#foo"/>
                     </resource>
                 </resource>
             </resources>
             <method id="foo"/>
        </application>
      when("the WADL is normalized")
      val thrown = intercept[Exception] {
        val normWADL = wadl.normalize(inWADL, TREE)
      }
      then("An exception should be thrown with the words 'foo' and 'param'")
      assert(thrown.getMessage().contains("foo"))
      assert(thrown.getMessage().contains("param"))
    }

    scenario ("A WADL with a representation reference, that does not point to a representation should be rejected") {
	   given("a WADL with a representation reference pointing to a method")
	   val inWADL =
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <resources base="https://test.api.openstack.com">
                 <resource path="a/b">
                     <resource path="c">
                       <method name="POST">
	                      <request>
                            <representation href="#foo"/>
                          </request>
                        </method>
                     </resource>
                 </resource>
             </resources>
             <method id="foo"/>
        </application>
      when("the WADL is normalized")
      val thrown = intercept[Exception] {
        val normWADL = wadl.normalize(inWADL, TREE)
      }
      then("An exception should be thrown with the words 'foo' and 'representation'")
      assert(thrown.getMessage().contains("foo"))
      assert(thrown.getMessage().contains("representation"))
    }

    scenario ("A WADL with a method reference, that does not point to a method should be rejected") {
	   given("a WADL with a method reference pointing to a representation")
	   val inWADL =
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <resources base="https://test.api.openstack.com">
                 <resource path="a/b">
                     <resource path="c">
                         <method href="#foo"/>
                     </resource>
                 </resource>
             </resources>
             <representation id="foo"/>
        </application>
      when("the WADL is normalized")
      val thrown = intercept[Exception] {
        val normWADL = wadl.normalize(inWADL, TREE)
      }
      then("An exception should be thrown with the words 'foo' and 'method'")
      assert(thrown.getMessage().contains("foo"))
      assert(thrown.getMessage().contains("method"))
    }

    scenario ("A WADL with a resource type reference, that does not point to a resource_type should be rejected") {
	   given("a WADL with a resource type  reference pointing to a representation")
	   val inWADL =
        <application xmlns="http://wadl.dev.java.net/2009/02"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
             <resources base="https://test.api.openstack.com">
                 <resource path="a/b">
                     <resource path="c">
                        <method name="GET">
                            <response status="200">
                                <representation mediaType="application/xml">
                                    <param name="location" style="plain" type="xsd:anyURI">
                                       <link resource_type="#foo"/>
                                    </param>
                                </representation>
                            </response>
                        </method>
                     </resource>
                 </resource>
             </resources>
             <representation id="foo"/>
        </application>
      when("the WADL is normalized")
      val thrown = intercept[Exception] {
        val normWADL = wadl.normalize(inWADL, TREE)
      }
      then("An exception should be thrown with the words 'foo' and 'resource_type'")
      assert(thrown.getMessage().contains("foo"))
      assert(thrown.getMessage().contains("resource_type"))
    }

  }
}
