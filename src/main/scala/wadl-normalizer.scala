package com.rackspace.cloud.api.wadl

object WADLFormat extends Enumeration {
  type Format = Value
  val TREE = Value("tree-format")
  val PATH = Value("path-format")
  val DONT = Value("dont-format")
}

object RType extends Enumeration {
  type ResourceType = Value
  val KEEP = Value("keep")
  val OMIT = Value("omit")
}

object XSDVersion extends Enumeration {
  type Version = Value
  val XSD10 = Value("1.0")
  val XSD11 = Value("1.1")
}

import WADLFormat._
import RType._
import XSDVersion._

import javax.xml.transform._
import javax.xml.transform.sax._
import javax.xml.transform.stream.StreamSource

class WADLNormalizer(private var transformerFactory : TransformerFactory) {

  if (transformerFactory == null) {
    transformerFactory = TransformerFactory.newInstance("net.sf.saxon.TransformerFactoryImpl", null)
  }

  if (!transformerFactory.getFeature(SAXTransformerFactory.FEATURE)) {
    throw new RuntimeException("Need a SAX-compatible TransformerFactory!")
  }

  private val saxTransformerFactory : SAXTransformerFactory = transformerFactory.asInstanceOf[SAXTransformerFactory]
  private val templates : Templates = saxTransformerFactory.newTemplates(new StreamSource(getClass().getResourceAsStream("normalizeWadl.xsl")))

  def this() = this(null)

  def newTransformer = templates.newTransformer()

  def normalizeWADL(in: Source, out: Result,
                    format : Format = DONT,
                    xsdVersion : Version = XSD11,
                    flattenXSDs : Boolean = false,
		              resource_types : ResourceType = KEEP) : Unit = {

    val transformer = newTransformer

    transformer.setParameter("format",format.toString())
    transformer.setParameter("xsdVersion", xsdVersion.toString())
    transformer.setParameter("resource_types", resource_types.toString())
    transformer.setParameter("flattenXsds", flattenXSDs.toString())
    transformer.transform (in, out)
  }
}
