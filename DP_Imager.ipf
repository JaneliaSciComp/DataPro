//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

Function ImagerConstructor()
	// if the DF already exists, nothing to do
	if (DataFolderExists("root:DP_Imager"))
		return 0		// have to return something
	endif

	// Save the current DF
	String savedDF=GetDataFolder(1)

//	IMAGING GLOBALS
	NewDataFolder /O/S root:DP_Imager
	String /G all_images
	Variable /G fluo_on_wheel=1, fluo_off_wheel=0
	//Variable /G sidx_handle
	//Variable /G ccd_opened
//	Variable ccd_driver, ccd_hardware, ccd_camera
	Variable /G image_trig, image_focus	// image_focus may be unnecessary if there is a separate focus routine
	//Variable /G image_roi
	Variable /G isROI=0		// is there a ROI? (false=>full frame)
	Variable /G isBackroundROIToo=0		// if isROI, is there a background ROI too? (if full-frame, this is unused)
	Variable /G imaging, ccd_handle, ccd_tempset, ccd_temp, ccd_frames
	ccd_tempset=-20; ccd_frames=56
	Variable /G ccd_focusexp
	Variable /G exposure=100		// duration of each frame exposure, in ms
	Variable /G ccd_seqexp, imageavgn, im_plane
	ccd_focusexp=100; ccd_seqexp=50; imageavgn=0
	String /G full_name, focus_name, imageseq_name
	//String /G gimage, gstack
	full_name="full_"; focus_name="full_"; imageseq_name="trig_"
	Variable /G full_num, focus_num, imageseq_num
	full_num=1; focus_num=1; imageseq_num=1
	Variable /G nROIs=2	// the primary ROI, and the background ROI
	Variable /G iROI=0	// indicates the primary ROI
	Variable /G roi_left=200
	Variable /G roi_right=210
	Variable /G roi_top=200
	Variable /G roi_bottom=220
	Variable /G xbin=10
	Variable /G ybin=20
	Variable /G xpixels=(roi_right-roi_left)/xbin
	Variable /G ypixels=(roi_bottom-roi_top)/ybin
	//Variable /G gray_low, gray_high
	Variable /G gray_low=0
	Variable /G gray_high=2^16-1
	
	Make /O /N=(6,nROIs) /I roisWave
	roisWave[][0]={roi_left, roi_right, roi_top, roi_bottom, xbin, ybin}
	roisWave[][1]={roi_left, roi_right, roi_top, roi_bottom, xbin, ybin}
	
	Make /O /N=(5,nROIs) /I roibox_x, roibox_y
	roibox_x[][0]={roi_left, roi_right, roi_right, roi_left, roi_left}
	roibox_y[][1]={roi_top, roi_top, roi_bottom, roi_bottom, roi_top}
	
	Make /O /N=5 roibox_x0, roibox_y0
	Make /O /N=5 roibox_x1, roibox_y1
	
	// make average wave for imaging
	Make /O /N=(imageavgn) dff_avg
	
	// Restore the original data folder
	SetDataFolder savedDF	
End

