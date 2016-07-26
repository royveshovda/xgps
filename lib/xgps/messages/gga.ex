defmodule XGPS.Messages.GGA do
  # Example:
  # $GPGGA,144729.000,5441.3996,N,02515.6709,E,1,05,2.20,118.7,M,27.6,M,,*62
  #   GGA          Global Positioning System Fix Data
  #   144729.000       Fix taken at 12:35:19 UTC
  #   5441.3996,N   Latitude 48 deg 07.038' N
  #   02515.6709,E  Longitude 11 deg 31.000' E
  #   1            Fix quality: 0 = invalid
  #                             1 = GPS fix (SPS)
  #                             2 = DGPS fix
  #                             3 = PPS fix
	#		                          4 = Real Time Kinematic
	#		                          5 = Float RTK
  #                             6 = estimated (dead reckoning) (2.3 feature)
	#		                          7 = Manual input mode
	#		                          8 = Simulation mode
  #   05           Number of satellites being tracked
  #   2.20          Horizontal dilution of position
  #   118.7,M      Altitude, Meters, above mean sea level
  #   27.6,M       Height of geoid (mean sea level) above WGS84
  #                    ellipsoid
  #   (empty field) time in seconds since last DGPS update
  #   (empty field) DGPS station ID number
  #   *62          the checksum data, always begins with *
  defstruct fix_taken: nil,
            latitude: nil,
            longitude: nil,
            fix_quality: 0,
            number_of_satelites_tracked: 0,
            horizontal_dilution: 0,
            altitude: 0,
            height_over_goeid: 0,
            time_since_last_dgps: nil,
            dgps_station_id: nil
end
