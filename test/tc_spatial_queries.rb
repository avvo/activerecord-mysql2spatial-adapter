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

module RGeo
  module ActiveRecord  # :nodoc:
    module Mysql2SpatialAdapter  # :nodoc:
      module Tests  # :nodoc:
        class TestSpatialQueries < ActiveSupport::TestCase  # :nodoc:
          def test_query_point
            obj = SpatialModel.build
            obj.latlon = factory.point(1, 2)
            obj.save!

            obj2 = SpatialModel.where(latlon: factory.point(1, 2)).first
            assert_equal(obj.id, obj2.id)
            obj3 = SpatialModel.where(latlon: factory.point(2, 2)).first
            assert_nil(obj3)
          end

          def _test_query_point_wkt
            obj = SpatialModel.build
            obj.latlon = factory.point(1, 2)
            obj.save!

            obj2 = SpatialModel.where(latlon: 'POINT(1 2)').first
            assert_equal(obj.id, obj2.id)
            obj3 = klass_.where(latlon: 'POINT(2 2)').first
            assert_nil(obj3)
          end

          def test_query_st_length
            obj = SpatialModel.build(geometric_name: 'path', geometric_type: :line_string)
            obj.path = factory.line(factory.point(1, 2), factory.point(3, 2))
            obj.save!

            obj2 = SpatialModel.where(SpatialModel.arel_table[:path].st_length.eq(2)).first
            assert_equal(obj.id, obj2.id)

            obj3 = SpatialModel.where(SpatialModel.arel_table[:path].st_length.gt(3)).first
            assert_nil(obj3)
          end

          def test_query_st_contains
            obj = SpatialModel.build(geometric_name: 'area', geometric_type: :polygon)
            obj.area = geographic_factory.polygon(
              factory.linear_ring(
                [factory.point(0, 1), factory.point(3, 4), factory.point(8, 9)]
              )
            )
            obj.save!
            obj2 = SpatialModel.where(
              SpatialModel.arel_table[:area].st_contains(
                Arel.sql("st_geomfromtext('POINT(2 4)', 4326)")
              )
            ).first
            assert_equal(obj.id, obj2.id)

            obj3 = SpatialModel.where(
              SpatialModel.arel_table[:area].st_contains(
                Arel.sql("st_geomfromtext('POINT(11 12)', 4326)")
              )
            ).first
            assert_nil(obj3)
          end
        end
      end
    end
  end
end
