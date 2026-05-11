-- =============================================================================
-- Extra Environment Variables - NVIDIA
-- =============================================================================
-- Environment variables for systems with an NVIDIA GPU.
-- This file is loaded by hyprland.lua.
-- =============================================================================

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

-- For hybrid systems (Intel + NVIDIA), uncomment the line below
-- and adjust according to your configuration:
-- hl.env("AQ_DRM_DEVICES", "/dev/dri/nvidia-dgpu:/dev/dri/intel-igpu")
