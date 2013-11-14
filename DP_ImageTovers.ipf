//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

// These are all the imaging-related functions whose proper place I haven't figured out yet.

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



//------------------------------------------------------------------------ DF/F PROCEDURES -------------------------------------------//


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

