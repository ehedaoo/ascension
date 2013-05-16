require 'mharris_ext'
require 'rchoice'
require 'mongo_persist'

def playing_on_command_line?
  $playing_on_command_line = true if $playing_on_command_line.nil?
  $playing_on_command_line
end

module Ascension
  def self.load_files!
    %w(to_json ext setup).each do |f|
      load File.dirname(__FILE__) + "/ascension/#{f}.rb"
    end

    %w(debug handle_choices game turn side card cards ability pool events parse turn_manager setup_rchoice image_map).each do |f|
      load File.dirname(__FILE__) + "/ascension/#{f}.rb"
    end

    %w(basic).each do |f|
      load File.dirname(__FILE__) + "/ascension/ai/#{f}.rb"
    end
  end
end

Ascension.load_files!