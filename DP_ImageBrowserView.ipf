//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

//---------------------------------------------------------- IMAGE DISPLAY PROCEDURES -----------------------------------------//

Function ImageBrowserViewConstructor()
	// If the view already exists, just bring it forward
	Variable windowExists=GraphExists("ImageBrowserView")
	if (windowExists)
		DoWindow /F ImageBrowserView
		return 0
	endif

	// Create the graph window, widgets
	Display /W=(45,40,45+310,40+300) /K=1 /N=ImageBrowserView as "Image Browser"

	ControlBar /T /W=ImageBrowserView 56

	PopupMenu image_popup0,win=ImageBrowserView,pos={16,6},size={110,24},proc=ImagePopMenuProc,title="Image"
	PopupMenu image_popup0,win=ImageBrowserView,value="(none)",mode=1

	SetVariable plane_setvar0,win=ImageBrowserView,pos={26,32},size={70,16},proc=ImagePlaneSetVarProc,title="Frame:"
	
	SetVariable gray_setvar0,win=ImageBrowserView,pos={126,8},size={130,16},proc=BlackCountSetVarProc,title="Black count:"
	SetVariable gray_setvar0,win=ImageBrowserView,limits={0,2^16-1,1024}

	SetVariable gray_setvar1,win=ImageBrowserView,pos={126,30},size={130,16},proc=WhiteCountSetVarProc,title="White count:"
	SetVariable gray_setvar1,win=ImageBrowserView,limits={0,2^16-1,1024}

	Button autogray_button0,win=ImageBrowserView,pos={280,8},size={80,20},proc=AutoGrayScaleButtonProc,title="Autoscale"

	CheckBox auto_on_fly_check0,win=ImageBrowserView,pos={280,32},size={111,14},title="Autoscale on the fly"
	CheckBox auto_on_fly_check0,win=ImageBrowserView, proc=ImageBrowserContAutoscaleCB
End





Function ImageBrowserViewModelEtcChanged()
	// The Etc is because this is intended to signal the ImagerBrowserView that either the
	// ImagerBrowserModel or the Imager has changed.
	ImageBrowserViewUpdate()
End






Function ImageBrowserViewUpdate()
	// If the view doesn't exist, nothing to do
	if (!GraphExists("ImageBrowserView"))
		return 0
	endif

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel

	// Update the autoscaleOnFly checkbox
	Variable autoscaleOnTheFly=ImageBrowserModGetAutoscaleFly()
	CheckBox auto_on_fly_check0, win=ImageBrowserView, value=autoscaleOnTheFly
	
	// Update the image popup
	String imageWaveName=ImageBrowserModGetImWaveName()
	String imageWaveNameAbs=ImageBrowserModGetImWaveNameAbs()
	String allVideoWaveNames=ImagerGetAllVideoWaveNames()
	String allVideoWaveNamesFU="\""+allVideoWaveNames+"\""
	Variable iVideo=WhichListItem(imageWaveName,allVideoWaveNames)
	PopupMenu image_popup0, win=ImageBrowserView, mode=iVideo+1, value= #allVideoWaveNamesFU

	// Update the frame selector
	Variable nFrames=DimSize($imageWaveNameAbs, 2)
	Variable iFrame=ImageBrowserModelGetIFrame()
	SetVariable plane_setvar0,win=ImageBrowserView,limits={0,nFrames-1,1}, value=_NUM:iFrame

	// Update the blackCount SetVariable
	Variable blackCount=ImageBrowserModelGetBlackCount()
	SetVariable gray_setvar0,win=ImageBrowserView, value= _NUM:blackCount
	
	// Update the whiteCount SetVariable
	Variable whiteCount=ImageBrowserModelGetWhiteCount()	
	SetVariable gray_setvar1, win=ImageBrowserView, value= _NUM:whiteCount
	
	// Update the image
	//String oldImageName=ImageNameList("ImageBrowserView",";")
	//printf "oldImageName: %s\r", oldImageName
	//RemoveImage /Z /W=ImageBrowserView $oldImageName
	RemoveAllImagesFromGraph("ImageBrowserView")
	AppendImage /W=ImageBrowserView /G=1 $imageWaveNameAbs
	ModifyImage /W=ImageBrowserView $imageWaveName ctab= {blackCount,whiteCount,Grays,0}, plane=iFrame
	SetAxis /W=ImageBrowserView /A /R left
	
	// Position the plot	
	ModifyGraph /W=ImageBrowserView gfSize=8,gmSize=8
	ModifyGraph /W=ImageBrowserView manTick={0,64,0,0},manMinor={8,8}

	// Make the pixels square, with the larger dim being auto-sized
	//Variable widthInPels=DimSize($imageWaveNameAbs,0)
	//Variable heightInPels=DimSize($imageWaveNameAbs,1)
	ModifyGraph /W=ImageBrowserView width=0, height={Plan,1,left,bottom}
//	if (widthInPels>heightInPels)
//		ModifyGraph /W=ImageBrowserView width=0, height={Plan,1,left,bottom}
//		//ModifyGraph /W=ImageBrowserView margin(left)=29
//	else
//		ModifyGraph /W=ImageBrowserView height=0, width={Plan,1,bottom,left}
//		//ModifyGraph /W=ImageBrowserView margin(bottom)=22,margin(top)=36
//	endif
	
	// Update the ROIs
	RemoveAllTracesFromGraph("ImageBrowserView")	
	Variable nROIs=ImagerGetNROIs()
	Variable iROICurrent=ImagerGetIROI()
	Variable iROI
	for (iROI=0; iROI<nROIs; iROI+=1)
		if (iROI==iROICurrent)	
			continue
		endif
		ImageBrowserViewDrawROI(iROI,iROICurrent)
	endfor
	// Draw the current ROI last, so that it's on top
	if (nROIs>0)
		ImageBrowserViewDrawROI(iROICurrent,iROICurrent)
	endif
	
	// Restore the original DF
	SetDataFolder savedDF	 	
End






// Private methods
Function ImageBrowserViewDrawROI(iROI,iROICurrent)
	// Draws the indicated ROI.  If iROI==iROICurrent, draws it a different color to indicate this
	Variable iROI
	Variable iROICurrent
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel

	String xBoxName=sprintf1v("xBox%d",iROI)
	Wave xBox=$xBoxName
	String yBoxName=sprintf1v("yBox%d",iROI)
	Wave yBox=$yBoxName
	AppendToGraph /W=ImageBrowserView yBox vs xBox
	//Print TraceNameList("ImageBrowserView",";",3)
	//ModifyGraph /W=ImageBrowserView lsize($yBoxName)=1.5
	if (iROI==iROICurrent)
		ModifyGraph /W=ImageBrowserView rgb($yBoxName)=(0,0.7*65535,65535)
	else
		ModifyGraph /W=ImageBrowserView rgb($yBoxName)=(0,0,65535)
	endif

	// Restore the original DF
	SetDataFolder savedDF	 	
End
