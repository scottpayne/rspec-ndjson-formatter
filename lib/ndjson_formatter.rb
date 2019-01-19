require "ndjson_formatter/version"

class NdjsonFormatter
  RSpec::Core::Formatters.register self, :stop, :example_started, :example_group_started

  def initialize(io)
    @io = io
    @state = :init
  end

  def state_table
    {
      [:init, :example_group_started] => [:inside_group, nil],
      [:inside_group, :example_group_started] => [:inside_group, method(:close_group)],
      [:any, :stop] => [:stopped, method(:close_group)],
    }
  end

  def close_group
    @io << "]}\n"
  end

  def transition(event)
    entry = state_table[[@state, event]] || state_table[[:any, event]]
    return if entry.nil?

    unless entry[1].nil?
      entry[1].call
    end

    @state = entry[0]
  end

  def example_group_started(group_notification)
    transition(:example_group_started)
    group = group_notification.group
    @io << "{"
    @io << %("id": "#{group.id}", )
    @io << %("type": "suite", )
    @io << %("label": "#{group.description}", )
    @io << %("file": "#{group.file_path}", )
    # @io << %("file": "#{group.metadata[:absolute_file_path]}", )
    @io << %("line": #{group.metadata[:line_number].to_i}, )
    @io << %("children": [)
  end

  def stop(_arg)
    transition(:stop)
  end
end
