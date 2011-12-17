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
}


import WADLFormat._
import XSDVersion._
import Converters._

trait URLHandlers extends URIResolver {
  private val sourceMap : Map[String, Source] = new HashMap[String, Source]()
  val defaultResolver: URIResolver;

  //
  //  Add a source to consider
  //
  def → (url : String, xml : NodeSeq) : Unit = {
    sourceMap + (url -> xml)
  }

  //
  //  URL resolver implementation, I'm ignoring the base input, I
  //  don't think that we need it.
  //
  def resolve(href : String, base : String) = sourceMap getOrElse (href, defaultResolver.resolve(href, base))
}

class BaseWADLSpec extends FeatureSpec with URLHandlers {
  //
  // The normalization XSL
  //
  val normXSL = "xsl/normalizeWadl.xsl"

  //
  //  Init xml security lib
  //
  org.apache.xml.security.Init.init()

  //
  //  Make sure we use Saxon's XSL Transformer
  //
  System.setProperty("javax.xml.transform.TransformerFactory", "net.sf.saxon.TransformerFactoryImpl")

  private val tfactory = TransformerFactory.newInstance()
  private val transformer = tfactory.newTransformer(new StreamSource(normXSL))
  private val canonicalizer = Canonicalizer.getInstance(Canonicalizer.ALGO_ID_C14N_OMIT_COMMENTS);

  //
  //  Get the default resolver
  //
  val defaultResolver = tfactory.getURIResolver

  //
  //  Set ourselves as the resolver
  //
  tfactory.setURIResolver (this)

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
