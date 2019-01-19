require "spec_helper"
require "json"

RSpec.describe NdjsonFormatter do
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
      output = StringIO.new("", "w+")
      formatter = described_class.new(output)
      formatter.example_group_started(top_level_group)
      formatter.stop(nil)
      output.rewind
      line = output.gets
      json = JSON.parse(line)
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
      let(:output) { StringIO.new("", "w+") }
      let(:formatter) { described_class.new(output) }

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
        json = JSON.parse(line)
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
end
