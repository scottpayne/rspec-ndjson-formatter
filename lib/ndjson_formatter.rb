require "ndjson_formatter/version"
require "json"

class NdjsonFormatter
  RSpec::Core::Formatters.register self,
    :stop,
    :example_started,
    :example_passed,
    :example_group_started

  def initialize(io)
    @io = io
    @testables = {}
  end

  def example_group_started(group_notification)
    group = group_notification.group
    insert_testable({
      id: group.id,
      type: "suite",
      label: group.description,
      file: group.file_path,
      line: group.metadata[:line_number].to_i,
      children: [],
      parent_id: group_parent_id(group),
    })
  end

  def example_started(example_notification)
    ex = example_notification.example
    insert_testable({
      id: ex.id,
      type: "test",
      label: ex.description,
      file: ex.file_path,
      line: ex.metadata[:line_number],
      parent_id: example_parent_id(ex),
    })
  end

  def example_passed(example_notification)
    update_testable(example_notification.example, status: "passed")
  end

  def stop(_arg)
    dump
  end

  private

  def dump
    @io.puts JSON.dump(@top_level)
  end

  def strip_parent_id(testable)
    testable.reject { |k, _| [:parent_id].include?(k) }
  end

  def top_level?(testable)
    testable[:parent_id].nil?
  end

  def insert_testable(testable)
    parent_id = testable[:parent_id]
    parentless_testable = strip_parent_id(testable)
    if top_level?(testable)
      dump unless @top_level.nil?
      @top_level = parentless_testable
    else
      @testables[parent_id][:children] << parentless_testable
    end
    @testables[parentless_testable[:id]] = parentless_testable
  end

  def update_testable(testable, attributes)
    @testables[testable.id].merge!(attributes)
  end

  def format_id(metadata)
    return unless metadata
    "#{metadata.fetch(:file_path)}[#{metadata.fetch(:scoped_id)}]"
  end

  def example_parent_id(testable = nil)
    format_id(testable.metadata[:example_group])
  end

  def group_parent_id(testable = nil)
    return if testable.nil?
    format_id(testable.metadata[:parent_example_group])
  end
end
