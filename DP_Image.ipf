//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998
//	last updated 1/5/2000

#pragma rtGlobals=1		// Use modern global access method.

//-------------------------------------------------------- DataPro Image MENU ---------------------------------------------------------//

//Menu "DataPro Image"
//	"Data Pro_Menu"
//	"-"
//	"Focus_Image"
//	"Acquire_Full_Image"
//	"Load_Full_Image"
//	"Load_Image_Stack"
//	"-"
//	"Image_Display"
//	"DFF_From_Stack"
//	"-"
//	"Show_DFoverF"
//	"Append_DFoverF"
//	"Quick_Append"
//	"Get_SIDX_Image"
//End

//---------------------------------------------------IMAGE ACQUISITION Procedures--------------------------------------------------//

Proc Focus_Image()
	Variable sidx_handle, status, exposure, canceled
	String message
	Variable frames_per_sequence, frames
	String wave_image
	sprintf wave_image, "%s%d", focus_name, focus_num
	frames_per_sequence=1
	frames=1
	image_trig=0			// set to one for triggered images
//	image_focus=0		// set to one when focusing (check if this is needed)
	if (ccd_opened<1)
//		SIDX_Begin()
		SIDX_Begin_Auto()
	endif
//	SIDX_Setup()
	SIDX_Setup_Auto()
	printf "Focusing (press space bar to stop) ..."
	FluorescenceON()
	Execute "Sleep /S 0.1"
	SIDX_Focus()
	FluorescenceOFF()
	full_num+=1; focus_num=full_num
	printf "%s: Focus Image done\r", wave_image
End

Proc Acquire_Full_Image()
	Variable sidx_handle, status, exposure, canceled
	String message
	String wave_image
	Variable frames_per_sequence, frames
	sprintf wave_image, "%s%d", full_name, full_num
	frames_per_sequence=1
	frames=1
	image_trig=0		// set to one for triggered images
	xbin=1; ybin=1
	if (ccd_opened<1)
//		SIDX_Begin()
		SIDX_Begin_Auto()
	endif
//	SIDX_Setup()
	SIDX_Setup_Auto()
	FluorescenceON()
	Execute "Sleep /S 0.1"
	SIDX_Acquisition(wave_image, frames_per_sequence, frames)
//	CCD_Acquire()
	FluorescenceOFF()
	Image_Display(wave_image)
	printf "%s%d: Full Image done\r", full_name, full_num
	all_images=WaveList(full_name+"*",";","")+WaveList(imageseq_name+"*",";","")
	full_num+=1; focus_num=full_num
End

Proc Image_Stack(trig, disp)
	Variable trig, disp
//	trig: one=triggered, zero=not triggered
//	disp: one=display stack, zero=don't display stack
	Variable sidx_handle, status, exposure, canceled
	String message
	String wave_image, datawavename
	Variable frames_per_sequence, frames
	sprintf wave_image, "%s%d", imageseq_name, wavenumber
	frames_per_sequence=ccd_frames
	frames=ccd_frames
	image_trig=trig		// set to one for triggered images
	if (ccd_opened<1)
		SIDXBegin()
	endif
	FluorescenceON()
	Execute "Sleep /S 0.1"
	im_plane=0
	SIDX_Acquisition(wave_image, frames_per_sequence, frames)
	FluorescenceOFF()
	if (disp>0)
		Image_Display(image)
	endif
	printf "%s%d: Image Stack done\r", imageseq_name, wavenumber
	if (image_trig<1)
		wavenumber+=1		
	endif
//	might want to add code to make an empty data wave if the image stack is taken on its own
End

//------------------------------------------------------ IMAGE LOAD PROCEDURES ----------------------------------------------//
//-----------------------------------------------------LOAD FROM FILE AND DISPLAY-------------------------------------------//

Proc Load_Full_Image()
	Silent 1; PauseUpdate
	String newimage
	Variable low, high
	sprintf newimage, "%s%d", full_name, full_num
	GBLoadWave/B/T={80,80}/S=4100/W=1/N=temp
	Duplicate /O temp0 $newimage
	Killwaves temp0
	Redimension /N=(512,512,1) $newimage
	Image_Display(newimage)
	AutoGrayScaleButtonProc("autogray_button0")
	printf "%s%d: Image loaded\r", full_name, full_num
	full_num+=1; focus_num=full_num
End

Proc Load_Image_Stack(stacknum, numimages)
//	this is not recently tested, but can be used for loading image stacks from WinView files saved as TIFF
//	when updating, use Load_Image as a template, as it is more up to date
	Variable stacknum, numimages
	Variable infile, outfile
	// data file types
	// 80 for 16-bit unsigned integer (raw binned data)
	// 2 for float (for post-process binned data)
	// 4 for double float
	infile=80; outfile=4
	Silent 1; PauseUpdate
	String newimage, filename, getbinary
	//	NewPath Images "C:Nelson:Imaging Expts:..........."
	sprintf filename, "%s%d.SPE", imagename, stacknum
	sprintf getbinary, "GBLoadWave/P=Images/B/T={%d,%d}/S=4100/W=1/N=temp \"%s\"", infile, outfile, filename
//	print getbinary
	sprintf newimage, "stack_%d", stacknum
	Execute getbinary
	Make /O/N=(numimages-1) $newimage
	DoWindow /F ImagingPanel
	ControlInfo bkgndcheck0
	if (V_value<1)
		$newimage=temp0[p+1]	// use this if there is no background subtraction
	else
		$newimage=temp0[2*(p+1)]-temp0[2*(p+1)+1]	// use this if there are alternating data and bkgnd points in array
	endif
	Killwaves temp0
End

//---------------------------------------------------------- IMAGE DISPLAY PROCEDURES -----------------------------------------//

Window Image_Display(image): Graph
	String image=gimage
	Prompt image, "Enter image wave", popup, WaveList(full_name+"*",";","")+WaveList(imageseq_name+"*",";","");
	gimage=image
	String wave=image
	String command
	PauseUpdate
	Variable numplanes
	numplanes=DimSize($wave, 2)
	im_plane=0
	all_images=WaveList(full_name+"*",";","")+WaveList(imageseq_name+"*",";","")
	if (wintype("Image_Display")<1)
		Display /W=(45,40,345,340) as "Image_Display"
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
	PopupMenu image_popup0,mode=WhichListItem(wave,all_images)+1
	sprintf command, "RemoveImage %s", ImageNameList("Image_Display",";")
	Execute command
	AppendImage $wave
//	SetAxis/A/R left
	ControlInfo auto_on_fly_check0
	if (V_Value>0)
		AutoGrayScaleButtonProc("autogray_button0")
	else
		ModifyImage $wave ctab= {gray_low,gray_high,Grays,0}
	endif
	ModifyGraph margin(left)=29,margin(bottom)=22,margin(top)=36,gfSize=8,gmSize=8
	ModifyGraph manTick={0,64,0,0},manMinor={8,8}
End

//------------------------------------------------------------------------ DF/F PROCEDURES -------------------------------------------//

Proc Get_DFoverF_from_Stack(stacknum)
	Variable stacknum
	Variable i, numbase
	numbase=16
	Silent 1; PauseUpdate
	Variable basef
	String stack, newimage
	sprintf stack, "%s%d", imageseq_name, stacknum
	sprintf newimage, "dff_%d", stacknum
	print stack, newimage
	DeletePoints /M=2 0,1, $stack		// kill the first plane of $stack
//	Duplicate /O $stack $newimage
	Make /O/N=(numpnts($stack)) $newimage
	basef=0
	i=0
	do
		basef+=$stack[i]
		i+=1
	while(i<numbase)
	basef=basef/numbase
	$newimage=100*(basef-$stack)/basef
	SetScale/P x 0,ccd_seqexp,"ms", $newimage
End

//----THIS ONE IS FOR THE MORE COMPLEX CASE OF A WHOLE IMAGE INSTEAD OF JUST 2 PTS---STILL NEEDS MORE WORK

Proc Get_DFoverF_from_Stack2(stacknum)
	Variable stacknum
	Variable index, numbase, basef
	String stack, dffwave
	Silent 1; PauseUpdate
	numbase=3
	sprintf stack, "%s%d", imageseq_name, stacknum
	print stack
	sprintf dffwave, "dff_%d", stacknum
	Make /O/N=(ccd_frames-1) tempwave $dffwave
	DoWindow /F ImagingPanel
	ControlInfo bkgndcheck0
	if (V_value<1)
		tempwave=$stack[0][0][p+1]	// use this if there is no background subtraction
	else
		tempwave=$stack[0][0][p+1]-$stack[1][0][p+1]	// use this if there are alternating data and bkgnd points in array
	endif
	do
		basef+=tempwave[index]
		index+=1
	while(index<numbase)
	basef=basef/numbase
	$dffwave=100*(basef-tempwave)/basef
	SetScale/P x 0,ccd_seqexp,"ms", $dffwave
	Killwaves tempwave
End

Proc Show_DFoverF(wavenum)
	Variable wavenum
//	String stack
	String newimage
//	sprintf stack, "stack_%d", wavenum
	sprintf newimage, "dff_%d", wavenum
	Display /W=(5,40,405,250) $newimage
	ModifyGraph mode=6
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph lsize(dff_temp)=1.5
End

Proc Append_DFoverF(stacknum)
	Variable stacknum, leftmin, leftmax
//	String stack
	String newimage
//	sprintf stack, "stack_%d", stacknum
	sprintf newimage, "dff_%d", stacknum
	PauseUpdate
	Append $newimage
	DoWindow /F ImagingPanel
	ControlInfo showimageavg_check0
	if (V_value>0)
		if (imageavgn<1)
			Duplicate /O $newimage dff_avg
			imageavgn+=1
		else
			dff_avg*=imageavgn
			dff_avg+=$newimage
			imageavgn+=1
			dff_avg/=imageavgn
			Append dff_avg
		endif
	endif
	ModifyGraph rgb($newimage)=(0,0,0)
	ModifyGraph lsize($newimage)=1.5
	ModifyGraph mode($newimage)=6
	ModifyGraph marker($newimage)=19
//	print imageavgn
	if (imageavgn>1)
		ModifyGraph lsize(dff_avg)=1.5,rgb(dff_avg)=(0,52224,0)
		ModifyGraph offset(dff_avg)={50,0}
	endif
	Wavestats /Q $thiswave
	leftmin=V_min
	leftmax=V_max
	Wavestats /Q $newimage
	if (V_min<leftmin)
		leftmin=V_min
	endif
	if (V_max>leftmax)
		leftmax=V_max
	endif
	Setaxis left, leftmin, leftmax
End

//----------------------------------------------------- ROI PROCEDURES -----------------------------------//

Proc GetROI(): GraphMarquee
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
End

Proc GetBkgndROI(): GraphMarquee
	GetMarquee /K left, bottom
	roinum=2
	roi_left=V_left; roi_right=V_left+xpixels
	xbin=1
	ybin=1
	xpixels=(roi_right-roi_left+1)/xbin
	ypixels=(roi_top-roi_bottom+1)/ybin
	roiwave[][roinum]={roi_left, roi_right, roi_top, roi_bottom, xbin, xpixels}
	DrawROI()
End

Proc GetROI_and_Bkgnd(): GraphMarquee
	GetROI()
	roinum=2
	roi_left+=200; roi_right=roi_left+xpixels
	roiwave[][roinum]={roi_left, roi_right, roi_top, roi_bottom, xbin, xpixels}
	DrawROI()
End

Proc Get_10x10_ROI(): GraphMarquee
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
End

Proc Get_10x10_ROI_and_Bkgnd(): GraphMarquee
	GetMarquee /K left, bottom
	Get_10x10_ROI()
	roinum=2
	roi_left+=200; roi_right=roi_left+9
	roiwave[][roinum]={roi_left, roi_right, roi_top, roi_bottom, xbin, xpixels}
	DrawROI()
End

Proc DrawROI()
	PauseUpdate; Silent 1
	String removeit, thebox_x, thebox_y, doit
	sprintf thebox_y, "roibox_y%d", roinum
	$thebox_y={roi_top, roi_top, roi_bottom, roi_bottom, roi_top}
	sprintf thebox_x, "roibox_x%d", roinum
	$thebox_x={roi_left, roi_right, roi_right, roi_left, roi_left}
	if (wintype("Image_Display")>0)
		DoWindow /F Image_Display
		removeit=Wavelist("roibox_y*",";","WIN:Image_Display")
		RemoveWaves(removeit,"Image_Display")
		Append roibox_y1 vs roibox_x1
		ModifyGraph /Z lsize(roibox_y1)=1.5
		Append roibox_y2 vs roibox_x2
		ModifyGraph /Z lsize(roibox_y2)=1.5,rgb(roibox_y2)=(0,65280,0)
	endif
End

Function SetROIProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	WAVE roiwave=roiwave, roibox_x=roibox_x, roibox_y=roibox_y
	NVAR roinum=roinum
	NVAR roi_left=roi_left, roi_right=roi_right, xbin=xbin, xpixels=xpixels
	NVAR roi_top=roi_top, roi_bottom=roi_bottom, ybin=ybin, ypixels=ypixels
	xpixels=(roi_right-roi_left+1)/xbin
	ypixels=(roi_bottom-roi_top+1)/ybin
	roiwave[][roinum]={roi_left, roi_right, roi_top, roi_bottom, xbin, ybin}
	Execute "DrawROI()"
End

Function GetROIProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
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
End

Function ImagePlaneSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	NVAR im_plane=im_plane, previouswave=previouswave
	SVAR imageseq_name=imageseq_name
	String command
	sprintf command, "ModifyImage \'\'#0 plane=%d", im_plane
	Execute command
End

Function GrayScaleSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	NVAR gray_low=gray_low, gray_high=gray_high
	String command
	sprintf command, "ModifyImage \'\'#0 ctab= {%d,%d,Grays,0}", gray_low, gray_high
	Execute command
End

Function AutoGrayScaleButtonProc(ctrlName) : ButtonControl
	String ctrlName
	NVAR gray_low=gray_low, gray_high=gray_high, full_num=full_num
	NVAR V_min=V_min, V_max=V_max, im_plane=im_plane
	SVAR full_name=full_name
	Variable min, max
//	Execute "ModifyImage \'\'#0 ctab= {*,*,Grays,0}"
	String imagename, command
	sprintf imagename, "%s", WaveList("full_*","","WIN:")
	// ignore the first col when doing imagestats, because for some reason its values are too high
	sprintf command, "ImageTransform /P=%d getplane %s", im_plane, imagename
	Execute command
	sprintf command, "Imagestats /M=1/G={0,506,2,506} M_ImagePlane"
	Execute command
	gray_low=V_min
	gray_high=V_max
//	uncomment the following lines if you want to do it manually
//	e.g. 5-95% instead of full range
//	gray_low=round(V_min+0.05*(V_max-V_min))
//	gray_high=round(V_min+0.95*(V_max-V_min))
//	print V_min, V_max, gray_low, gray_high
	sprintf command, "ModifyImage \'\'#0 ctab= {%d,%d,Grays,0}", gray_low, gray_high
	Execute command
End

Proc DFF_From_Stack(imagestack)
	String imagestack=gstack
	Prompt imagestack, "Enter image stack wave", popup, WaveList(full_name+"*",";","");trig_name+"*";
	gstack=imagestack
	Silent 1
	Variable index, numbaseline, numtest, low, high
	String basename, number, next, image, mathwave, doit
	numbaseline=4
	numtest=4
//	sprintf image "%s%s", basename, number
	sprintf mathwave "%s_math", image
	Duplicate /O $imagestack $mathwave
	Redimension/D/N=(-1,-1) im_123_math
	$mathwave=0
	Duplicate /O $mathwave, basewave, testwave
	do
		ImageTransform /p=(index) getPlane $imagestack
		basewave+=M_ImagePlane
		index+=1
	while(index<(numbaseline+1))
	basewave=basewave/numbaseline
	print "these loops are taking too damn long"
	do
		ImageTransform /p=(index) getPlane $imagestack
		testwave+=M_ImagePlane
		index+=1
	while(index<(numbaseline+numtest+1))
	testwave=testwave/numtest
//	Wavestats /Q/R=(0,512) testwave
//	background=V_avg
  	$mathwave=-100*(testwave-basewave)/basewave
 	Wavestats /Q $mathwave
 	low=V_min+0.1*(V_max-V_min)
 	high=V_max-0.1*(V_max-V_min)
 	print V_min, V_max, low, high
	ImageDisplay(mathwave)
//	ModifyImage $mathwave ctab= {low,high,Grays,0}
End

//------------------------------------- START OF BUTTON AND SETVAR PROCEDURES  ----------------------------------------------//

Function DFFButtonProc(ctrlName) : ButtonControl
	String ctrlName
	String command
	NVAR previouswave=previouswave
	sprintf command, "Get_DFoverF_from_Stack(%d)", previouswave
	Execute command
	sprintf command, "Append_DFoverF(%d)", previouswave
	Execute command
End

Function ResetAvgButtonProc(ctrlName) : ButtonControl
	String ctrlName
	NVAR imageavgn=imageavgn
	Wave average=dff_avg
	average=0
	imageavgn=0
End

Function SetCCDTempVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Execute "CCD_Temp_Set()"
End

Function StackButtonProc(ctrlName) : ButtonControl
	String ctrlName
	Execute "Image_Stack(0,0)"
End

Function FullButtonProc(ctrlName) : ButtonControl
	String ctrlName
	Execute "Acquire_Full_Image()"
End

Function FocusButtonProc(ctrlName) : ButtonControl
	String ctrlName
	Execute "Focus_Image()"
End

Function EphysImageButtonProc(ctrlName) : ButtonControl
	String ctrlName
	Execute "EPhys_Image()"
End

Function ImagePopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	String command
	sprintf command, "Image_Display(\"%s\")", popStr
	Execute command
End
//--------------------------------------- END OF BUTTON AND SETVAR PROCEDURES---------------------------------------//

//------------------------------------------------------ END OF IMAGING PROCEDURES ----------------------------------------//
