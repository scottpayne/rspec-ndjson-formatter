require "ndjson_formatter/version"

class NdjsonFormatter
  RSpec::Core::Formatters.register self, :stop, :example_started, :example_group_started

  GroupCloser = Struct.new(:group_id, :proc) do
    def close(parent_id)
      if parent_id == group_id
        false
      else
        proc.call
        true
      end
    end
  end

  def initialize(io)
    @io = io
    @state = :init
    @ancestors = []
  end

  def state_table
    {
      [:init, :example_group_started] => [:inside_group, method(:append_top_level_group_closer)],
      [:inside_group, :example_group_started] => [:inside_group, method(:append_nested_group_closer)],
      [:any, :stop] => [:stopped, method(:close_all_that_need_closing)],
    }
  end

  def append_top_level_group_closer(group)
    @ancestors.push(GroupCloser.new(group.id, -> () { @io << "]}\n" }))
  end

  def append_nested_group_closer(group)
    @ancestors.push(GroupCloser.new(group.id, -> () { @io << "]}" }))
  end

  def transition(event, *args)
    entry = state_table[[@state, event]] || state_table[[:any, event]]
    return if entry.nil?

    unless entry[1].nil?
      entry[1].call(*args)
    end

    @state = entry[0]
  end

  def format_id(metadata)
    return unless metadata
    "#{metadata[:file_path]}[#{metadata[:scoped_id]}]"
  end

  def group_parent_id(testable = nil)
    return if testable.nil?
    format_id(testable.metadata[:parent_example_group])
  end

  def close_all_that_need_closing(group = nil)
    @ancestors.reverse.each do |closer|
      if closer.close(group_parent_id(group))
        @ancestors.pop
      else
        break
      end
    end
    if @ancestors.empty?
      transition(:init)
    end
  end

  def example_group_started(group_notification)
    close_all_that_need_closing(group_notification.group)
    transition(:example_group_started, group_notification.group)
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
    close_all_that_need_closing
  end
end
