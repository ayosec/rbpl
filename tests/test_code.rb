
class TestCode < Test::Unit::TestCase

    def setup
        @engine = Perl::Engine.new
    end

    def teardown
        @engine.stop!
        @engine = nil
    end


    def test_errors
        assert_raise(Perl::EngineCodeError) { @engine.eval "foo + bar" };
        assert_raise(Perl::EngineCodeError) { @engine.eval "foo bar" };
        assert_nothing_raised { @engine.eval "1" };
    end

    def test_basics
        assert_equal 15, @engine.eval("10 + 5")
        assert_equal 6, @engine.eval("length('foobar')")
        assert_nil @engine.eval("undef")
    end

    def test_session
        assert_equal 20, @engine.eval("$SESSION{foo} = 20")
        assert_equal 21, @engine.eval("++$SESSION{foo}")
        assert_equal 22, @engine.eval("++$SESSION{foo}")
        assert_equal 22, @engine.eval("$SESSION{foo}")
    end

    def test_blocks
        assert_equal -1, @engine.eval(%[
            {
                my $foo = 100;
                $foo - 101;
            }
        ])
    end

end
