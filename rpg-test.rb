# encoding: utf-8

require_relative "./ui-accessor/ui-accessor.rb"
require_relative "./rpg-base.rb"
require "pp"

module RPGTest
  module App
    class Main
      def initialize
        @app = UIAccessor::App.new(false)
        script()
      end

      def script
        @app.script do
          function("open") {
            puts "opened"
          }

          function("load") {
            puts "loaded"
            @maps = RPG::Map::Bundle.new
            @maps.load_file("./").construct_bundle
            puts "map loaded"
            # binding.pry
            sheet = @maps.sheet("main")
            raise "ERROR:  no map loaded" unless sheet
            @renderer = RPGTest::Renderer::Map.new(sheet, self)
            puts "renderer loaded"
            @renderer.show
          }

          function("close") {
            puts "closed"
          }
        end
      end

      def run
        @app.start
      end
    end
  end

  module Renderer
    class Map
      def initialize(map_sheet, tr)
        # binding.pry
        @map = map_sheet
        @map_area_elm = []
        @row_tiles_elm = []
        @tile_elm = []
        @tr = tr
        @map_area_elm = @tr.jquery("#map_area")
        p @map_area_elm
      end

      def show
        # binding.pry
        @map.tiles.reverse.each_with_index { |y_tiles, y|
          @map_area_elm.prepend("<div id='row_tiles_container_#{y}' class='row_tiles_container'></div>")
          @row_tiles_elm[y] = @tr.jquery("#row_tiles_container_#{y}")
          # puts y
          y_tiles.reverse.each_with_index { |tile, x|
            # puts x
            @tile_elm[y] ||= []
            @row_tiles_elm[y].prepend("<div id='tile_#{y}_#{x}' class='tile'></div>")
            @tile_elm[y][x] = @tr.jquery("#tile_#{y}_#{x}")
            @tile_elm[y][x].css({
              "background-image" => "url(./#{tile.object}.png)"
            })
          }
        }
      end
    end

    class Char
      
    end

    class Prompt
      
    end
  end
end

rpg_app = RPGTest::App::Main.new
puts "app loaded"
rpg_app.run
