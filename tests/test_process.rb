
class TestProcess < Test::Unit::TestCase
    def test_manual_stop
        engine = Perl::Engine.new
        assert engine.running?
        engine.stop!
        assert !engine.running?
    end

    def test_engine_dies
        engine = Perl::Engine.new
        assert engine.running?
        assert_raise Perl::EngineReadingError do
            engine.eval "exit 1"
        end
        assert !engine.running?
    end

end
