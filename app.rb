#!/usr/bin/env ruby


# Run the script with one of the followings params
#   csv
#   json
#   grouped_json


require 'nokogiri'

class SectionList
  def initialize
    @sections = []
    parse_files
  end

  def parse_files
    Dir.chdir('data') do
      Dir.glob('*').each do |file|
        parse_file(file)
      end
    end
    sort_sections
  end

  def sort_sections
    @sections.sort!
  end

  def parse_file(file)
    doc = Nokogiri::HTML(File.read(file))
    doc.css('.smythp').each do |section|
      add_section(section, file)
    end
  end

  def group_by_range
    last_file = nil
    sections_only.each_with_object({}) do |section, hsh|
      file = section.file
      if file != last_file
        last_file = file
        hsh[file] = [section.id_value]
      else
        hsh[file][1] = section.id_value
      end
    end
  end

  def sections_only
    @sections.select(&:is_section?)
  end

  def to_csv
    @sections.map(&:to_csv).join("\n")
  end

  def wrap_as_obj
    "{\n#{yield}\n}"
  end

  def to_json
    wrap_as_obj do
      @sections.map { |section| "  #{section.to_json}" }.join(",\n")
    end
  end

  def to_grouped_json
    wrap_as_obj do
      group_by_range.map { |r, f| "  #{r} : #{f}}" }.join(",\n")
    end
  end

  def add_section(section, file)
    @sections << Section.new(section, file)
  end
end

class Section
  attr_reader :section, :file, :id

  include Comparable

  def initialize(section, file)
    @section = section
    @file = file
    @id = @section.attr('id')
  end

  def id_value
    @id[1..-1].to_i
  end

  def <=>(other)
    if is_section? && other.is_section?
      id_value <=> other.id_value
    else
      @id <=> other.id
    end
  end

  def is_section?
    @id.start_with?('s')
  end

  def to_csv
    "#{@id},#{@file}"
  end

  def to_json
    %{"#{@id}" : "#{@file}"}
  end
end

method = "to_#{ARGV.shift}"
sections = SectionList.new

puts sections.send(method)
