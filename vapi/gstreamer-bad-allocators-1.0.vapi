/* gstreamer-bad-allocators-1.0.vapi generated by vapigen, do not modify. */

[CCode (cprefix = "Gst", gir_namespace = "GstBadAllocators", gir_version = "1.0", lower_case_cprefix = "gst_")]
namespace Gst {
	[CCode (cheader_filename = "gst/allocators/badallocators.h", type_cname = "GstPhysMemoryAllocatorInterface", type_id = "gst_phys_memory_allocator_get_type ()")]
	public interface PhysMemoryAllocator : Gst.Allocator {
		[NoWrapper]
		public abstract uintptr get_phys_addr (Gst.Memory mem);
	}
	[CCode (cheader_filename = "gst/allocators/badallocators.h")]
	[Version (since = "1.12")]
	public static bool is_phys_memory (Gst.Memory mem);
	[CCode (cheader_filename = "gst/allocators/badallocators.h")]
	[Version (since = "1.12")]
	public static uintptr phys_memory_get_phys_addr (Gst.Memory mem);
}