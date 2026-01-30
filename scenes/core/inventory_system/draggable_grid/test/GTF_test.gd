class_name GdUnitExampleTest
extends GdUnitTestSuite

func test_example():
 assert_str("This is an example message")\
   .has_length(26)\
   .starts_with("This is an ex")
