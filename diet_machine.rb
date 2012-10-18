# -*- coding: utf-8 -*-
require 'rubygems'
require 'mac-event-monitor'
require "uri"

class DietMachine

  class Position
    attr_reader :x, :y
    def initialize(x, y)
      @x = x
      @y = y
    end

    def distance_with(position)
      return 0 unless position
      Math.sqrt((x - position.x)**2 + (y - position.y)**2)
    end
  end

  def initialize
    @monitor = setup_monitor
    @total_types = 0
    @total_pixel = 0
    @last_position = nil
    @listeners = []

    self
  end

  def setup_monitor
    monitor = Mac::EventMonitor::Monitor.new
    monitor.add_listener(:mouse_move) do |event|
      current_position = Position.new(event.location.x, event.location.y)
      @total_pixel += current_position.distance_with(@last_position)
      @last_position = current_position

      trigger
    end

    monitor.add_listener(:key_down) do |event|
      @total_types += 1

      trigger
    end

    monitor
  end

  def run
    @monitor.run
  end

  def add_listener(&block)
    @listeners << block
  end

  def trigger
    state = {
      :pixel => @total_pixel,
      :types => @total_types,
    }
    @listeners.each{ |listener|
      listener.call state.clone
    }
  end
end

machine = DietMachine.new

pixel_unit = 10000
types_unit = 1000

pixel_total = pixel_unit
types_total = types_unit
machine.add_listener do |state|
  print '.'
  STDOUT.flush
  messages = []
  if state[:pixel] >= pixel_total
    pixel_total += pixel_unit
    messages << "#{state[:pixel].to_i}ピクセル"
  end

  if state[:types] >= types_total
    types_total += types_unit
    messages << "#{state[:types].to_i}タイプ"
  end

  unless messages.empty?
    url = 'http://github.com/hitode909/diet_machine/'
    message = "diet_machineで#{ messages.join(', ') }を達成をしました #diet_machine"
    system "open 'https://twitter.com/share?url=#{URI.escape(url)}&text=#{URI.escape(message)}'"
  end
end

machine.run
