package com.rackspace.cloud.api.wadl.util

import javax.xml.transform.ErrorListener
import javax.xml.transform.TransformerException
import com.typesafe.scalalogging.slf4j.LazyLogging


private object LogErrorListener {
  val trace   = "^\\[TRACE\\]\\s+(.*)".r
  val debug   = "^\\[DEBUG\\]\\s+(.*)".r
  val info    = "^\\[INFO\\]\\s+(.*)".r
  val warning = "^\\[WARNING\\]\\s+(.*)".r
  val error   = "^\\[ERROR\\]\\s+(.*)".r
}

import LogErrorListener._

class LogErrorListener extends ErrorListener with LazyLogging {

  override def error (exception : TransformerException) : Unit = {
    logger.error (exception.getMessage())
  }

  override def fatalError (exception : TransformerException) : Unit = {
    logger.error (exception.getMessage())
  }

  override def warning (exception : TransformerException) : Unit = {
    exception.getMessage() match {
      case trace(m) => logger.trace(m)
      case debug(m) =>  logger.debug(m)
      case info(m) => logger.info(m)
      case warning(m) => logger.warn(m)
      case error(m) => logger.error(m)
      case s : String => logger.warn(s)
    }
  }

}
