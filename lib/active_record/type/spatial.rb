module ActiveRecord
  module Type
    class Spatial < Value # :nodoc:
      def initialize(sql_type)
        @sql_type = sql_type
        @geo_type = sql_type
      end

      def type
        :spatial
      end

      def spatial?
        true
      end

      def spatial_factory(srid: nil)
        RGeo::ActiveRecord::SpatialFactoryStore.instance.factory(
          geo_type: @geo_type,
          sql_type: @sql_type,
          srid:     srid,
        )
      end

      def changed?(old_value, new_value, _new_value_before_type_cast)
        old_value.to_s != new_value.to_s || old_value&.srid != new_value.srid
      end

      def serialize(value)
        return if value.nil?

        geo_value = type_cast(value)
        RGeo::WKRep::WKBGenerator.new(hex_format: true, little_endian: true).generate(geo_value)
      end

      private

      def cast_value(value)
        return if value.nil?

        value.is_a?(::String) ? parse_wkt(value) : value
      end

      def parse_wkt(string)
        marker = string[4, 1]
        if %(\x00 \x01).include?(marker)
          srid = string[0, 4].unpack1(marker == "\x01" ? 'V' : 'N')
          data = string[4..-1]

          wkb_parser(srid).parse(data)
        elsif string[0, 10].match?(/[0-9a-fA-F]{8}0[01]/)
          srid = value[0, 8].to_i(16)
          srid = [srid].pack('V').unpack1('N') if string[9, 1] == '1'
          data = string[8..-1]

          wkb_parser(srid).parse(data)
        else
          wkt_parser.parse(string)
        end
      end

      def wkb_parser(srid)
        RGeo::WKRep::WKBParser.new(spatial_factory(srid: srid), default_srid: srid)
      end

      def wkt_parser
        RGeo::WKRep::WKTParser.new(nil, support_ewkt: true)
      end
    end
  end
end
