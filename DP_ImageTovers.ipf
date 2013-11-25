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
	SetDataFolder root:DP_Imager

	// instance vars
	SVAR fullFrameWaveBaseName
	NVAR iFullFrameWave
	NVAR iFocusWave

	//Silent 1; PauseUpdate
	//Variable low, high
	String newImageWaveName=sprintf2sv("%s%d", fullFrameWaveBaseName, iFullFrameWave)
	GBLoadWave /B /T={80,80} /S=4100 /W=1 /N=temp
	Rename temp0 $newImageWaveName
	//Duplicate /O temp0 $newImageWaveName
	//Killwaves temp0
	Redimension /N=(512,512,1) $newImageWaveName
	ImageBrowserContSetVideo(newImageWaveName)
	AutoGrayScaleButtonProc("autogray_button0")
	printf "%s%d: Image loaded\r", fullFrameWaveBaseName, iFullFrameWave
	iFullFrameWave+=1
	iFocusWave=iFullFrameWave
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function Load_Image_Stack(stacknum, numimages)
//	this is not recently tested, but can be used for loading image stacks from WinView files saved as TIFF
//	when updating, use Load_Image as a template, as it is more up to date
	Variable stacknum, numimages
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
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

	//sprintf getbinary, "GBLoadWave/P=Images/B/T={%d,%d}/S=4100/W=1/N=temp \"%s\"", infile, outfile, filename
	//Execute getbinary
	GBLoadWave /P=Images /B /T={infile,outfile} /S=4100 /W=1 /N=temp filename

	sprintf newImageWaveName, "stack_%d", stacknum
	Make /O /N=(numimages-1) $newImageWaveName
	WAVE newImageWave=$newImageWaveName
	DoWindow /F ImagerView
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
	SetDataFolder root:DP_Imager
	
	// instance vars
	SVAR videoWaveBaseName
	NVAR nFramesForVideo
	NVAR videoExposure
	
	Variable index, basef
	Variable numbase=3
	String stackWaveName=sprintf2sv("%s%d", videoWaveBaseName, stacknum)
	print stackWaveName
	String dffWaveName=sprintf1v("dff_%d", stacknum)
	Make /O /N=(nFramesForVideo-1) tempwave, $dffWaveName
	WAVE stackWave=$stackWaveName
	DoWindow /F ImagerView
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
	SetScale/P x 0,videoExposure,"ms", dffWave
	Killwaves tempwave
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function Show_DFoverF(wavenum)
	Variable wavenum
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
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
	SetDataFolder root:DP_Imager

	// instance vars
	NVAR iROI
	NVAR iROILeft, iROIRight, iROITop, iROIBottom
	NVAR binWidth, binHeight
	//NVAR binnedFrameWidth, binnedFrameHeight
	WAVE roisWave

	GetMarquee /K left, bottom
	iROI=0
	iROILeft=V_left; iROIRight=V_right
	iROITop=V_top; iROIBottom=V_bottom
	binWidth=1
	binHeight=1
	//binnedFrameWidth=(iROIRight-iROILeft+1)/binWidth
	//binnedFrameHeight=(iROITop-iROIBottom+1)/binHeight
	roisWave[][iROI]={iROILeft, iROIRight, iROITop, iROIBottom, binWidth, binHeight}
	ImageBrowserViewModelChanged()
	
	// Update the view
	ImagerViewModelChanged()
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function GetBkgndROI(): GraphMarquee
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// instance vars
	NVAR iROI
	NVAR iROILeft, iROIRight, iROITop, iROIBottom
	NVAR binWidth, binHeight
	//NVAR binnedFrameWidth, binnedFrameHeight
	WAVE roisWave

	GetMarquee /K left, bottom
	iROI=1		// the background ROI
	iROILeft=V_left
	iROIRight=V_right
	binWidth=1
	binHeight=1
	//binnedFrameWidth=(iROIRight-iROILeft+1)/binWidth
	//binnedFrameHeight=(iROITop-iROIBottom+1)/binHeight
	roisWave[][iROI]={iROILeft, iROIRight, iROITop, iROIBottom, binWidth, binHeight}
	ImageBrowserViewModelChanged()

	// Update the view
	ImagerViewModelChanged()
		
	// Restore the original DF
	SetDataFolder savedDF
End

Function GetROI_and_Bkgnd(): GraphMarquee
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// instance vars
	NVAR iROI
	NVAR iROILeft, iROIRight, iROITop, iROIBottom
	NVAR binWidth, binHeight
	//NVAR binnedFrameWidth, binnedFrameHeight
	WAVE roisWave

	GetROI()
	iROI=1	// the background ROI
	iROILeft+=200; 
	Variable binnedFrameWidth=(iROIRight-iROILeft+1)/binWidth
	iROIRight=iROILeft+binnedFrameWidth
	roisWave[][iROI]={iROILeft, iROIRight, iROITop, iROIBottom, binWidth, binHeight}
	ImageBrowserViewModelChanged()
	
	// Update the view
	ImagerViewModelChanged()
		
	// Restore the original DF
	SetDataFolder savedDF
End

Function Get_10x10_ROI(): GraphMarquee
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// instance vars
	NVAR iROI, iROILeft, iROIRight, iROITop, iROIBottom
	NVAR binWidth, binHeight
	//NVAR binnedFrameWidth, binnedFrameHeight
	WAVE roisWave

	GetMarquee /K left, bottom
	iROI=0	// the primary ROI
	binWidth=10
	binHeight=10
	iROILeft=round(V_left+(V_right-V_left)/2); iROIRight=iROILeft+binWidth-1
	iROITop=round(V_top-(V_top-V_bottom)/2); iROIBottom=iROITop-binHeight+1
	//binnedFrameWidth=(iROIRight-iROILeft+1)/binWidth
	//binnedFrameHeight=(iROITop-iROIBottom+1)/binHeight
	roisWave[][iROI]={iROILeft, iROIRight, iROITop, iROIBottom, binWidth, binHeight}
	ImageBrowserViewModelChanged()
	
	// Update the view
	ImagerViewModelChanged()
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function Get_10x10_ROI_and_Bkgnd(): GraphMarquee
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// instance vars
	NVAR iROI, iROILeft, iROIRight, iROITop, iROIBottom
	NVAR binWidth, binHeight
	//NVAR binnedFrameWidth, binnedFrameHeight
	WAVE roisWave

	GetMarquee /K left, bottom
	Get_10x10_ROI()
	iROI=1
	iROILeft+=200; iROIRight=iROILeft+9
	roisWave[][iROI]={iROILeft, iROIRight, iROITop, iROIBottom, binWidth, binHeight}
	ImageBrowserViewModelChanged()
	
	// Update the view
	ImagerViewModelChanged()
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function DFF_From_Stack(imagestack)
	String imagestack
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// instance vars
	SVAR fullFrameWaveBaseName
	SVAR trig_name	

	//String imagestack=gstack
	//Prompt imagestack, "Enter image stack wave", popup, WaveList(fullFrameWaveBaseName+"*",";","");trig_name+"*";		// Not sure what this is supposed to be
	Prompt imagestack, "Enter image stack wave", popup, WaveList(fullFrameWaveBaseName+"*",";","")
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
	ImageBrowserContSetVideo(mathWaveName)
//	ModifyImage $mathWaveName ctab= {low,high,Grays,0}
	
	// Restore the original DF
	SetDataFolder savedDF
End





Function SetVDTPort(name)
	String name

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

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

