
require 'timeout'

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

    def test_output_garbage
        engine = Perl::Engine.new
        assert_nothing_raised do
            timeout 0.2 do
                # If the evaluated code generates output it should not break the protocol
                engine.eval 'use IO::Handle; print " "; STDOUT->flush'
                engine.eval("1 == 1")
            end
        end
        engine.stop!
    end

end
