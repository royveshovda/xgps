defmodule XGPS.Messages.GSV do
  # Example:
  # $GPGSV,3,2,12,10,40,181,22,26,32,206,25,20,27,053,,15,22,069,*7A
  #    GSV          Satellites in view
  #    3            Number of sentences for full data
  #    2            sentence number 2 (of maximum 3)
  #    12           Number of satellites in view

  #    10           Satellite PRN number
  #    40           Elevation, degrees
  #    181          Azimuth, degrees
  #    22           SNR - higher is better
  #         for up to 12 satellites per sentence
  #    *7A          the checksum data, always begins with *

  defstruct number_of_sences: 0,
            sentence_number: 0,
            number_of_satelites_in_view: 0,
            satelite_prn_number: nil,
            elevation_degrees: nil,
            azimuth_degrees: nil,
            sat_1_snr: nil,
            sat_2_snr: nil,
            sat_3_snr: nil,
            sat_4_snr: nil,
            sat_5_snr: nil,
            sat_6_snr: nil,
            sat_7_snr: nil,
            sat_8_snr: nil,
            sat_9_snr: nil,
            sat_10_snr: nil,
            sat_11_snr: nil,
            sat_12_snr: nil,
            autonomous: nil
end

defmodule XGPS.Messages.GSA do
  # Example:
  # $GPGSA,A,3,21,26,18,10,16,,,,,,,,2.41,2.20,0.99*0D
  #   GSA      Satellite status
  #   A        Auto selection of 2D or 3D fix (M = manual)
  #   3        3D fix - values include: 1 = no fix
  #                                     2 = 2D fix
  #                                     3 = 3D fix
  #   21,26... PRNs of satellites used for fix (space for 12)
  #   2.41      PDOP (dilution of precision)
  #   2.20      Horizontal dilution of precision (HDOP)
  #   0.99      Vertical dilution of precision (VDOP)
  #   *0D      the checksum data, always begins with *
  defstruct selection: nil,
            fix_3d: nil,
            prn_1_for_fix: nil,
            prn_2_for_fix: nil,
            prn_3_for_fix: nil,
            prn_4_for_fix: nil,
            prn_5_for_fix: nil,
            prn_6_for_fix: nil,
            prn_7_for_fix: nil,
            prn_8_for_fix: nil,
            prn_9_for_fix: nil,
            prn_10_for_fix: nil,
            prn_11_for_fix: nil,
            prn_12_for_fix: nil,
            pdop: nil,
            hdop: nil,
            vdop: nil
end

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
            magnetic_variation: nil,
            unknown: nil,
            autonomous: nil
end

defmodule XGPS.Messages.VTG do
  # Example:
  # $GPVTG,38.57,T,,M,1.37,N,2.53,K,A*05
  #      VTG          Track made good and ground speed
  #      38.57,T      True track made good (degrees)
  #      (empty),M      Magnetic track made good
  #      1.37,N      Ground speed, knots
  #      2.53,K      Ground speed, Kilometers per hour
  #      A           Autonomous
  #      *05          Checksum
  defstruct true_track_made_good: nil,
            magnetic_track_made_good: nil,
            ground_speed_in_knots: 0,
            ground_speed_in_km_h: 0,
            autonomous: nil
end

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
            unknown_1: nil,
            unknown_2: nil
end

defmodule XGPS.Messages.PGTOP do
  # Example:
  # $PGTOP,11,2*6E
  #     PGTOP        Antenna status
  #     11           ?
  #     2            Antenna type (3=external, 2=internal)
  #     *6E          Checksum
  #     (Requested by sending $PGCMD,33,1*6C\r\n)
  defstruct unknown_number: nil,
            antenna_type: nil
end


defmodule XGPS.Messages.PGACK do
  # Example:
  # $PGACK,33,1*6F
  defstruct request1: nil, request2: nil
end
