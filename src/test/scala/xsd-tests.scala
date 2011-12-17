package com.rackspace.cloud.api.wadl.test

import scala.xml._
import org.junit.runner.RunWith
import org.scalatest.junit.JUnitRunner
import org.scalatest.GivenWhenThen
import org.scalatest.matchers.ShouldMatchers._

import WADLFormat._
import XSDVersion._


@RunWith(classOf[JUnitRunner])
class NormalizeXSDSpec extends BaseWADLSpec with GivenWhenThen {

  feature ("The WADL normalizer can correctly transform XSD into 1.0 format") {

    info("As a developer")
    info("I want to be able to transform the XSDs in a WADL into 1.0 format")
    info("by correctly processing the schema versioning attributes")
    info("So that I can process the WADL with an XSD 1.0 tool")

    scenario("The WADL does not contain an XSD") {
      given("a WADL with no schema")
      val inWADL =
        <application xmlns="http://wadl.dev.java.net/2009/02">
            <grammars>
            </grammars>
            <resources base="https://test.api.openstack.com">
              <resource path="a">
                <resource path="b">
                  <resource path="c"/>
                </resource>
              </resource>
            </resources>
        </application>
      when("the wadl is normalized")
      val normWADL = normalizeWADL(inWADL, TREE, XSD10, true)
      then("No additonal documents should be produced")
      outputs.size should equal (0)
    }

    scenario("The WADL points to a single XSD with no versioning schema in a relative path") {
      given("a WADL with a relative path schema")
      val inXSD = ("test://path/to/test/schema1.xsd",
       <schema elementFormDefault="qualified"
          attributeFormDefault="unqualified"
          xmlns="http://www.w3.org/2001/XMLSchema"
          xmlns:xsd="http://www.w3.org/2001/XMLSchema"
          targetNamespace="test://schema/a">
             <element name="test" type="xsd:string"/>
       </schema>)
      register(inXSD)
      val inWADL = ("test://path/to/test/mywadl.wadl",
        <application xmlns="http://wadl.dev.java.net/2009/02">
            <grammars>
               <include href="schema1.xsd"/>
            </grammars>
            <resources base="https://test.api.openstack.com">
              <resource path="a">
                <resource path="b">
                  <resource path="c"/>
                </resource>
              </resource>
            </resources>
        </application>)
      when("the wadl is normalized")
      val normWADL = normalizeWADL(inWADL, TREE, XSD10, true)
      then("There should be a single XSD produced")
      outputs.size should equal (1)
      and("The name of the XSD file produced should be WADLName-xsd-1.xsd")
      assert (outputs contains "mywadl-xsd-1.xsd")
    }
  }

}
