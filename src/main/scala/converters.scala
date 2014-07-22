package com.rackspace.cloud.api.wadl

import com.rackspace.cloud.api.wadl.util.LogErrorListener

import scala.xml._
import javax.xml.transform._
import javax.xml.transform.stream._
import java.io.ByteArrayInputStream

import net.sf.saxon.Controller
import net.sf.saxon.serialize.MessageWarner

import org.w3c.dom.NodeList
import org.w3c.dom.Node

//
//  Converters
//
object Converters {
  //
  //  Convert a node sequence to a ByteArrayInputStream
  //
  implicit def nodeSeq2ByteArrayInputStream(ns : NodeSeq) : ByteArrayInputStream = new ByteArrayInputStream(ns.toString().getBytes())


  //
  //  Convert a node sequence string touple to a ByteArrayInputStream with a system ID set
  //
  implicit def nodeSeqString2Source (nss : (String, NodeSeq)) : (String, ByteArrayInputStream) = {
    val s = nodeSeq2ByteArrayInputStream(nss._2)
    (nss._1, s)
  }

  //
  //  Convert a byte array stream result to a NodeSeq
  //
  implicit def byteArrayStreamResult2NodeSeq(sr : StreamResult) : NodeSeq = XML.loadString (sr.getOutputStream().toString())


  //
  //  Adds log error listener to a Saxon controller
  //
  implicit def toLogController(c : Controller) = new {
    def addLogErrorListener : Unit = {
      c.asInstanceOf[Transformer].setErrorListener (new LogErrorListener)
      c.setMessageEmitter(new MessageWarner())
    }
  }

  implicit def toList(nl : NodeList) : List[Node] = {
    def nodeList(nl : NodeList, curr : List[Node], i : Int) : List[Node] = {
      if (i < nl.getLength()) {
        nodeList(nl, curr ::: List(nl.item(i)), i+1)
      } else {
        curr
      }
    }

    nodeList(nl, List[Node](), 0)
  }
}
