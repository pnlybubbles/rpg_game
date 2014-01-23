# encoding: utf-8

require "pry"

module RPG
  module Map
    class Loader
      def load_file(directory)
        @map_files = []
        @map_names = []
        @map_files_dir = Dir::glob(File.expand_path(directory) + "/*_map.json")
        @map_files_dir.each_with_index { |dir, i|
          @map_files[i] = JSON.parse(File.read(dir))
          @map_names[i] = dir.match(/\/(?<name>[^\/]+)_map.json$/)["name"]
        }
        return self
      end
    end

    class Bundle < Loader
      attr_reader :maps

      def initialize
        @maps = []
      end

      def construct_bundle
        @map_files.each_with_index { |data, i|
          @maps[i] = Sheet.new(@map_names[i], data["object_data"], data["type_data"], data["action_data"])
        }
        return self
      end

      def sheet(name)
        maps_index = @map_names.index(name)
        return maps_index ? @maps[maps_index] : nil
      end
    end

    class Sheet
      attr_reader :columns, :rows, :tiles

      def initialize(name, objects_data, type_data, action_data)
        @tiles = []
        @name = name
        if objects_data.length != type_data.length && objects_data.length != action_data.length
          raise "ERROR: map size mismatched : y"
        elsif [objects_data, type_data, action_data].map { |w| w.inject(0) { |r, v| r += v.length != objects_data[0].length ? 1 : 0 } }.max != 0
          raise "ERROR: map size mismatched : x"
        end
        @rows = objects_data.length
        @columns = objects_data[0].length
        @objects_data = objects_data
        @type_data = type_data
        @action_data = action_data
        # @objects_data = [["glass", "glass", "glass", "glass"], ["stone", "glass", "stone", "stone"], ["glass", "glass", "glass", "glass"], ["glass", "glass", "glass", "glass"]]
        # @type_data = [[0, 0, 0, 0], [1, 0, 1, 1], [0, 0, 0, 0], [0, 0, 0, 0]]
        # @action_data = [[{"touch" => {"nesw" => "move_map"}}, nil, nil, nil], [nil ,nil, nil, nil], [nil ,nil, nil, nil], [nil ,nil, nil, nil]]
        @objects_data.each_with_index { |objects_data_y, y|
          objects_data_y.each_with_index { |object, x|
            @tiles[y] ||= []
            @tiles[y][x] = Tile.new(object, @type_data[y][x], @action_data[y][x])
          }
        }
      end
    end

    class Tile
      attr_reader :object, :type

      def initialize(object, type, action)
        @object = object
        @type = type
        @action = action
        if @action
          @action.each { |action, cont|
            self.class.class_eval {
              define_method(action) { |direction|
                cont.each { |direction_str, method|
                  if direction_str =~ /#{direction}/
                    send(method) ### target object not defined
                  end
                }
              }
            }
          }
        end
      end
    end
  end

  module Person
    class Char
      
    end

    class NPC < Char
      
    end

    class Enemy < Char
      
    end

    class Ally < Char
      
    end
  end
end
