require 'minitest/autorun'
require 'active_record'

DATABASE_CONFIG_PATH = File.dirname(__FILE__) << '/database.yml'

class SpatialModel < ActiveRecord::Base
  establish_connection YAML.load_file(DATABASE_CONFIG_PATH)

  def self.create_table(options = {})
    return if connection.table_exists?(table_name)

    connection.create_table(table_name, options) do |t|
      yield t
    end

    SpatialModel.reset_column_information
    SpatialModel
  end

  def self.change_table
    SpatialModel.connection.change_table(table_name) do |t|
      yield t
    end

    SpatialModel.reset_column_information
    SpatialModel
  end

  def self.build(geometric_name: 'latlon', geometric_type: :point)
    create_table do |t|
      t.column geometric_name, geometric_type
    end
    new
  end
end

class ActiveSupport::TestCase
  self.test_order = :random

  def factory
    RGeo::Cartesian.preferred_factory(srid: 3785)
  end

  def geographic_factory
    RGeo::Geographic.spherical_factory(srid: 4326)
  end

  def teardown
    SpatialModel.connection.drop_table(:spatial_models) if SpatialModel.connection.table_exists?('spatial_models')
  end
end
