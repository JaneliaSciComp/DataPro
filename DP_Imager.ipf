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
	String /G allVideoWaveNames		// a semicolon-separated list of all the video wave names
	Variable /G fluo_on_wheel=1	// Setting of something that results in epi-illumination being on
	Variable /G fluo_off_wheel=0	// Setting of something that results in epi-illumination being off
	Variable /G image_trig		// boolean, true iff the image acquisition will be triggerd (as opposed to free-running)
	Variable /G image_focus	// image_focus may be unnecessary if there is a separate focus routine
	Variable /G isROI=0		// is there a ROI? (false=>full frame)
	Variable /G isBackroundROIToo=0		// if isROI, is there a background ROI too? (if full-frame, this is unused)
	Variable /G ccd_tempset= -20		// the setpoint CCD temperature
	Variable /G ccd_temp=nan			// the current CCD temperature
	Variable /G ccd_frames=56	// number of frames to acquire
	Variable /G ccd_focusexp=100		// duration of each exposure when focusing, in ms
	Variable /G exposure=100		// duration of each frame exposure for full-frame images, in ms
	Variable /G ccd_seqexp=50	// duration of each frame for triggered video, in ms
	Variable /G imageavgn=0		// number of frames to average (not sure for what purpose)
	Variable /G iFrame		// Frame index to show in the browser
	String /G fullFrameWaveBaseName="full_"		// the base name of the full-frame image waves, including the underscore
	String /G focus_name="full_"		// the base name of the focusing image waves, including the underscore
	String /G videoWaveBaseName="trig_"	// the base name of the triggered video waves, including the underscore
	Variable /G full_num=1	// The "sweep number" to use for the next full-frame image
	Variable /G focus_num=1		// The "sweep number" to use for the next focus image
	Variable /G imageseq_num=1		// The "sweep number" to use for the video
	Variable /G nROIs=2	// the primary ROI, and the background ROI
	Variable /G iROI=0	// indicates the primary ROI
	Variable /G roi_left=200	// column index of the left border of the ROI
	Variable /G roi_right=210	// column index of the right border of the ROI
	Variable /G roi_top=200	// row index of the top border of the ROI
	Variable /G roi_bottom=220	// row index of the bottom border of the ROI
	Variable /G xbin=10	// CCD bins per pixel in x dimension
	Variable /G ybin=20	// CCD bins per pixel in y dimension
	Variable /G xpixels=(roi_right-roi_left)/xbin	// Width of the binned ROI image
	Variable /G ypixels=(roi_bottom-roi_top)/ybin		// Height of the binned ROI image
	Variable /G blackCount=0		// the CCD count that gets mapped to black
	Variable /G whiteCount=2^16-1	// the CCD count that gets mapped to white
	
	Make /O /N=(6,nROIs) /I roisWave		// a 2D wave holding a ROI specification in each column
	roisWave[][0]={roi_left, roi_right, roi_top, roi_bottom, xbin, ybin}
	roisWave[][1]={roi_left, roi_right, roi_top, roi_bottom, xbin, ybin}
	
	Make /O /N=(5,nROIs) /I roibox_x 		// a 2D wave holding ROI corner x-coords in each column
	roibox_x[][0]={roi_left, roi_right, roi_right, roi_left, roi_left}
	roibox_x[][1]={roi_left, roi_right, roi_right, roi_left, roi_left}

	Make /O /N=(5,nROIs) /I roibox_y 		// a 2D wave holding ROI corner y-coords in each column
	roibox_y[][0]={roi_top, roi_top, roi_bottom, roi_bottom, roi_top}
	roibox_y[][1]={roi_top, roi_top, roi_bottom, roi_bottom, roi_top}
	
	Make /O /N=5 roibox_x0	// a 1D wave holding the ROI corner x-coords for the foreground ROI
	Make /O /N=5 roibox_y0	// a 1D wave holding the ROI corner y-coords for the foreground ROI
	Make /O /N=5 roibox_x1	// a 1D wave holding the ROI corner x-coords for the background ROI
	Make /O /N=5 roibox_y1	// a 1D wave holding the ROI corner y-coords for the background ROI
	
	// make average wave for imaging
	Make /O /N=(imageavgn) dff_avg
	
	// Restore the original data folder
	SetDataFolder savedDF	
End

		