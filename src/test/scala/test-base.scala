package com.rackspace.cloud.api.wadl.test

import scala.xml._
import scala.collection.mutable.Map
import scala.collection.mutable.HashMap
import javax.xml.transform._
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import org.apache.xml.security.c14n.Canonicalizer
import org.scalatest.FeatureSpec
import net.sf.saxon.lib.OutputURIResolver

object WADLFormat extends Enumeration {
  type Format = Value
  val TREE = Value("tree-format")
  val PATH = Value("path-format")
  val DONT = Value("dont-format")
}

object XSDVersion extends Enumeration {
  type Version = Value
  val XSD10 = Value("1.0")
  val XSD11 = Value("1.1")
}

object Converters {
  //
  //  Convert a node sequence to a Source
  //
  implicit def nodeSeq2Source(ns : NodeSeq) : Source = new StreamSource(new ByteArrayInputStream(ns.toString().getBytes()))

  //
  //  Convert a byte array stream result to a NodeSeq
  //
  implicit def byteArrayStreamResult2NodeSeq(sr : StreamResult) : NodeSeq = XML.loadString (sr.getOutputStream().toString())
}


import WADLFormat._
import XSDVersion._
import Converters._

trait TransformHandler {
  val transformerFactory = TransformerFactory.newInstance("net.sf.saxon.TransformerFactoryImpl", null)

  private val defaultResolver = transformerFactory.getURIResolver
  private val sourceMap : Map[String, Source] = new HashMap[String, Source]()
  private val destMap : Map[String, StreamResult] = new HashMap[String, StreamResult]()

  //
  //  Set input URL resolver
  //
  transformerFactory.setURIResolver (new Object() with URIResolver {
    //
    //  URL resolver implementation, I'm ignoring the base input, I
    //  don't think that we need it.
    //
    def resolve(href : String, base : String) = sourceMap getOrElse (href, defaultResolver.resolve(href, base)) 
  })

  //
  //  Set output URL resolver
  //
  transformerFactory.setAttribute ("http://saxon.sf.net/feature/outputURIResolver", new Object() with OutputURIResolver {
    //
    //  Output URI resolver, again ignoring the base here...
    //
    def resolve(href : String, base : String) = {
      val result = new StreamResult(new ByteArrayOutputStream())
      destMap += (href -> result)
      result
    }

    //
    //  Close the result
    //
    def close(result : Result) = {
      result.asInstanceOf[StreamResult].getOutputStream().close()
    }
  })

  //
  //  Add a source to consider
  //
  def register (url : String, xml : NodeSeq) : Unit = {
    sourceMap += (url -> xml)
  }

  //
  //  Get outputs
  //
  def outputs : Map[String, NodeSeq] = {
    val result : Map[String, NodeSeq] = new HashMap[String, NodeSeq]()
    destMap foreach ( (t) => result += (t._1 -> t._2))
    result
  }

  //
  //  Clear all!
  //
  def clearAll : Unit = {
    destMap.clear()
    sourceMap.clear()
  }
}

class BaseWADLSpec extends FeatureSpec with TransformHandler {
  //
  // The normalization XSL
  //
  val normXSL = "xsl/normalizeWadl.xsl"

  //
  //  Init xml security lib
  //
  org.apache.xml.security.Init.init()

  private val transformer = transformerFactory.newTransformer(new StreamSource(normXSL))
  private val canonicalizer = Canonicalizer.getInstance(Canonicalizer.ALGO_ID_C14N_OMIT_COMMENTS);

  def normalizeWADL(in : NodeSeq,
                    format : WADLFormat.Format = DONT,
                    xsdVersion : XSDVersion.Version = XSD11,
                    flattenXSDs : Boolean = false) = {
    val bytesOut = new ByteArrayOutputStream()
    transformer.clearParameters
    transformer.setParameter("format",format.toString())
    transformer.setParameter("xsdVersion", xsdVersion.toString())
    transformer.setParameter("flattenXsds", flattenXSDs.toString())
    transformer.transform (in, new StreamResult(bytesOut))
    XML.loadString (bytesOut.toString())
}

  //
  //  Given a node sequence returns a canonicalized XML string that
  //  can be used for comparisons.
  //
  def canon(in : NodeSeq) = {
    new String (canonicalizer.canonicalize(Utility.trim(in(0)).toString().getBytes()))
  }
}
