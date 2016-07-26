defmodule XGPS.Messages.RMC do
  # Example:
  # $GPRMC,144728.000,A,5441.3992,N,02515.6704,E,1.37,38.57,190716,,,A*55
  #   RMC          Recommended Minimum sentence C
  #   144728.000   Fix taken at 12:35:19 UTC
  #   A            Status A=active or V=Void.
  #   5441.3992,N   Latitude 48 deg 07.038' N
  #   02515.6704,E  Longitude 11 deg 31.000' E
  #   1.37        Speed over the ground in knots
  #   38.57        Track angle in degrees True
  #   190716       Date - 19th of July 2016
  #   (empty)      Magnetic Variation
  #   (empty)
  #   A            autonomous
  #   *55          The checksum data, always begins with *
  defstruct time: nil,
            status: nil,
            latitude: nil,
            longitude: nil,
            speed_over_groud: nil,
            track_angle: nil,
            date: nil,
            magnetic_variation: nil
end
