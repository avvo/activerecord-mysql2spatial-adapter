#
# Tests for the Mysql2Spatial ActiveRecord adapter
#
# Copyright 2010 Daniel Azuma
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the copyright holder, nor the names of any other
#   contributors to this software, may be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require_relative './test_helper'
require 'minitest/autorun'

module RGeo
  module ActiveRecord  # :nodoc:
    module Mysql2SpatialAdapter  # :nodoc:
      module Tests  # :nodoc:
        class TestBasic < ::ActiveSupport::TestCase  # :nodoc:

          DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database.yml'

          def test_version
            refute_nil(::ActiveRecord::ConnectionAdapters::Mysql2SpatialAdapter::VERSION)
          end

          def test_create_simple_geometry
            SpatialModel.create_table do |t|
              t.column 'latlon', :geometry
            end
            assert_equal(::RGeo::Feature::Geometry, SpatialModel.columns.last.geometric_type)
            assert(SpatialModel.column_names.include?('latlon'))
          end

          def test_create_point_geometry
            SpatialModel.create_table do |t|
              t.column 'latlon', :point
            end
            assert_equal(::RGeo::Feature::Point, SpatialModel.columns.last.geometric_type)
            assert(SpatialModel.column_names.include?('latlon'))
          end

          def test_create_polygon_geometry
            SpatialModel.create_table do |t|
              t.column 'latlon', :polygon
            end
            assert_equal(::RGeo::Feature::Polygon, SpatialModel.columns.last.geometric_type)
            assert(SpatialModel.column_names.include?('latlon'))
          end

          def test_create_multipolygon_geometry
            SpatialModel.create_table do |t|
              t.column 'latlon', :multipolygon
            end
            assert_equal(::RGeo::Feature::MultiPolygon, SpatialModel.columns.last.geometric_type)
            assert(SpatialModel.column_names.include?('latlon'))
          end

          def test_create_geometry_with_index
            SpatialModel.create_table(options: 'ENGINE=MyISAM') do |t|
              t.column 'latlon', :geometry, null: false
            end
            SpatialModel.change_table do |t|
              t.index([:latlon], spatial: true)
            end
            assert(SpatialModel.connection.indexes(:spatial_models).last.spatial)
          end

          def test_set_and_get_point
            obj = SpatialModel.build
            assert_nil(obj.latlon)
            obj.latlon = factory.point(1, 2)
            obj.save!
            obj.reload
            assert_equal(factory.point(1, 2), obj.latlon)
            assert_equal(3785, obj.latlon.srid)
          end

          def test_set_and_get_point_from_wkt
            obj = SpatialModel.build
            assert_nil(obj.latlon)
            obj.latlon = 'SRID=1000;POINT(1 4)'
            obj.save!
            obj.reload
            assert_equal(factory.point(1, 4), obj.latlon)
            assert_equal(1000, obj.latlon.srid)
          end

          def test_save_and_load_point
            obj = SpatialModel.build
            obj.latlon = factory.point(1, 2)
            obj.save!
            id = obj.id
            obj2 = SpatialModel.find(id)
            assert_equal(factory.point(1, 2), obj2.latlon)
            assert_equal(3785, obj2.latlon.srid)
          end

          def test_save_and_load_point_from_wkt
            obj = SpatialModel.build
            obj.latlon = 'SRID=1000;POINT(1 2)'
            obj.save!
            id = obj.id
            obj2 = SpatialModel.find(id)
            assert_equal(factory.point(1, 2), obj2.latlon)
            assert_equal(1000, obj2.latlon.srid)
          end

          def test_readme_example
            skip
            SpatialModel.create_table(options: 'ENGINE=MyISAM') do |t|
              t.column(:latlon, :point, null: false)
              t.line_string(:path)
              t.geometry(:shape)
            end
            SpatialModel.change_table do |t|
              t.index(:latlon, spatial: true)
            end

            SpatialModel.class_eval do
              self.rgeo_factory_generator = ::RGeo::Geos.method(:factory)
              set_rgeo_factory_for_column(:latlon, ::RGeo::Geographic.spherical_factory)
            end
            obj = SpatialModel.build
            obj.latlon = 'POINT(-122 47)'
            loc = obj.latlon
            assert_equal(47, loc.latitude)
            obj.shape = loc
            assert_equal(true, ::RGeo::Geos.is_geos?(obj.shape))
          end

          def test_create_simple_geometry_using_shortcut
            SpatialModel.create_table do |t|
              t.geometry 'latlon'
            end
            assert_equal(::RGeo::Feature::Geometry, SpatialModel.columns.last.geometric_type)
            assert(SpatialModel.column_names.include?('latlon'))
          end

          def test_create_point_geometry_using_shortcut
            SpatialModel.create_table do |t|
              t.point 'latlon'
            end
            assert_equal(::RGeo::Feature::Point, SpatialModel.columns.last.geometric_type)
            assert(SpatialModel.column_names.include?('latlon'))
          end

          def test_create_geometry_using_limit
            SpatialModel.create_table do |t|
              t.spatial 'geom', limit: { type: :line_string }
            end
            assert_equal(::RGeo::Feature::LineString, SpatialModel.columns.last.geometric_type)
            assert(SpatialModel.column_names.include?('geom'))
          end
        end
      end
    end
  end
end
