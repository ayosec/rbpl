
require 'open3'
require 'yaml'

class Perl
    class EngineError < Exception; end
    class EngineNotRunningError < EngineError; end
    class EngineReadingError < EngineError; end
    class EngineCodeError < EngineError; end

    class Engine

        PerlFile = File.join(File.dirname(__FILE__), "engine.pl")

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

        def running?
            return false unless @stdin and @stdout

            if IO.select [@stdin], [], [], 0
                return false if @stdin.eof?
            end

            true
        end

        def stop!
            return false unless running?

            @stdin.close
            @stdout.close
            @stdin = @stdout = nil

            Process.kill "TERM", @pid
            Process.wait @pid

            true
        end

        def request(request, options = {})
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

        def eval(code)
            request :eval, "code" => code, :generic_response => true
        end

        def define_method(method_name, body)
            request "define_method", "name" => method_name.to_s, "body" => body.to_s, :generic_response => true
        end

        def invoke_method(method_name, *arguments)
            request "invoke_method", "name" => method_name.to_s, "arguments" => arguments, :generic_response => true
        end
    end
end

