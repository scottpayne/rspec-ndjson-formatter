require "spec_helper"
require "json"

RSpec.describe NdjsonFormatter do
  let(:output) { StringIO.new("", "w+") }
  let(:formatter) { described_class.new(output) }

  context "a top level example group" do
    let(:top_level_group) do
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

    it "outputs on a new line" do
      formatter.example_group_started(top_level_group)
      formatter.stop(nil)
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
      before do
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

    before { print_examples }

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
end
