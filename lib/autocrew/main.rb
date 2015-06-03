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
      Thread.abort_on_exception = true

      threads = %w(display solver input).map do |name|
        Thread.new { send(:"#{name}_thread") }
      end

      ThreadsWait.new(threads).all_waits
    end

    def display_thread
      Display::Window.new(@state).loop
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
    end

    def input_thread
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
    end
  end
end
