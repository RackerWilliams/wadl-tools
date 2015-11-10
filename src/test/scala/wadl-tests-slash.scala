package com.rackspace.cloud.api.wadl.test

import scala.xml._
import org.junit.runner.RunWith
import org.scalatest.junit.JUnitRunner
import org.scalatest.matchers.ShouldMatchers._

import com.rackspace.cloud.api.wadl.WADLFormat._
import com.rackspace.cloud.api.wadl.XSDVersion._
import com.rackspace.cloud.api.wadl.RType._
import com.rackspace.cloud.api.wadl.Converters._

@RunWith(classOf[JUnitRunner])
class NormalizeWADLSlashSpec extends BaseWADLSpec {

  //
  //  Register some common prefixes, you'll need the for XPath
  //  assertions.
  //
  register ("xsd", "http://www.w3.org/2001/XMLSchema")
  register ("wadl","http://wadl.dev.java.net/2009/02")
  register ("rax", "http://docs.rackspace.com/api")

  feature ("The WADL normalizer can convert resources in a tree format and ignore extra slashes //") {

    info("As a developer")
    info("I want to ignore extra slashes in the WADL cus they happen all the time and they are irrelevent")
    info("So that I can normalize a WADL without worrying about cleaning extra slashes up.")

    scenario ("A single WADL contians extra slashes") {
      Given("Given semantically equivilant WADLs with and without extra slashes")

        def norm(n : NodeSeq) : NodeSeq = {
	  wadl.normalize(("test://path/to/test/mywadl.wadl", n), TREE, XSD11, false, KEEP)
	}

      //
      //  An external file with double slashes...
      //
       register ("test://path/to/test/other.wadl",
		 <application xmlns="http://wadl.dev.java.net/2009/02">
                    <resource_type id="cd">
		     <resource path="c///d">
			 <method name="GET"/>
		     </resource>
                    </resource_type>
                 </application>)

        val normWADLs = List(
	  //
	  //  No double slashes
	  //
	  norm(<application xmlns="http://wadl.dev.java.net/2009/02">
        <resources base="https://test.api.openstack.com">
          <resource path="/a">
              <method name="PUT"/>
              <resource path="/b">
                  <method name="POST"/>
                  <method name="PUT"/>
                  <method name="DELETE"/>
              </resource>
           </resource>
          <resource path="/a/b/c/d">
	    <method name="GET"/>
	  </resource>
	  <resource path="/foo">
	      <method name="GET"/>
	      <resource path="bar">
		  <method name="POST"/>
	      </resource>
	  </resource>
        </resources>
       </application>),
	  //
	  //  Double slashes at the end of the path
	  //
	  norm(<application xmlns="http://wadl.dev.java.net/2009/02">
        <resources base="https://test.api.openstack.com">
          <resource path="/a">
              <method name="PUT"/>
              <resource path="/b//">
                  <method name="POST"/>
                  <method name="PUT"/>
                  <method name="DELETE"/>
              </resource>
           </resource>
          <resource path="/a/b/c/d//">
	    <method name="GET"/>
	  </resource>
	  <resource path="/foo">
	      <method name="GET"/>
	      <resource path="bar//">
		  <method name="POST"/>
	      </resource>
	  </resource>
        </resources>
       </application>),
	  //
	  //  Double slashes at the end of all of the paths
	  //
	  norm(<application xmlns="http://wadl.dev.java.net/2009/02">
        <resources base="https://test.api.openstack.com">
          <resource path="/a///">
              <method name="PUT"/>
              <resource path="/b//">
                  <method name="POST"/>
                  <method name="PUT"/>
                  <method name="DELETE"/>
              </resource>
           </resource>
          <resource path="/a/b/c/d//">
	    <method name="GET"/>
	  </resource>
	  <resource path="/foo//">
	      <method name="GET"/>
	      <resource path="bar//">
		  <method name="POST"/>
	      </resource>
	  </resource>
        </resources>
       </application>),
	  //
	  //  Double slashes in various parts of the path
	  //
	  norm(<application xmlns="http://wadl.dev.java.net/2009/02">
        <resources base="https://test.api.openstack.com">
          <resource path="/a">
              <method name="PUT"/>
              <resource path="//b">
                  <method name="POST"/>
                  <method name="PUT"/>
                  <method name="DELETE"/>
              </resource>
           </resource>
          <resource path="/a/b/c///d">
	    <method name="GET"/>
	  </resource>
	  <resource path="//foo">
	      <method name="GET"/>
	      <resource path="bar">
		  <method name="POST"/>
	      </resource>
	  </resource>
        </resources>
       </application>),
	  //
	  //  Double slashes in various parts of the path, with method
	  //  references.
	  //
	  norm(<application xmlns="http://wadl.dev.java.net/2009/02">
            <resources base="https://test.api.openstack.com">
               <resource path="/a">
                 <method href="#putOnA"/>
                   <resource path="//b">
                     <method href="#postOnB"/>
                     <method href="#putOnB"/>
                     <method href="#deleteOnB"/>
                   </resource>
               </resource>
              <resource path="/a/b/c///d">
		 <method href="#getOnD"/>
	      </resource>
	      <resource path="//foo">
		<method href="#getOnD"/>
		<resource path="bar">
		  <method href="#postOnB"/>
		</resource>
	      </resource>
            </resources>
             <method id="putOnA" name="PUT"/>
             <method id="postOnB" name="POST"/>
             <method id="putOnB" name="PUT"/>
             <method id="deleteOnB" name="DELETE"/>
             <method id="getOnD" name="GET"/>
           </application>),
	  //
	  //  Double slashes in external file
	  //
	  norm(<application xmlns="http://wadl.dev.java.net/2009/02">
        <resources base="https://test.api.openstack.com">
          <resource path="/a">
              <method name="PUT"/>
              <resource path="/b" type="other.wadl#cd">
                  <method name="POST"/>
                  <method name="PUT"/>
                  <method name="DELETE"/>
              </resource>
           </resource>
	  <resource path="/foo">
	      <method name="GET"/>
	      <resource path="bar">
		  <method name="POST"/>
	      </resource>
	  </resource>
        </resources>
       </application>)
	)

      When ("When the WADLs are normalized in tree format")
      Then("The following XPath assertions should match")
      normWADLs.foreach(w => {
	//
	//  Overall structure
	//
	assert (w, "/wadl:application/wadl:resources/wadl:resource[@path='a']")
	assert (w, "/wadl:application/wadl:resources/wadl:resource[@path='a']/wadl:resource[@path='b']")
	assert (w, "/wadl:application/wadl:resources/wadl:resource[@path='a']/wadl:resource[@path='b']/wadl:resource[@path='c']")
	assert (w, "/wadl:application/wadl:resources/wadl:resource[@path='a']/wadl:resource[@path='b']/wadl:resource[@path='c']/wadl:resource[@path='d']")
	assert (w, "/wadl:application/wadl:resources/wadl:resource[@path='foo']")
	assert (w, "/wadl:application/wadl:resources/wadl:resource[@path='foo']/wadl:resource[@path='bar']")

	//
	//  Methods
	//
	assert (w, "/wadl:application/wadl:resources/wadl:resource[@path='a']/wadl:method[@name='PUT']")
	assert (w, "/wadl:application/wadl:resources/wadl:resource[@path='a']/wadl:resource[@path='b']/wadl:method[@name='POST']")
	assert (w, "/wadl:application/wadl:resources/wadl:resource[@path='a']/wadl:resource[@path='b']/wadl:method[@name='PUT']")
	assert (w, "/wadl:application/wadl:resources/wadl:resource[@path='a']/wadl:resource[@path='b']/wadl:method[@name='DELETE']")
	assert (w, "/wadl:application/wadl:resources/wadl:resource[@path='a']/wadl:resource[@path='b']/wadl:resource[@path='c']/wadl:resource[@path='d']/wadl:method[@name='GET']")
	assert (w, "/wadl:application/wadl:resources/wadl:resource[@path='foo']/wadl:method[@name='GET']")
	assert (w, "/wadl:application/wadl:resources/wadl:resource[@path='foo']/wadl:resource[@path='bar']/wadl:method[@name='POST']")
      })
    }
  }
}
