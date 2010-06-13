
class TestInvoke < Test::Unit::TestCase

    def setup
        @engine = Perl::Engine.new
    end

    def teardown
        @engine.stop!
        @engine = nil
    end

    def test_basics
        @engine.define_method "add_two_values", "$_[0] + $_[1]"
        assert_equal 3, @engine.invoke_method("add_two_values", 1, 2)
        assert_equal -20, @engine.invoke_method("add_two_values", -23, 3)
        assert_not_equal 4, @engine.invoke_method("add_two_values", 4, 2)
    end

    def test_complex_types
        @engine.define_method "get_inner_array", "$_[0]->[$_[1]]->[$_[2]]"
        assert_equal "d", @engine.invoke_method("get_inner_item", ["a", "b", ["c", "d", "e"], "f"], 2, 1)
        assert_equal [-5], @engine.invoke_method("get_inner_item", [{}, [[-5]]], 1, 0)

        @engine.define_method "get_inner_hash", "$_[0]->{$_[1]}->{$_[2]}"
        assert_equal [100], @engine.invoke_method("get_inner_hash", { "a" => 0, "b" => { "c" => [100], "d" => "e" }, "f" => [] }, "b", "c")
    end

end
