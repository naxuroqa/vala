namespace ClutterGst {
	namespace Version {
		[CCode (cheader_filename = "clutter-gst/clutter-gst.h", cname = "CLUTTER_GST_CHECK_VERSION")]
		public static bool check (int major, int minor, int micro);
	}
}
