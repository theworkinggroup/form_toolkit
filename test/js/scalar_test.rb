require '../../test_init'
require 'form_toolkit/js/scalar'

class FormToolkit::Js::ScalarTest < Test::Unit::TestCase
  def test_create
    assert_equal 'test', FormToolkit::Js::Scalar.new('test').to_s
  end

  def test_array_access
    assert_equal 'test[0]', FormToolkit::Js::Scalar.new('test')[0].to_s
    assert_equal 'test[0,1]', FormToolkit::Js::Scalar.new('test')[0,1].to_s
    assert_equal "test['foo']", FormToolkit::Js::Scalar.new('test')['foo'].to_s
    assert_equal "test['foo'].hide()", FormToolkit::Js::Scalar.new('test')['foo'].hide.to_s
  end

  def test_method_call
    assert_equal 'test.hide()', FormToolkit::Js::Scalar.new('test').hide.to_s
    assert_equal 'test.hide(true)', FormToolkit::Js::Scalar.new('test').hide(true).to_s
    assert_equal "test.hide(1,'foo',false)", FormToolkit::Js::Scalar.new('test').hide(1,'foo',false).to_s
  end
  
  def test_to_json
    assert_equal '"test"', FormToolkit::Js::Scalar.new('test').to_json
  end
end
