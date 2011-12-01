package com.rackspace.cloud.api.wadl.test

import scala.xml._
import javax.xml.transform._
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import org.scalatest.FeatureSpec


class BaseWADLSpec extends FeatureSpec {
  //
  //  Make sure we use Saxon's XSL Transformer
  //
  System.setProperty("javax.xml.transform.TransformerFactory", "net.sf.saxon.TransformerFactoryImpl")

  val normXSL = "xsl/normalizeWadl.xsl"

  private val tfactory = TransformerFactory.newInstance()
  private val transformer = tfactory.newTransformer(new StreamSource(normXSL))

  def normalizeWADL(in : NodeSeq) = {
    val bytesOut = new ByteArrayOutputStream()
    transformer.transform (new StreamSource(new ByteArrayInputStream(in.toString().getBytes())), new StreamResult(bytesOut))
    XML.loadString (bytesOut.toString())
  }
}
