//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

Function ImagerContConstructor()
	ImagerConstructor()
	ImagerViewConstructor()
End


Function EPhys_Image()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// Declare the instance vars
	SVAR focus_name
	NVAR focus_num, image_trig, full_num
	NVAR im_plane, previouswave
	NVAR isROI
	NVAR isBackgroundROIToo
	SVAR imageseq_name
	WAVE roisWave
	NVAR exposure
	NVAR ccd_tempset
	NVAR xbin
	NVAR ybin
	
	Variable status, canceled
	String message
	//String command
	image_trig=1
	FancyCameraSetupAcquisition(isROI,isBackgroundROIToo,roisWave,image_trig,exposure,ccd_tempset,xbin,ybin)
	//image_roi=2		// zero for full frame, one for specific ROI, two for ROI with background
	isROI=1
	isBackgroundROIToo=1
	im_plane=0
	EpiLightTurnOnOff(1)
	Sleep /S 0.1
	Image_Stack(image_trig,0)
	print "done with image stack"
	Get_DFoverF_from_Stack(previouswave)
	Append_DFoverF(previouswave)
	EpiLightTurnOnOff(0)
	printf "%s%d: Image with EPhys done\r", imageseq_name, previouswave
	
	// Restore the data folder
	SetDataFolder savedDF	
End

Function FocusImage()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// Declare the object vars
	SVAR focus_name
	NVAR focus_num, image_trig, full_num
	//NVAR image_roi
	NVAR isROI
	NVAR isBackgroundROIToo
	WAVE roisWave
	NVAR exposure
	NVAR ccd_tempset
	NVAR xbin
	NVAR ybin

	Variable status, canceled
	String message
	Variable frames_per_sequence, frames
	String wave_image
	sprintf wave_image, "%s%d", focus_name, focus_num
	frames_per_sequence=1
	frames=1
	image_trig=0			// set to one for triggered images
	FancyCameraSetupAcquisition(isROI,isBackgroundROIToo,roisWave,image_trig,exposure,ccd_tempset,xbin,ybin)
	//printf "Focusing (press Esc key to stop) ..."
	EpiLightTurnOnOff(1)
	Sleep /S 0.1
	ImagerFocus()
	EpiLightTurnOnOff(0)
	full_num+=1
	focus_num=full_num
	//printf "%s: Focus Image done\r", wave_image

	// Restore the data folder
	SetDataFolder savedDF
End

Function Acquire_Full_Image()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// Declare the object vars
	SVAR full_name
	NVAR focus_num, image_trig, full_num
	NVAR xbin, ybin
	SVAR all_images
	SVAR imageseq_name
	WAVE roisWave
	NVAR exposure
	NVAR ccd_tempset
	NVAR xbin
	NVAR ybin
	
	Variable status, canceled
	String message
	//String imageWaveName
	Variable frames
	String imageWaveName=sprintf2sv("%s%d", full_name, full_num)
	//Variable image_roi=0		// means there is no ROI
	Variable isROI=0
	Variable isBackgroundROIToo=0	// Irrelevant
	frames=1
	image_trig=0		// set to one for triggered images
	xbin=1; ybin=1
	FancyCameraSetupAcquisition(isROI,isBackgroundROIToo,roisWave,image_trig,exposure,ccd_tempset,xbin,ybin) 
	EpiLightTurnOnOff(1)
	Sleep /S 0.1
	Make /O /N=(512,512) $imageWaveName
	Wave w=$imageWaveName
	w=100+gnoise(10)
	Variable isVideoTriggered=0
	FancyCameraArmAcquireDisarm(imageWaveName,frames,isVideoTriggered)  // needs to come back
	EpiLightTurnOnOff(0)
	Image_Display(imageWaveName) 
	printf "%s%d: Full Image done\r", full_name, full_num
	all_images=WaveList(full_name+"*",";","")+WaveList(imageseq_name+"*",";","")
	full_num+=1; focus_num=full_num

	// Restore the data folder
	SetDataFolder savedDF
End

Function Image_Stack(trig, disp)
	Variable trig, disp
	//	trig: one=triggered, zero=not triggered
	//	disp: one=display stack, zero=don't display stack
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// instance vars
	SVAR imageseq_name
	NVAR wavenumber
	NVAR ccd_frames
	NVAR image_trig
	NVAR im_plane
	
	Variable status, exposure, canceled
	String message
	String imageWaveName, datawavename
	Variable frames_per_sequence, frames
	sprintf imageWaveName, "%s%d", imageseq_name, wavenumber
	frames_per_sequence=ccd_frames
	frames=ccd_frames
	image_trig=trig		// set to one for triggered images
	EpiLightTurnOnOff(1)
	Sleep /S 0.1
	im_plane=0
	FancyCameraArmAcquireDisarm(imageWaveName,frames,trig)
	EpiLightTurnOnOff(0)
	if (disp>0)
		Image_Display(imageWaveName)
	endif
	printf "%s%d: Image Stack done\r", imageseq_name, wavenumber
	if (image_trig<1)
		wavenumber+=1		
	endif
	//	might want to add code to make an empty data wave if the image stack is taken on its own
	
	// Restore the original DF
	SetDataFolder savedDF
End

//------------------------------------- START OF BUTTON AND SETVAR PROCEDURES  ----------------------------------------------//

Function DFFButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	//String command
	NVAR previouswave
	Get_DFoverF_from_Stack(previouswave)
	Append_DFoverF(previouswave)
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function ResetAvgButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	NVAR imageavgn=imageavgn
	Wave average=dff_avg
	average=0
	imageavgn=0
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function SetCCDTempVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	FancyCameraSetTemperature(varNum)
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function StackButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	Image_Stack(0,0)
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function FullButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	Acquire_Full_Image()
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function FocusButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	FocusImage()
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function EphysImageButtonProc(ctrlName) : ButtonControl
	String ctrlName

	EPhys_Image()
End

//--------------------------------------- END OF BUTTON AND SETVAR PROCEDURES---------------------------------------//




//______________________DataPro Imaging PROCEDURES__________________________//


Function FluONButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	EpiLightTurnOnOff(1)
End

Function FluOFFButtonProc(ctrlName) : ButtonControl
	String ctrlName
	EpiLightTurnOnOff(0)
End

Function ImagingCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	NVAR imaging=imaging
	Execute "VDTGetPortList"
	SVAR port=S_VDT
	if (checked>0)
		imaging=1
		SetVDTPort("COM1")
	else
		imaging=0
	endif
	
	// Restore the original DF
	SetDataFolder savedDF
End






Function ImagerFocus()
	// Do a live view of the CCD, to enable focusing, etc.

	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// instance vars
	SVAR focus_name
	NVAR focus_num
	NVAR gray_low, gray_high

	String imageWaveName=sprintf2sv("%s%d", focus_name, focus_num)
	Variable	nFrames=1
	Variable isTriggered=0		// Just want the camera to free-run
	
	FancyCameraArm(imageWaveName, nFrames)
	Variable iFrame=0
	do
		// Start a sequence of images. In the current case, there is 
		// only one frame in the sequence.
		FancyCameraAcquire(imageWaveName, nFrames, isTriggered)
		// If first frame, create a display window.
		// If subseqent frame, update the image in the display window
		if (iFrame==0)
			Image_Display(imageWaveName)
		else
			if (iFrame==1)
				ModifyImage $imageWaveName ctab= {gray_low,gray_high,Grays,0}
			endif
			ControlInfo auto_on_fly_check0
			if (V_Value>0)
				AutoGrayScaleButtonProc("autogray_button0")
			endif
		endif
		iFrame+=1
		printf "."
	while (!EscapeKeyWasPressed())	
	FancyCameraDisarm()	
	
	// Restore the original DF
	SetDataFolder savedDF
End



Function Get_DFoverF_from_Stack(stacknum)
	Variable stacknum
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// instance vars
	SVAR imageseq_name
	NVAR ccd_seqexp
	
	Variable numbase
	numbase=16
	//Silent 1; PauseUpdate
	String stackWaveName, newImageWaveName
	sprintf stackWaveName, "%s%d", imageseq_name, stacknum
	sprintf newImageWaveName, "dff_%d", stacknum
	print stackWaveName, newImageWaveName
	DeletePoints /M=2 0,1, $stackWaveName		// kill the first plane of $stackWaveName
//	Duplicate /O $stack $newimage
	Make /O /N=(numpnts($stackWaveName)) $newImageWaveName
	WAVE newImageWave=$newImageWaveName
	WAVE stackWave=$stackWaveName
	Variable basef=0
	Variable i=0
	do
		basef+=stackWave[i]
		i+=1
	while (i<numbase)
	basef=basef/numbase
	newImageWave=100*(basef-stackWave)/basef
	SetScale /P x 0,ccd_seqexp,"ms", newImageWave
	
	// Restore the original DF
	SetDataFolder savedDF
End



Function Append_DFoverF(stacknum)
	Variable stacknum
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// instance vars
	NVAR imageavgn
	WAVE dff_avg
	
//	String stack
	String newImageWaveName=sprintf1v("dff_%d", stacknum)
//	sprintf stack, "stack_%d", stacknum
	//sprintf newImageWaveName, "dff_%d", stacknum
	//PauseUpdate
	AppendToGraph $newImageWaveName
	DoWindow /F ImagerView
	ControlInfo showimageavg_check0
	if (V_value>0)
		if (imageavgn<1)
			Duplicate /O $newImageWaveName dff_avg
			imageavgn+=1
		else
			dff_avg*=imageavgn
			WAVE newImageWave=$newImageWaveName
			dff_avg+=newImageWave
			imageavgn+=1
			dff_avg/=imageavgn
			AppendToGraph dff_avg
		endif
	endif
	ModifyGraph rgb($newImageWaveName)=(0,0,0)
	ModifyGraph lsize($newImageWaveName)=1.5
	ModifyGraph mode($newImageWaveName)=6
	ModifyGraph marker($newImageWaveName)=19
//	print imageavgn
	if (imageavgn>1)
		ModifyGraph lsize(dff_avg)=1.5,rgb(dff_avg)=(0,52224,0)
		ModifyGraph offset(dff_avg)={50,0}
	endif
	Variable leftmin, leftmax
	leftmin=0
	leftmax=0
	// Commented this out because I'm not sure what thiswave is supposed to refer to.
	// I'll fix this once I understand the code better. --ALT
	//Wavestats /Q $thiswave
	//leftmin=V_min
	//leftmax=V_max
	Wavestats /Q $newImageWaveName
	if (V_min<leftmin)
		leftmin=V_min
	endif
	if (V_max>leftmax)
		leftmax=V_max
	endif
	Setaxis left, leftmin, leftmax
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function SetROIProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	WAVE roisWave=roisWave, roibox_x=roibox_x, roibox_y=roibox_y
	NVAR iROI
	NVAR roi_left=roi_left, roi_right=roi_right, xbin=xbin, xpixels=xpixels
	NVAR roi_top=roi_top, roi_bottom=roi_bottom, ybin=ybin, ypixels=ypixels
	xpixels=(roi_right-roi_left+1)/xbin
	ypixels=(roi_bottom-roi_top+1)/ybin
	roisWave[][iROI]={roi_left, roi_right, roi_top, roi_bottom, xbin, ybin}
	DrawROI()
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function ImagerContiROISVTwiddled(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct
	
	// If control is being killed, do nothing
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	

	// Need a better name for the thing set
	Variable iROIPlusOne=svStruct.dval
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// decare instance vars
	WAVE roisWave
	NVAR iROI
	NVAR roi_left, roi_right, xbin, xpixels
	NVAR roi_top, roi_bottom, ybin, ypixels
	
	// do stuff
	iROI=iROIPlusOne-1
	roi_left=roisWave[0][iROI]
	roi_right=roisWave[1][iROI]
	roi_top=roisWave[2][iROI]
	roi_bottom=roisWave[3][iROI]
	xbin=roisWave[4][iROI]
	ybin=roisWave[5][iROI]
	xpixels=(roi_right-roi_left+1)/xbin
	ypixels=(roi_bottom-roi_top+1)/ybin
	DrawROI()
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function DrawROI()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// instance vars
	NVAR iROI
	NVAR roi_left, roi_right, roi_top, roi_bottom
	NVAR xbin, ybin
	NVAR xpixels, ypixels
	WAVE roisWave
	WAVE roibox_x0, roibox_y0
	WAVE roibox_x1, roibox_y1

	String thebox_yName=sprintf1v("roibox_y%d", iROI)
	WAVE thebox_y=$thebox_yName
	thebox_y={roi_top, roi_top, roi_bottom, roi_bottom, roi_top}
	String thebox_xName=sprintf1v("roibox_x%d", iROI)
	WAVE thebox_x=$thebox_xName	
	thebox_x={roi_left, roi_right, roi_right, roi_left, roi_left}
	if (wintype("Image_Display")>0)
		DoWindow /F Image_Display
		String removeit=Wavelist("roibox_yName*",";","WIN:Image_Display")
		RemoveFromGraph /W=Image_Display $removeit
		AppendToGraph roibox_y0 vs roibox_x0
		ModifyGraph /Z lsize(roibox_y0)=1.5
		AppendToGraph roibox_y1 vs roibox_x1
		ModifyGraph /Z lsize(roibox_y1)=1.5,rgb(roibox_y1)=(0,65280,0)
	endif
	
	// Restore the original DF
	SetDataFolder savedDF
End



