
require 'open3'
require 'yaml'

class Perl

    # Base for every exception raised by Perl::Engine
    class EngineError < Exception; end

    # Raised when a request is to be sent but the engine is stopped
    class EngineNotRunningError < EngineError; end

    # Raised when a request has been sent but an error ocurred when the response is read
    class EngineReadingError < EngineError; end

    # Raised when an evaluated code has errors
    class EngineCodeError < EngineError; end

    # Manages an instance of the Perl interpreter. With #eval method you can execute Perl code and get the result in a Ruby object.
    # Objects are serialized using YAML, both in the Ruby and Perl side.
    class Engine

        PerlFile = File.join(File.dirname(__FILE__), "engine.pl")

        # Creates a new instance of the Perl interpreter.
        def initialize
            writer = IO.pipe
            reader = IO.pipe

            @pid = fork do
                writer[1].close
                STDIN.reopen(writer[0])
                writer[0].close

                reader[0].close
                STDOUT.reopen(reader[1])
                reader[1].close

                exec "perl", PerlFile
            end

            reader[1].close
            writer[0].close

            @stdin = reader[0]
            @stdout = writer[1]
        end

        # Check if the Perl interpreter is still alive
        def running?
            return false unless @stdin and @stdout

            if IO.select [@stdin], [], [], 0
                return false if @stdin.eof?
            end

            true
        end

        # Stop the Perl interpreter
        def stop!
            return false unless running?

            @stdin.close
            @stdout.close
            @stdin = @stdout = nil

            Process.kill "TERM", @pid
            Process.wait @pid

            true
        end

        def request(request, options = {}) # :nodoc:
            raise EngineNotRunningError, "Engine is not running" unless @stdout and @stdin

            generic_response = options.delete(:generic_response)

            data = { "request" => request.to_s }.merge!(options).to_yaml
            @stdout.print([data.length].pack("L") + data)

            data_length = @stdin.read(4).to_s
            raise EngineReadingError, "Can not read data" if data_length.length != 4

            data_length = data_length.unpack("L").first
            data = @stdin.read(data_length)
            raise EngineReadingError, "Can not read data" if data.length != data_length

            response = YAML.load data

            if generic_response
                case response["status"]
                when "ok"
                    response["result"]
                when "error"
                    raise EngineCodeError, response["error"].chomp
                end
            else
                response
            end
        end

        # Executes the given code in the Perl interpreter.
        # EngineNotRunningError will be raised if the interpreter is stopped.
        #
        # The result will be returned in a Ruby object, using YAML to transport
        # it. If an error is produced in the Perl interpreter the EngineCodeError
        # exception will be raised, with the error message generated by Perl.
        def eval(code)
            request :eval, "code" => code, :generic_response => true
        end

        # Defines a method in the Perl interpreter.
        #
        # You can access to the arguments using the normal Perl syntax:
        #  engine.define_method "add_two_values", "$_[0] + $_[1]"
        def define_method(method_name, body)
            request "define_method", "name" => method_name.to_s, "body" => body.to_s, :generic_response => true
        end

        # Invokes a method previously defined by #define_method
        #
        # Objects are passed to Perl using YAML. Everything that can be understood by YAML in both sides can be used as an argument.
        def invoke_method(method_name, *arguments)
            request "invoke_method", "name" => method_name.to_s, "arguments" => arguments, :generic_response => true
        end
    end
end

