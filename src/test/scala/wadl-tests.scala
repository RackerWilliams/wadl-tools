package com.rackspace.cloud.api.wadl.test

import org.junit.runner.RunWith
import org.scalatest.junit.JUnitRunner
import org.scalatest.FeatureSpec

@RunWith(classOf[JUnitRunner])
class BaseWADLSpec extends FeatureSpec {
  feature ("The WADL normalizer can convert a WADL resources into a tree format") {
    scenario ("The original WADL is in the path format") (pending)
    scenario ("The original WADL is already in a tree format") (pending)
    scenario ("The original WADL is in mixed path/tree format") (pending)
  }
}
