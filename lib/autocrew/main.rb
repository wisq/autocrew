require 'thwait'
require 'readline'

require 'autocrew/world_state'
require 'autocrew/commander'
require 'autocrew/display/window'

module Autocrew
  class Main
    def initialize
      if load_name = ENV.delete('AUTOCREW_LOAD')
        @state = WorldState.load(load_name)
      else
        @state = WorldState.new
      end

      ownship = Ownship.new
      ownship.add_event Event::Initial.new(GameTime.parse("10:45"), 90, 6)
      ownship.add_event Event::BeginTurn.new(GameTime.parse("10:50"), :starboard)
      ownship.add_event Event::EndTurn.new(GameTime.parse("10:51"), 180)

      contact = Contact.new
      contact.course = 105
      contact.speed  = 4
      contact.origin = Coord.new(0, -0.1)
      contact.origin_time = GameTime.parse("10:47")

      @state.ownship = ownship
      @state.stopwatch = Stopwatch.new(GameTime.parse("10:55"))
      @state.contacts = {'s1' => contact}
      @state.focus = 's1'
    end

    def run
      @window = Display::Window.new(@state)
      Thread.new { solver_thread }
      Thread.new { main_thread }
      @window.show
    end

    def solver_thread
      loop do
        @state.contacts.each do |id, contact|
          begin
            contact.solve
          rescue StandardError => e
            puts "Error while solving #{id}: #{e}"
            puts "  (at #{e.backtrace.first})"
          end
        end

        sleep(2)
      end
    rescue Exception => e
      puts "Error in solver thread: #{e}"
      puts "  (at #{e.backtrace.first})"
    ensure
      @window.close
    end

    def main_thread
      puts "Welcome to autocrew!"
      commander = Commander.new

      stty_save = `stty -g`.chomp
      begin
        while line = Readline.readline("> ", true)
          begin
            commander.parse(line).execute(@state)
          rescue StandardError => e
            puts "Error while running command: #{e}"
            puts "  (at #{e.backtrace.first})"
          end
        end
      rescue Interrupt
        system("stty", stty_save)
        exit
      end
    rescue Exception => e
      puts "Error in main thread: #{e}"
      puts "  (at #{e.backtrace.first})"
    ensure
      @window.close
    end
  end
end
