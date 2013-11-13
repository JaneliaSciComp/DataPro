//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

//-------------------------------------------------------- DataPro Image MENU ---------------------------------------------------------//

Menu "DataPro Image"
//	"Data Pro_Menu"
//	"-"
	"LaunchImagingPanel"
	"-"
//	"Focus_Image"
	"Acquire_Full_Image"
	"Load_Full_Image"
	"Load_Image_Stack"
	"-"
	"Image_Display"
	"DFF_From_Stack"
	"-"
	"Show_DFoverF"
	"Append_DFoverF"
	"Quick_Append"
	//"Get_SIDX_Image"
End

// From DataPro 6 main panel:
// 		Button imaging_button,pos={24,325},size={120,20},proc=ImagingButtonProc,title="Imaging"

Function ImagingPanel() : Panel
	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	String absVarName
	
	//PauseUpdate; Silent 1		// building window...
	NewPanel /W=(757,268,1068,741)  /N=ImagingPanel /K=1 as "Imaging Controls"
	Button flu_on,pos={10,40},size={130,20},proc=FluONButtonProc,title="Fluorescence ON"
	Button flu_off,pos={10,10},size={130,20},proc=FluOFFButtonProc,title="Fluorescence OFF"
	CheckBox imaging_check0,pos={14,244},size={114,14},proc=ImagingCheckProc,title="trigger filter wheel"
	CheckBox imaging_check0,value= 1
	Button button0,pos={215,283},size={80,20},proc=DFFButtonProc,title="Append DF/F"
	Button button1,pos={9,190},size={130,20},proc=EphysImageButtonProc,title="Electrophys. + Image"
	SetVariable setimagename0,pos={141,223},size={80,15},title="name"
	SetVariable setimagename0,value= imageseq_name
	CheckBox bkgndcheck0,pos={14,265},size={71,14},title="Bkgnd Sub.",value= 1
	SetVariable numimages_setvar0,pos={11,223},size={120,15},title="No. images"
	SetVariable numimages_setvar0,limits={1,10000,1},value= ccd_frames
	SetVariable ccdtemp_setvar0,pos={13,311},size={150,15},proc=SetCCDTempVarProc,title="CCD Temp. Set"
	SetVariable ccdtemp_setvar0,limits={-50,20,5},value= ccd_tempset
	CheckBox showimageavg_check0,pos={14,286},size={84,14},title="Show Average"
	CheckBox showimageavg_check0,value= 0
	Button resetavg_button2,pos={212,253},size={80,20},proc=ResetAvgButtonProc,title="Reset Avg"
	Button focus,pos={10,70},size={130,20},proc=FocusButtonProc,title="Focus"
	Button full_frame,pos={10,130},size={130,20},proc=FullButtonProc,title="Full Frame Image"
	SetVariable fluo_on_set,pos={178,40},size={120,15},title="ON   position"
	SetVariable fluo_on_set,limits={0,9,1},value= fluo_on_wheel
	SetVariable fluo_off_set,pos={177,10},size={120,15},title="OFF position"
	SetVariable fluo_off_set,limits={0,9,1},value= fluo_off_wheel
	SetVariable focusnum_set,pos={229,98},size={70,15},title="no."
	SetVariable focusnum_set,limits={0,1000,1},value= focus_num
	SetVariable fulltime_set,pos={152,130},size={150,15},title="Exp. time (ms)"
	SetVariable fulltime_set,limits={0,10000,100},value= ccd_fullexp
	SetVariable imagetime_setvar0,pos={149,193},size={150,15},title="Exp.time (ms)"
	SetVariable imagetime_setvar0,limits={0,10000,10},value= ccd_seqexp
	SetVariable setfullname0,pos={137,158},size={80,15},title="name"
	SetVariable setfullname0,value= full_name
	SetVariable setfocusname0,pos={139,99},size={80,15},title="name"
	SetVariable setfocusname0,value= focus_name
	
	absVarName=AbsoluteVarName("root:DP_Imaging","ccd_temp")
	ValDisplay tempdisp0,pos={174,311},size={120,14},title="CCD Temp."
	ValDisplay tempdisp0,format="%3.1f",limits={0,0,0},barmisc={0,1000}
	ValDisplay tempdisp0,value= #absVarName
	
	SetVariable focustime_set,pos={151,70},size={150,15},title="Exp. time (ms)"
	SetVariable focustime_set,limits={0,10000,100},value= ccd_focusexp
	SetVariable fullnum_set,pos={230,159},size={70,15},title="no."
	SetVariable fullnum_set,limits={0,1000,1},value= full_num
	SetVariable imageseqnum_set,pos={227,223},size={70,15},title="no."
	SetVariable imageseqnum_set,limits={0,10000,1},value= imageseq_num
	SetVariable roinum_set0,pos={117,341},size={90,15},proc=GetROIProc,title="ROI no."
	SetVariable roinum_set0,format="%d",limits={1,2,1},value= roinum
	SetVariable settop0,pos={182,371},size={77,15},proc=SetROIProc,title="top"
	SetVariable settop0,format="%d",limits={0,512,1},value= roi_top
	SetVariable setright0,pos={54,395},size={85,15},proc=SetROIProc,title="right"
	SetVariable setright0,format="%d",limits={0,512,1},value= roi_right
	SetVariable settleft0,pos={64,370},size={75,15},proc=SetROIProc,title="left"
	SetVariable settleft0,format="%d",limits={0,512,1},value= roi_left
	SetVariable setbottom0,pos={159,395},size={100,15},proc=SetROIProc,title="bottom"
	SetVariable setbottom0,format="%d",limits={0,512,1},value= roi_bottom
	SetVariable setxbin0,pos={55,419},size={85,15},proc=SetROIProc,title="x bin"
	SetVariable setxbin0,format="%d",limits={0,512,1},value= xbin
	SetVariable setybin0,pos={174,419},size={85,15},proc=SetROIProc,title="y bin"
	SetVariable setybin0,format="%d",limits={0,512,1},value= ybin

	absVarName=AbsoluteVarName("root:DP_Imaging","xpixels")
	ValDisplay xpixels0,pos={54,444},size={85,14},title="x pixels",format="%4.2f"
	ValDisplay xpixels0,limits={0,0,0},barmisc={0,1000},value= #absVarName
	
	absVarName=AbsoluteVarName("root:DP_Imaging","ypixels")
	ValDisplay ypixels0,pos={173,446},size={85,14},title="y pixels",format="%4.2f"
	ValDisplay ypixels0,limits={0,0,0},barmisc={0,1000},value= #absVarName
	
	Button getstac_button,pos={125,253},size={80,20},proc=StackButtonProc,title="GetStack"
	CheckBox show_roi_check0,pos={109,286},size={94,14},title="Show ROI Image"
	CheckBox show_roi_check0,value= 0
	
	// Restore the original DF
	SetDataFolder savedDF
End

//---------------------------------------------------IMAGE ACQUISITION Procedures--------------------------------------------------//

//Proc SetupImagingGlobals()
Function SetupImagingGlobals()
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

Function EPhys_Image()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	// Declare the instance vars
	SVAR focus_name
	NVAR focus_num, image_trig, full_num
	NVAR image_roi, im_plane, previouswave
	SVAR imageseq_name
	WAVE roiwave
	NVAR ccd_fullexp
	NVAR ccd_tempset
	
	Variable status, exposure, canceled
	String message, command
	image_trig=1
	CameraSetupAcquisition(image_roi,roiwave,image_trig,ccd_fullexp,ccd_tempset)
	image_roi=2		// zero for full frame, one for specific ROI, two for ROI with background
	im_plane=0
	EpiLightTurnOnOff(1)
	Sleep /S 0.1
	sprintf command, "Image_Stack(image_trig,0)"
	Execute command
	print "done with image stack"
	sprintf command, "Get_DFoverF_from_Stack(%d)", previouswave
	Execute command
	sprintf command, "Append_DFoverF(%d)", previouswave
	Execute command
	EpiLightTurnOnOff(0)
	printf "%s%d: Image with EPhys done\r", imageseq_name, previouswave
	
	// Restore the data folder
	SetDataFolder savedDF	
End

Function FocusImage()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	// Declare the object vars
	SVAR focus_name
	NVAR focus_num, image_trig, full_num
	NVAR image_roi
	WAVE roiwave
	NVAR ccd_fullexp
	NVAR ccd_tempset

	Variable status, exposure, canceled
	String message
	Variable frames_per_sequence, frames
	String wave_image
	sprintf wave_image, "%s%d", focus_name, focus_num
	frames_per_sequence=1
	frames=1
	image_trig=0			// set to one for triggered images
	CameraSetupAcquisition(image_roi,roiwave,image_trig,ccd_fullexp,ccd_tempset)
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
	SetDataFolder root:DP_Imaging

	// Declare the object vars
	SVAR full_name
	NVAR focus_num, image_trig, full_num
	NVAR xbin, ybin
	SVAR all_images
	SVAR imageseq_name
	WAVE roiwave
	NVAR ccd_fullexp
	NVAR ccd_tempset
	
	Variable status, exposure, canceled
	String message
	//String imageWaveName
	Variable frames
	String imageWaveName=sprintf2sv("%s%d", full_name, full_num)
	Variable image_roi=0		// means there is no ROI
	frames=1
	image_trig=0		// set to one for triggered images
	xbin=1; ybin=1
	CameraSetupAcquisition(image_roi,roiwave,image_trig,ccd_fullexp,ccd_tempset) 
	EpiLightTurnOnOff(1)
	Sleep /S 0.1
	Make /O /N=(512,512) $imageWaveName
	Wave w=$imageWaveName
	w=100+gnoise(10)
	Variable isVideoTriggered=0
	CameraAllocateAndAcquire(imageWaveName,frames,isVideoTriggered)  // needs to come back
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
	SetDataFolder root:DP_Imaging
	
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
	CameraAllocateAndAcquire(imageWaveName,frames,trig)
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

//------------------------------------------------------ IMAGE LOAD PROCEDURES ----------------------------------------------//
//-----------------------------------------------------LOAD FROM FILE AND DISPLAY-------------------------------------------//

Function Load_Full_Image()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	// instance vars
	SVAR full_name
	NVAR full_num
	NVAR focus_num

	//Silent 1; PauseUpdate
	//Variable low, high
	String newImageWaveName=sprintf2sv("%s%d", full_name, full_num)
	GBLoadWave /B /T={80,80} /S=4100 /W=1 /N=temp
	Rename temp0 $newImageWaveName
	//Duplicate /O temp0 $newImageWaveName
	//Killwaves temp0
	Redimension /N=(512,512,1) $newImageWaveName
	Image_Display(newImageWaveName)
	AutoGrayScaleButtonProc("autogray_button0")
	printf "%s%d: Image loaded\r", full_name, full_num
	full_num+=1; focus_num=full_num
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function Load_Image_Stack(stacknum, numimages)
//	this is not recently tested, but can be used for loading image stacks from WinView files saved as TIFF
//	when updating, use Load_Image as a template, as it is more up to date
	Variable stacknum, numimages
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging
	
	// instance vars
	SVAR imagename
	WAVE temp0
	
	Variable infile, outfile
	// data file types
	// 80 for 16-bit unsigned integer (raw binned data)
	// 2 for float (for post-process binned data)
	// 4 for double float
	infile=80; outfile=4
	//Silent 1; PauseUpdate
	String newImageWaveName, filename, getbinary
	//	NewPath Images "C:Nelson:Imaging Expts:..........."
	sprintf filename, "%s%d.SPE", imagename, stacknum
	sprintf getbinary, "GBLoadWave/P=Images/B/T={%d,%d}/S=4100/W=1/N=temp \"%s\"", infile, outfile, filename
//	print getbinary
	sprintf newImageWaveName, "stack_%d", stacknum
	Execute getbinary
	Make /O /N=(numimages-1) $newImageWaveName
	WAVE newImageWave=$newImageWaveName
	DoWindow /F ImagingPanel
	ControlInfo bkgndcheck0
	if (V_value<1)
		newImageWave=temp0[p+1]	// use this if there is no background subtraction
	else
		newImageWave=temp0[2*(p+1)]-temp0[2*(p+1)+1]	// use this if there are alternating data and bkgnd points in array
	endif
	Killwaves temp0
	
	// Restore the original DF
	SetDataFolder savedDF
End

//---------------------------------------------------------- IMAGE DISPLAY PROCEDURES -----------------------------------------//

//Window Image_Display(imageWaveName): Graph
Function Image_Display(imageWaveName): Graph
	String imageWaveName
	
	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging
	
	// Declare instance vars
	//SVAR gimage
	NVAR im_plane
	SVAR all_images
	SVAR full_name
	SVAR imageseq_name
	NVAR gray_low, gray_high
	
	//String imageWaveName=gimage
	//Prompt imageWaveName, "Enter image wave", popup, WaveList(full_name+"*",";","")+WaveList(imageseq_name+"*",";","");
	//gimage=imageWaveName
	//String wave=imageWaveName
	String command
	Variable numplanes
	numplanes=DimSize($imageWaveName, 2)
	im_plane=0
	all_images=WaveList(full_name+"*",";","")+WaveList(imageseq_name+"*",";","")
	if (wintype("Image_Display")<1)
		Display /W=(45,40,345,340) /K=1 as "Image_Display"
		SetVariable plane_setvar0,pos={45,23},size={80,16},proc=ImagePlaneSetVarProc,title="plane"
		SetVariable plane_setvar0,limits={0,numplanes-1,1},value= im_plane
		SetVariable gray_setvar0,pos={137,1},size={130,16},proc=GrayScaleSetVarProc,title="gray low"
		SetVariable gray_setvar0,limits={0,64000,1000},value= gray_low
		SetVariable gray_setvar1,pos={137,23},size={130,16},proc=GrayScaleSetVarProc,title="gray high"
		SetVariable gray_setvar1,limits={0,64000,1000},value= gray_high
		Button autogray_button0,pos={282,0},size={80,20},proc=AutoGrayScaleButtonProc,title="Autoscale"
		CheckBox auto_on_fly_check0,pos={282,25},size={111,14},title="Autoscale on the fly"
		CheckBox auto_on_fly_check0,value= 0
		PopupMenu image_popup0,pos={17,0},size={111,21},proc=ImagePopMenuProc,title="Image"
		PopupMenu image_popup0,mode=26	//,value= #"all_images"
		PopupMenu image_popup0,mode=1
	else
		SetVariable plane_setvar0,limits={0,numplanes-1,1},value= im_plane
	endif
	DoWindow /F Image_Display
	PopupMenu image_popup0,value= #"all_images"
	PopupMenu image_popup0,mode=WhichListItem(imageWaveName,all_images)+1
	sprintf command, "RemoveImage %s", ImageNameList("Image_Display",";")
	Execute command
	AppendImage $imageWaveName
//	SetAxis/A/R left
	ControlInfo auto_on_fly_check0
	if (V_Value>0)
		AutoGrayScaleButtonProc("autogray_button0")
	else
		ModifyImage $imageWaveName ctab= {gray_low,gray_high,Grays,0}
	endif
	ModifyGraph margin(left)=29,margin(bottom)=22,margin(top)=36,gfSize=8,gmSize=8
	ModifyGraph manTick={0,64,0,0},manMinor={8,8}
	
	// Restore the original DF
	SetDataFolder savedDF	
End

//------------------------------------------------------------------------ DF/F PROCEDURES -------------------------------------------//

Function Get_DFoverF_from_Stack(stacknum)
	Variable stacknum
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging
	
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

//----THIS ONE IS FOR THE MORE COMPLEX CASE OF A WHOLE IMAGE INSTEAD OF JUST 2 PTS---STILL NEEDS MORE WORK

Function Get_DFoverF_from_Stack2(stacknum)
	Variable stacknum
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging
	
	// instance vars
	SVAR imageseq_name
	NVAR ccd_frames
	NVAR ccd_seqexp
	
	Variable index, basef
	Variable numbase=3
	String stackWaveName=sprintf2sv("%s%d", imageseq_name, stacknum)
	print stackWaveName
	String dffWaveName=sprintf1v("dff_%d", stacknum)
	Make /O /N=(ccd_frames-1) tempwave, $dffWaveName
	WAVE stackWave=$stackWaveName
	DoWindow /F ImagingPanel
	ControlInfo bkgndcheck0
	if (V_value<1)
		tempwave=stackWave[0][0][p+1]	// use this if there is no background subtraction
	else
		tempwave=stackWave[0][0][p+1]-stackWave[1][0][p+1]	// use this if there are alternating data and bkgnd points in array
	endif
	do
		basef+=tempwave[index]
		index+=1
	while (index<numbase)
	basef=basef/numbase
	WAVE dffWave=$dffWaveName
	dffWave=100*(basef-tempwave)/basef
	SetScale/P x 0,ccd_seqexp,"ms", dffWave
	Killwaves tempwave
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function Show_DFoverF(wavenum)
	Variable wavenum
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging
	
//	String stack
	String newimage
//	sprintf stack, "stack_%d", wavenum
	sprintf newimage, "dff_%d", wavenum
	Display /W=(5,40,405,250) $newimage
	ModifyGraph mode=6
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph lsize(dff_temp)=1.5
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function Append_DFoverF(stacknum)
	Variable stacknum
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging
	
	// instance vars
	NVAR imageavgn
	WAVE dff_avg
	
//	String stack
	String newImageWaveName=sprintf1v("dff_%d", stacknum)
//	sprintf stack, "stack_%d", stacknum
	//sprintf newImageWaveName, "dff_%d", stacknum
	//PauseUpdate
	AppendToGraph $newImageWaveName
	DoWindow /F ImagingPanel
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

//----------------------------------------------------- ROI PROCEDURES -----------------------------------//

Function GetROI(): GraphMarquee
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	// instance vars
	NVAR roinum, roi_left, roi_right, roi_top, roi_bottom
	NVAR xbin, ybin
	NVAR xpixels, ypixels
	WAVE roiwave

	GetMarquee /K left, bottom
	roinum=1
	roi_left=V_left; roi_right=V_right
	roi_top=V_top; roi_bottom=V_bottom
	xbin=1
	ybin=1
	xpixels=(roi_right-roi_left+1)/xbin
	ypixels=(roi_top-roi_bottom+1)/ybin
	roiwave[][roinum]={roi_left, roi_right, roi_top, roi_bottom, xbin, xpixels}
	DrawROI()
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function GetBkgndROI(): GraphMarquee
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	// instance vars
	NVAR roinum, roi_left, roi_right, roi_top, roi_bottom
	NVAR xbin, ybin
	NVAR xpixels, ypixels
	WAVE roiwave

	GetMarquee /K left, bottom
	roinum=2
	roi_left=V_left; roi_right=V_left+xpixels
	xbin=1
	ybin=1
	xpixels=(roi_right-roi_left+1)/xbin
	ypixels=(roi_top-roi_bottom+1)/ybin
	roiwave[][roinum]={roi_left, roi_right, roi_top, roi_bottom, xbin, xpixels}
	DrawROI()
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function GetROI_and_Bkgnd(): GraphMarquee
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	// instance vars
	NVAR roinum, roi_left, roi_right, roi_top, roi_bottom
	NVAR xbin, ybin
	NVAR xpixels, ypixels
	WAVE roiwave

	GetROI()
	roinum=2
	roi_left+=200; roi_right=roi_left+xpixels
	roiwave[][roinum]={roi_left, roi_right, roi_top, roi_bottom, xbin, xpixels}
	DrawROI()
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function Get_10x10_ROI(): GraphMarquee
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	// instance vars
	NVAR roinum, roi_left, roi_right, roi_top, roi_bottom
	NVAR xbin, ybin
	NVAR xpixels, ypixels
	WAVE roiwave

	GetMarquee /K left, bottom
	roinum=1
	xbin=10
	ybin=10
	roi_left=round(V_left+(V_right-V_left)/2); roi_right=roi_left+xbin-1
	roi_top=round(V_top-(V_top-V_bottom)/2); roi_bottom=roi_top-ybin+1
	xpixels=(roi_right-roi_left+1)/xbin
	ypixels=(roi_top-roi_bottom+1)/ybin
	roiwave[][roinum]={roi_left, roi_right, roi_top, roi_bottom, xbin, xpixels}
	DrawROI()
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function Get_10x10_ROI_and_Bkgnd(): GraphMarquee
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	// instance vars
	NVAR roinum, roi_left, roi_right, roi_top, roi_bottom
	NVAR xbin, ybin
	NVAR xpixels, ypixels
	WAVE roiwave

	GetMarquee /K left, bottom
	Get_10x10_ROI()
	roinum=2
	roi_left+=200; roi_right=roi_left+9
	roiwave[][roinum]={roi_left, roi_right, roi_top, roi_bottom, xbin, xpixels}
	DrawROI()
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function DrawROI()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	// instance vars
	NVAR roinum, roi_left, roi_right, roi_top, roi_bottom
	NVAR xbin, ybin
	NVAR xpixels, ypixels
	WAVE roiwave
	WAVE roibox_x1, roibox_y1
	WAVE roibox_x2, roibox_y2

	//PauseUpdate; Silent 1
	//String doit
	String thebox_yName=sprintf1v("roibox_y%d", roinum)
	WAVE thebox_y=$thebox_yName
	thebox_y={roi_top, roi_top, roi_bottom, roi_bottom, roi_top}
	String thebox_xName=sprintf1v("roibox_x%d", roinum)
	WAVE thebox_x=$thebox_xName	
	thebox_x={roi_left, roi_right, roi_right, roi_left, roi_left}
	if (wintype("Image_Display")>0)
		DoWindow /F Image_Display
		String removeit=Wavelist("roibox_yName*",";","WIN:Image_Display")
		RemoveFromGraph /W=Image_Display $removeit
		AppendToGraph roibox_y1 vs roibox_x1
		ModifyGraph /Z lsize(roibox_y1)=1.5
		AppendToGraph roibox_y2 vs roibox_x2
		ModifyGraph /Z lsize(roibox_y2)=1.5,rgb(roibox_y2)=(0,65280,0)
	endif
	
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
	SetDataFolder root:DP_Imaging
	
	WAVE roiwave=roiwave, roibox_x=roibox_x, roibox_y=roibox_y
	NVAR roinum=roinum
	NVAR roi_left=roi_left, roi_right=roi_right, xbin=xbin, xpixels=xpixels
	NVAR roi_top=roi_top, roi_bottom=roi_bottom, ybin=ybin, ypixels=ypixels
	xpixels=(roi_right-roi_left+1)/xbin
	ypixels=(roi_bottom-roi_top+1)/ybin
	roiwave[][roinum]={roi_left, roi_right, roi_top, roi_bottom, xbin, ybin}
	Execute "DrawROI()"
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function GetROIProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging
	
	WAVE roiwave=roiwave
	NVAR roinum=roinum
	NVAR roi_left=roi_left, roi_right=roi_right, xbin=xbin, xpixels=xpixels
	NVAR roi_top=roi_top, roi_bottom=roi_bottom, ybin=ybin, ypixels=ypixels
	roi_left=roiwave[0][roinum]
	roi_right=roiwave[1][roinum]
	roi_top=roiwave[2][roinum]
	roi_bottom=roiwave[3][roinum]
	xbin=roiwave[4][roinum]
	ybin=roiwave[5][roinum]
	xpixels=(roi_right-roi_left+1)/xbin
	ypixels=(roi_bottom-roi_top+1)/ybin
	PauseUpdate
	Execute "DrawROI()"
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function ImagePlaneSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	// instance variables
	NVAR im_plane
	NVAR previouswave
	SVAR imageseq_name
	
	// Do stuff
	String command
	sprintf command, "ModifyImage \'\'#0 plane=%d", im_plane
	Execute command
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function GrayScaleSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	// instance vars
	NVAR gray_low=gray_low
	NVAR gray_high=gray_high
	
	ModifyImage ''#0 ctab= {gray_low,gray_high,Grays,0}
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function AutoGrayScaleButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging
	
	// instance vars
	NVAR gray_low
	NVAR gray_high
	NVAR full_num
	NVAR im_plane
	SVAR full_name
	
	String imageWaveName=WaveList("full_*","","WIN:")
	//String command

	//sprintf command, "ImageTransform /P=%d getplane %s", im_plane, imageWaveName
	//Execute command
	//WAVE M_ImagePlane	// "returned" from ImageTransform
	//ImageTransform /P=(im_plane) getPlane imageWaveName

	//sprintf command, "Imagestats /M=1/G={0,506,2,506} M_ImagePlane"
	//Execute command
	
	Imagestats /M=1 $imageWaveName
	gray_low=V_min
	gray_high=V_max
	
	//sprintf command, "ModifyImage \'\'#0 ctab= {%d,%d,Grays,0}", gray_low, gray_high
	//Execute command
	
	ModifyImage ''#0 ctab= {gray_low,gray_high,Grays,0}
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function DFF_From_Stack(imagestack)
	String imagestack
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	// instance vars
	SVAR full_name
	SVAR trig_name	

	//String imagestack=gstack
	//Prompt imagestack, "Enter image stack wave", popup, WaveList(full_name+"*",";","");trig_name+"*";		// Not sure what this is supposed to be
	Prompt imagestack, "Enter image stack wave", popup, WaveList(full_name+"*",";","")
	//gstack=imagestack
	//Silent 1
	Variable numbaseline, numtest, low, high
	String basename, number, next, image, doit
	numbaseline=4
	numtest=4
//	sprintf image "%s%s", basename, number
	String mathWaveName=sprintf1s("%s_math", image)
	Duplicate /O $imagestack $mathWaveName
	Wave mathWave=$mathWaveName
	Redimension /D /N=(-1,-1) $mathWaveName
	mathWave=0
	Duplicate /O $mathWaveName, basewave, testwave
	Variable index
	WAVE M_ImagePlane	// will be "returned" from ImageTransform below
	do
		ImageTransform /P=(index) getPlane $imagestack
		basewave+=M_ImagePlane
		index+=1
	while (index<(numbaseline+1))
	basewave=basewave/numbaseline
	print "these loops are taking too damn long"
	do
		ImageTransform /P=(index) getPlane $imagestack
		testwave+=M_ImagePlane
		index+=1
	while(index<(numbaseline+numtest+1))
	testwave=testwave/numtest
//	Wavestats /Q/R=(0,512) testwave
//	background=V_avg
  	mathWave=-100*(testwave-basewave)/basewave
 	Wavestats /Q $mathWaveName
 	low=V_min+0.1*(V_max-V_min)
 	high=V_max-0.1*(V_max-V_min)
 	print V_min, V_max, low, high
	Image_Display(mathWaveName)
//	ModifyImage $mathWaveName ctab= {low,high,Grays,0}
	
	// Restore the original DF
	SetDataFolder savedDF
End

//------------------------------------- START OF BUTTON AND SETVAR PROCEDURES  ----------------------------------------------//

Function DFFButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	String command
	NVAR previouswave=previouswave
	sprintf command, "Get_DFoverF_from_Stack(%d)", previouswave
	Execute command
	sprintf command, "Append_DFoverF(%d)", previouswave
	Execute command
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function ResetAvgButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

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
	SetDataFolder root:DP_Imaging

	CameraSetTemperature(varNum)
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function StackButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	Image_Stack(0,0)
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function FullButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	Execute "Acquire_Full_Image()"
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function FocusButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	FocusImage()
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function EphysImageButtonProc(ctrlName) : ButtonControl
	String ctrlName

	EPhys_Image()
End

Function ImagePopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	String command
	sprintf command, "Image_Display(\"%s\")", popStr
	Execute command
	
	// Restore the original DF
	SetDataFolder savedDF
End
//--------------------------------------- END OF BUTTON AND SETVAR PROCEDURES---------------------------------------//




//______________________DataPro Imaging PROCEDURES__________________________//

Function LaunchImagingPanel()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	if (wintype("ImagingPanel")<1)
		Execute "ImagingPanel()"
	else
		DoWindow /F ImagingPanel	
	endif
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function ImagingButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	if (wintype("ImagingPanel")<1)
		Execute "ImagingPanel()"
	else
		DoWindow /F ImagingPanel	
	endif
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function FluONButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	EpiLightTurnOnOff(1)
End

//Function FluorescenceON()
//	String command
//	
//	// Switch to the imaging data folder
//	String savedDF=GetDataFolder(1)
//	SetDataFolder root:DP_Imaging
//
//	NVAR wheel=fluo_on_wheel
//	// This will need to be updated
//	//SetVDTPort("COM1")
//	//Execute "VDTWriteBinary 238"
//	//sprintf command "VDTWriteBinary 8%d", wheel
//	//Execute command
//	
//	// Restore the original DF
//	SetDataFolder savedDF
//End

Function FluOFFButtonProc(ctrlName) : ButtonControl
	String ctrlName
	EpiLightTurnOnOff(0)
End

//Function FluorescenceOFF()
//	// This will need to be updated
//	//SetVDTPort("COM1")
//	//Execute "VDTWriteBinary 238"
//	//Execute "VDTWriteBinary 80"
//End

Function SetVDTPort(name)
	String name

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging

	Execute "VDTGetPortList"
	SVAR port=S_VDT
	NVAR imaging=imaging
	String command
	imaging=1
	if (cmpstr(port,"")==0)
		imaging=0
		Abort "A serial port could not be located"
	else
		sprintf command, "VDTOperationsPort %s", name
		Execute command
	endif
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function ImagingCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imaging
	
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
	SetDataFolder root:DP_Imaging
	
	// instance vars
	SVAR focus_name
	NVAR focus_num
	NVAR gray_low, gray_high

	String imageWaveName=sprintf2sv("%s%d", focus_name, focus_num)
	Variable	nFrames=1
	Variable isTriggered=0		// Just want the camera to free-run
	
	CameraAllocateFramebuffer(imageWaveName, nFrames)
	Variable iFrame=0
	do
		// Start a sequence of images. In the current case, there is 
		// only one frame in the sequence.
		CameraAcquire(imageWaveName, nFrames, isTriggered)
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
	CameraDeallocateFramebuffer()	
	
	// Restore the original DF
	SetDataFolder savedDF
End

