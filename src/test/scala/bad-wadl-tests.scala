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

  }
}
