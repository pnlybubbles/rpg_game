# encoding: utf-8

require "em-websocket"
require "json"
require "thread"
# require "pp"
# require "pry"

module UIAccessor
  class Transfer
    def initialize(ws)
      @ws = ws
      @callback_queue = {}
    end

    def tell(msg, *callback)
      # p msg
      # p callback
      callback_id = nil
      if !callback.empty? && callback[0]
        callback_id = rand(36**4).to_s(36)
        @callback_queue[callback_id] = Queue.new
      end
      whole_msg = {"content" => msg, "callback_id" => callback_id}
      @ws.send(JSON.generate(whole_msg).to_s)
      return @callback_queue[callback_id] if callback_id
    end

    def get(req)
      Thread.new {
        begin
          case
          when req["event"]
            e = req["event"]
            e['elementId'] = "null" unless e['elementId']
            self.send("elm_#{e['elementId']}_evt_#{e['type']}", e)
          when req["callback"]
            e = req["callback"]
            @callback_queue[e["callback_id"]].push(e["content"])
          end
        rescue Exception => e
          puts e
          puts e.backtrace
        end
      }
    end

    def function(event_type, event_element = nil)
      raise "Error: no block given." unless block_given?
      event_element = "null" if event_element.nil?
      self.class.class_eval do
        define_method("elm_#{event_element}_evt_#{event_type}") { |e|
          yield(e)
        }
      end
    end

    def eval_js(str)
      msg = {"type" => "eval", "argu" => str}
      ret = tell(msg, true).pop
    end

    def jquery(selector)
      return JQuery.new(selector, self)
    end

    def method_missing(meth, *args, &blk)
      puts "method_missing : #{meth}"
    end
  end

  class JQuery
    attr_reader :trid, :selector

    def initialize(selector, tr)
      @tr = tr
      @selector = selector
      @trid = rand(36**8).to_s(36)
      msg = {"type" => "jquery", "argu" => {"method" => "add", "trid" => @trid, "param" => {"selector" => @selector}}}
      ret = @tr.tell(msg, true).pop
      unless ret
        @trid = nil
        raise "ERROR: no jquery object matched selector."
      end
    end

    def bind(event)
      msg = {"type" => "jquery", "argu" => {"method" => "bind", "trid" => @trid, "param" => {"event" => event}}}
      ret = @tr.tell(msg, true).pop
      unless ret
        @trid = nil
        raise "ERROR: no jquery object matched selector."
      end
    end

    def method_missing(meth, *args)
      # binding.pry
      param = args.map { |v|
        if v.class == UIAccessor::JQuery
          {"jquery_obj" => {"trid" => v.trid}}
        else
          v
        end
      }
      # pp param
      msg = {"type" => "jquery", "argu" => {"method" => meth, "trid" => @trid, "param" => param}}
      ret = @tr.tell(msg, true).pop
      unless ret
        @trid = nil
        raise "ERROR: no jquery object matched selector."
      end
    end
  end

  class App
    def initialize(debug = false)
      @tr = nil
      @script = nil
      @debug = debug
    end

    def script(&blk)
      @script = blk
    end

    def start
      EM::WebSocket.start(:host => "localhost", :port => 8080, :debug => @debug) do |ws|
        ws.onopen {
          @tr = Transfer.new(ws)
          @tr.instance_eval(&@script)
          @tr.send("elm_null_evt_open", nil)
        }

        ws.onmessage { |msg|
          @tr.get(JSON.parse(msg))
        }

        ws.onclose {
          @tr.send("elm_null_evt_close", nil)
        }
      end
    end
  end
end

# app = UIAccessor::App.new

# app.script do
#   function("open", nil) { |e|
#     puts "opened"
#   }

#   function("load", nil) { |e|
#     elm = jquery(".test")
#     # binding.pry
#     puts "added"
#     elm.css({
#       "height" => "100px",
#       "background-color" => "#FF0000"
#     })
#     puts "changed style"
#     elm.append("<span class='tt'>Hello</span>")
#     # puts "append"
#     # elm2 = jquery(".tt")
#     # puts "added"
#     elm.attr("id", "test")
#     elm.bind("click")
#     # elm.wrap(elm2)
#   }

#   function("click", "test") { |e|
#     puts "clicked"
#   }
# end

# app.start
