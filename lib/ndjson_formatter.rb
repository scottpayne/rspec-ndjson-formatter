require "ndjson_formatter/version"

class NdjsonFormatter
  RSpec::Core::Formatters.register self, :stop, :example_started, :example_group_started

  GroupCloser = Struct.new(:group_id, :callable) do
    def close(parent_id)
      if parent_id == group_id
        false
      else
        callable.call
        true
      end
    end
  end

  def initialize(io)
    @io = io
    @ancestors = []
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
  end

  def example_group_started(group_notification)
    close_all_that_need_closing(group_notification.group)
    append_closer(group_notification.group)
    group = group_notification.group
    @io << "{"
    @io << %("id": "#{group.id}", )
    @io << %("type": "suite", )
    @io << %("label": "#{group.description}", )
    @io << %("file": "#{group.file_path}", )
    @io << %("line": #{group.metadata[:line_number].to_i}, )
    @io << %("children": [)
  end

  def example_started(example_notification)
    ex = example_notification.example
    @io << "{"
    @io << %("id": "#{ex.id}", )
    @io << %("type": "test", )
    @io << %("label": "#{ex.description}", )
    @io << %("file": "#{ex.file_path}", )
    @io << %("line": #{ex.metadata[:line_number]} )
    @io << "}"
  end

  def stop(_arg)
    close_all_that_need_closing
  end

  private

  def append_closer(group)
    if @ancestors.empty?
      append_top_level_group_closer(group)
    else
      append_nested_group_closer(group)
    end
  end

  def append_top_level_group_closer(group)
    @ancestors.push(GroupCloser.new(group.id, -> () { @io << "]}\n" }))
  end

  def append_nested_group_closer(group)
    @ancestors.push(GroupCloser.new(group.id, -> () { @io << "]}" }))
  end
end
