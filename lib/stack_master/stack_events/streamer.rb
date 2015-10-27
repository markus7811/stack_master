module StackMaster
  class StackEvents
    class Streamer
      def self.stream(*args, &block)
        new(*args, &block).stream
      end

      def initialize(stack_name, region, from: Time.now, break_on_finish_state: true, sleep_between_fetches: 1, io: nil, &block)
        @stack_name = stack_name
        @region = region
        @block = block
        @seen_events = Set.new
        @from = from
        @break_on_finish_state = break_on_finish_state
        @sleep_between_fetches = sleep_between_fetches
        @io = io
      end

      def stream
        catch(:halt) do
          loop do
            events = Fetcher.fetch(@stack_name, @region, from: @from)
            unseen_events(events).each do |event|
              @block.call(event) if @block
              print_event(event) if @io
              if @break_on_finish_state && finish_state?(event)
                throw :halt
              end
            end
            sleep @sleep_between_fetches
          end
        end
      end

      private

      def unseen_events(events)
        [].tap do |unseen_events|
          events.each do |event|
            next if @seen_events.include?(event.event_id)
            @seen_events << event.event_id
            unseen_events << event
          end
        end
      end

      def print_event(event)
        @io.puts "#{event.timestamp} #{event.logical_resource_id} #{event.resource_type} #{event.resource_status} #{event.resource_status_reason}".colorize(event_colour(event))
      end

      def event_colour(event)
        if StackStates.failure_state?(event.resource_status)
          :red
        elsif StackStates.success_state?(event.resource_status)
          :green
        else
          :yellow
        end
      end

      def finish_state?(event)
        StackStates.finish_state?(event.resource_status) &&
          event.resource_type == 'AWS::CloudFormation::Stack' &&
          event.logical_id == @stack_name
      end
    end
  end
end
