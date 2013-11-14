//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

Function ImagerConstructor()
	// if the DF already exists, nothing to do
	if (DataFolderExists("root:DP_Imaging"))
		return 0		// have to return something
	endif

	// Save the current DF
	String savedDF=GetDataFolder(1)

//	IMAGING GLOBALS
	NewDataFolder /O/S root:DP_Imaging
	String /G all_images
	Variable /G fluo_on_wheel=1, fluo_off_wheel=0
	//Variable /G sidx_handle
	//Variable /G ccd_opened
//	Variable ccd_driver, ccd_hardware, ccd_camera
	Variable /G image_trig, image_focus, image_roi // image_focus may be unnecessary if there is a separate focus routine
	Variable /G imaging, ccd_handle, ccd_tempset, ccd_temp, ccd_frames
	ccd_tempset=-20; ccd_frames=56
	Variable /G ccd_focusexp, ccd_fullexp, ccd_seqexp, imageavgn, im_plane
	ccd_focusexp=100; ccd_fullexp=100; ccd_seqexp=50; imageavgn=0
	String /G full_name, focus_name, imageseq_name
	//String /G gimage, gstack
	full_name="full_"; focus_name="full_"; imageseq_name="trig_"
	Variable /G full_num, focus_num, imageseq_num
	full_num=1; focus_num=1; imageseq_num=1
	Variable /G numrois, roinum, roi_left, roi_right, roi_top, roi_bottom, xbin, ybin, xpixels, ypixels
	numrois=2; roinum=1; roi_left=200; roi_right=210; roi_top=200; roi_bottom=220
	xbin=10; 
	ybin=20; 
	xpixels=(roi_right-roi_left)/xbin; 
	ypixels=(roi_bottom-roi_top)/ybin
	Variable /G gray_low, gray_high
	gray_low=0; gray_high=2^16-1
	
	Make /O /N=(6,numrois+1) /I roiwave
	roiwave[][1]={roi_left, roi_right, roi_top, roi_bottom, xbin, ybin}
	roiwave[][2]={roi_left, roi_right, roi_top, roi_bottom, xbin, ybin}
	
	Make /O /N=(5,numrois+1) /I roibox_x, roibox_y
	roibox_x[][1]={roi_left, roi_right, roi_right, roi_left, roi_left}
	roibox_y[][2]={roi_top, roi_top, roi_bottom, roi_bottom, roi_top}
	
	Make /O /N=5 roibox_x1, roibox_y1, roibox_x2, roibox_y2
	
	// make average wave for imaging
	Make /O /N=(imageavgn) dff_avg
	
	// SIDX stuff
	//Variable /G sidx_handle

	// Restore the original data folder
	SetDataFolder savedDF	
End

