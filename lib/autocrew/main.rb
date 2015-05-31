require 'thwait'
require 'readline'

require 'autocrew/world_state'
require 'autocrew/commander'

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
      threads = {}
      threads['solver'] ||= Thread.new { solver_thread }
      threads['main']   ||= Thread.new { main_thread }
      by_thread = threads.invert

      until threads.empty?
        thread = ThreadsWait.new(threads.values).next_wait
        name = by_thread[thread]
        puts "#{name.capitalize} thread has died."
        exit(0) if name == 'main'
        threads.delete(name)
      end
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

    def main_thread
      puts "Welcome to autocrew!"

      stty_save = `stty -g`.chomp
      begin
        while line = Readline.readline("> ")
          begin
            Commander.parse(line).execute(@state)
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
