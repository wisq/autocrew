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
        while line = Readline.readline("> ")
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
