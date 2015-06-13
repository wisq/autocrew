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
      ownship.add_event Event::Initial.new(GameTime.parse("10:00"), 60, 8)
      ownship.add_event Event::BeginTurn.new(GameTime.parse("10:20"), :starboard)
      ownship.add_event Event::EndTurn.new(GameTime.parse("10:21"), 130)
      ownship.add_event Event::BeginTurn.new(GameTime.parse("10:40"), :port)
      ownship.add_event Event::EndTurn.new(GameTime.parse("10:41"), 80)

      contact = Contact.new
      #contact.origin = Coord.new(1.2, 3.4)
      #contact.origin_time = GameTime.parse("10:00")
      #contact.course = 123
      #contact.speed  = 6

      contact.add_observation(ownship, GameTime.parse("10:00"), 19.440)
      contact.add_observation(ownship, GameTime.parse("10:05"), 20.450)
      contact.add_observation(ownship, GameTime.parse("10:10"), 21.993)
      contact.add_observation(ownship, GameTime.parse("10:15"), 24.635)
      contact.add_observation(ownship, GameTime.parse("10:20"), 30.160)
      contact.add_observation(ownship, GameTime.parse("10:25"), 23.209)
      contact.add_observation(ownship, GameTime.parse("10:30"), 16.619)
      contact.add_observation(ownship, GameTime.parse("10:35"), 11.191)
      contact.add_observation(ownship, GameTime.parse("10:40"), 6.718)
      contact.add_observation(ownship, GameTime.parse("10:45"), 357.571)
      contact.add_observation(ownship, GameTime.parse("10:50"), 340.383)
      contact.add_observation(ownship, GameTime.parse("10:55"), 308.636)
      contact.add_observation(ownship, GameTime.parse("11:00"), 272.378)

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
