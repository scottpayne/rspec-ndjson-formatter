require "spec_helper"
require "json"

RSpec.describe NdjsonFormatter do
  let(:example_json) do
    {
      "id" => "example_id",
      "type" => "test",
      "label" => "This is some example",
      "file" => top_level_group.group.file_path,
      "line" => 20,
    }
  end

  let(:output) { StringIO.new("", "w+") }
  let(:formatter) { described_class.new(output) }

  before { print_examples }

  let(:top_level_group) do
    double(:group_notification,
           group: double(
             :group,
             id: "./spec/top_level_spec.rb[1]",
             description: "top level",
             file_path: "./spec/top_level_spec.rb",
             metadata: {
               file_path: "./spec/top_level_spec.rb",
               line_number: 2,
               parent_example_group: nil,
               scoped_id: "1",
             },
           ))
  end

  context "a top level example group" do
    def print_examples
      formatter.example_group_started(top_level_group)
      formatter.stop(nil)
    end

    it "outputs on a new line" do
      output.rewind
      line = output.gets
      json = JSON.parse(line) rescue pending("Unparseable line: #{line}")
      expect(json).to eq(
        "id" => "./spec/top_level_spec.rb[1]",
        "type" => "suite",
        "label" => "top level",
        "file" => "./spec/top_level_spec.rb",
        "line" => 2,
        "children" => [],
      )
    end

    context "following from an existing top level group" do
      let(:second_top_level_group) do
        double(:group_notification,
               group: double(
                 :group,
                 id: "./spec/second_top_level_spec.rb[1]",
                 description: "second top level",
                 file_path: "./spec/second_top_level_spec.rb",
                 metadata: {
                   line_number: 3,
                   parent_example_group: nil,
                   scoped_id: "1",
                 },
               ))
      end

      def print_examples
        formatter.example_group_started(top_level_group)
        formatter.example_group_started(second_top_level_group)
        formatter.stop(nil)
      end

      it "closes the first group" do
        output.rewind
        line = output.gets
        expect { JSON.parse(line) }.not_to raise_error
      end

      it "outputs the second group on a new line" do
        output.rewind
        lines = output.readlines
        line = lines[1]
        json = JSON.parse(line) rescue pending("Unparsable line: #{line}")
        expect(json).to eq(
          "id" => "./spec/second_top_level_spec.rb[1]",
          "type" => "suite",
          "label" => "second top level",
          "file" => "./spec/second_top_level_spec.rb",
          "line" => 3,
          "children" => [],
        )
      end
    end
  end

  context "a nested example group" do
    let(:first_top_level_group) do
      double(:group_notification,
             group: double(
               :group,
               id: "./spec/top_level_spec.rb[1]",
               description: "top level",
               file_path: "./spec/top_level_spec.rb",
               metadata: {
                 line_number: 2,
                 parent_example_group: nil,
                 scoped_id: "1",
               },
             ))
    end
    let(:nested_example_group) do
      double(:group_notification,
             group: double(
               :group,
               id: "./spec/top_level_spec.rb[1:1]",
               description: "nested",
               file_path: "./spec/top_level_spec.rb",
               metadata: {
                 line_number: 4,
                 parent_example_group: {
                   file_path: "./spec/top_level_spec.rb",
                   scoped_id: "1",
                 },
                 scoped_id: "1:1",
               },
             ))
    end

    def print_examples
      formatter.example_group_started(first_top_level_group)
      formatter.example_group_started(nested_example_group)
      formatter.stop(nil)
      output.rewind
    end

    it "only prints a single line" do
      expect(output.readlines.size).to eq(1)
    end

    it "prints a parseable json string" do
      expect { JSON.parse(output.gets) }.not_to raise_error
    end

    it "prints the top level group with the nested child group" do
      line = JSON.parse(output.gets) rescue pending("unparsable")
      expect(line["children"]).to eq([
        "id" => "./spec/top_level_spec.rb[1:1]",
        "type" => "suite",
        "label" => "nested",
        "file" => "./spec/top_level_spec.rb",
        "line" => 4,
        "children" => [],
      ])
    end

    context "when followed by a top level example group" do
      let(:second_top_level_group) do
        double(:group_notification,
               group: double(
                 :group,
                 id: "./spec/second_top_level_spec.rb[1]",
                 description: "second top level",
                 file_path: "./spec/second_top_level_spec.rb",
                 metadata: {
                   line_number: 3,
                   parent_example_group: nil,
                   scoped_id: "1",
                 },
               ))
      end

      def print_examples
        formatter.example_group_started(first_top_level_group)
        formatter.example_group_started(nested_example_group)
        formatter.example_group_started(second_top_level_group)
        formatter.stop(nil)
        output.rewind
      end

      it "prints the following top level example group on a new line" do
        line = output.readlines[1]
        pending("wrong number of lines printed") if line.nil?
        parsed = JSON.parse(line) rescue pending("Invalid JSON")
        expect(parsed).to eq(
          "id" => "./spec/second_top_level_spec.rb[1]",
          "type" => "suite",
          "label" => "second top level",
          "file" => "./spec/second_top_level_spec.rb",
          "line" => 3,
          "children" => [],
        )
      end
    end
  end

  shared_examples "n lines" do |number_of_lines|
    it "results in #{number_of_lines} lines of output" do
      expect(output.readlines.size).to eq(number_of_lines)
    end
  end

  shared_examples "parseable JSON" do |line_number|
    it "results in a parseable JSON line of JSON at line #{line_number}" do
      line = output.readlines[line_number - 1]
      expect { JSON.parse(line) }.not_to raise_error, "line: #{line}"
    end
  end

  context "an example nested in a top level group" do
    let(:example) do
      double(:example_notification,
             example: double(
               :example,
               id: "example_id",
               description: "This is some example",
               file_path: top_level_group.group.file_path,
               metadata: {
                 line_number: 20,
                 example_group: top_level_group.group.metadata,
               },
             ))
    end

    def print_examples
      formatter.example_group_started(top_level_group)
      formatter.example_started(example)
      formatter.stop(nil)
      output.rewind
    end

    include_examples "n lines", 1
    include_examples "parseable JSON", 1

    it "is nested in the top level group" do
      line = JSON.parse(output.gets) rescue pending("Unparseable JSON")
      expect(line["children"].first).to eq(
        "id" => "example_id",
        "type" => "test",
        "label" => "This is some example",
        "file" => top_level_group.group.file_path,
        "line" => 20,
      )
    end

    context "followed by another example in the same group" do
      let(:second_example) do
        double(:example_notification,
               example: double(
                 :example,
                 id: "second_example_id",
                 description: "This is another example",
                 file_path: top_level_group.group.file_path,
                 metadata: {
                   line_number: 25,
                   example_group: top_level_group.group.metadata,
                 },
               ))
      end

      def print_examples
        formatter.example_group_started(top_level_group)
        formatter.example_started(example)
        formatter.example_started(second_example)
        formatter.stop(nil)
        output.rewind
      end

      include_examples "n lines", 1
      include_examples "parseable JSON", 1

      it "prints the second example after the first" do
        json = JSON.parse(output.gets) rescue pending("Unparseable JSON")
        expect(json["children"][1]).to eq(
          "id" => "second_example_id",
          "type" => "test",
          "label" => "This is another example",
          "file" => top_level_group.group.file_path,
          "line" => 25,
        )
      end
    end
  end

  context "a group with an example followed by a nested group" do
    let(:example) do
      double(:example_notification,
             example: double(
               :example,
               id: "example_id",
               description: "This is some example",
               file_path: top_level_group.group.file_path,
               metadata: {
                 line_number: 20,
                 example_group: top_level_group.group.metadata,
               },
             ))
    end
    let(:nested_example_group) do
      double(:group_notification,
             group: double(
               :group,
               id: "./spec/top_level_spec.rb[1:1]",
               description: "nested",
               file_path: "./spec/top_level_spec.rb",
               metadata: {
                 line_number: 4,
                 parent_example_group: top_level_group.group.metadata,
                 scoped_id: "1:1",
               },
             ))
    end

    def print_examples
      formatter.example_group_started(top_level_group)
      formatter.example_started(example)
      formatter.example_group_started(nested_example_group)
      formatter.stop(nil)
      output.rewind
    end

    include_examples "n lines", 1
    include_examples "parseable JSON", 1

    it "has the nested group as the second child of the top level group" do
      json = JSON.parse(output.gets) rescue pending("Unparseable JSON")
      expect(json["children"][1]).to eq(
        "id" => "./spec/top_level_spec.rb[1:1]",
        "type" => "suite",
        "label" => "nested",
        "file" => "./spec/top_level_spec.rb",
        "line" => 4,
        "children" => [],
      )
    end
  end

  let(:example) do
    double(:example_notification,
           example: double(
             :example,
             id: "example_id",
             description: "This is some example",
             file_path: top_level_group.group.file_path,
             metadata: {
               line_number: 20,
               example_group: top_level_group.group.metadata,
             },
           ))
  end
  let(:nested_example_group) do
    double(:group_notification,
           group: double(
             :group,
             id: "./spec/top_level_spec.rb[1:1]",
             description: "nested",
             file_path: "./spec/top_level_spec.rb",
             metadata: {
               line_number: 4,
               parent_example_group: top_level_group.group.metadata,
               scoped_id: "1:1",
               file_path: "./spec/top_level_spec.rb",
             },
           ))
  end

  let(:nested_example) do
    double(:example_notification,
           example: double(
             :example,
             id: "nested_example_id",
             description: "this is a nested example",
             file_path: nested_example_group.group.file_path,
             metadata: {
               line_number: 47,
               example_group: nested_example_group.group.metadata,
             },
           ))
  end
  let(:nested_example_json) do
    {
      "id" => "nested_example_id",
      "type" => "test",
      "label" => "this is a nested example",
      "file" => nested_example_group.group.file_path,
      "line" => 47,
    }
  end

  let(:nested_example_group_json) do
    {
      "id" => "./spec/top_level_spec.rb[1:1]",
      "type" => "suite",
      "label" => "nested",
      "file" => "./spec/top_level_spec.rb",
      "line" => 4,
      "children" => [],
    }
  end

  context "a group with a nested group followed by an example" do
    def print_examples
      formatter.example_group_started(top_level_group)
      formatter.example_group_started(nested_example_group)
      formatter.example_started(example)
      formatter.stop(nil)
      output.rewind
    end

    include_examples "n lines", 1
    include_examples "parseable JSON", 1

    it "has the nested group as the first child of the top level group" do
      json = JSON.parse(output.gets) rescue pending("Unparseable JSON")
      expect(json["children"][0]).to eq(nested_example_group_json)
    end

    it "has the example as the second child of the top level group" do
      json = JSON.parse(output.gets) rescue pending("Unparseable JSON")
      expect(json["children"][1]).to eq(example_json)
    end
  end

  context "an example in a nested group, followed by a top level example" do
    def print_examples
      formatter.example_group_started(top_level_group)
      formatter.example_group_started(nested_example_group)
      formatter.example_started(nested_example)
      formatter.example_started(example)
      formatter.stop(nil)
      output.rewind
    end

    include_examples "n lines", 1
    include_examples "parseable JSON", 1

    it "has the nested example as a child of the nested example group" do
      parsed_json = JSON.parse(output.gets) rescue pending("Unparsable JSON")
      expect(parsed_json["children"][0]["children"][0]).to eq(nested_example_json)
    end
  end

  context "example results" do
    context "when an example passes" do
      def print_examples
        formatter.example_group_started(top_level_group)
        formatter.example_started(example)
        formatter.example_passed(example)
        formatter.stop(nil)
        output.rewind
      end

      it "outputs a status of passed" do
        parsed_json = JSON.parse(output.gets) rescue pending("Unparsable JSON")
        expect(parsed_json["children"][0]["status"]).to eq("passed")
      end
    end
  end
end
