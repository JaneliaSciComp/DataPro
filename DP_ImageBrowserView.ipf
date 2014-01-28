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
	Display /W=(45,40,45+360,40+360) /K=1 /N=ImageBrowserView as "Image Browser"

	ControlBar /T /W=ImageBrowserView 56

	PopupMenu image_popup0,win=ImageBrowserView,pos={16,6},size={110,24},proc=ImagePopMenuProc,title="Image"
	PopupMenu image_popup0,win=ImageBrowserView,value="(none)",mode=1

	SetVariable plane_setvar0,win=ImageBrowserView,pos={26,32},size={70,16},proc=ImagePlaneSetVarProc,title="Frame:"
	
	SetVariable gray_setvar0,win=ImageBrowserView,pos={126,8},size={130,16},proc=BlackCountSetVarProc,title="Black Count:"
	SetVariable gray_setvar0,win=ImageBrowserView,limits={0,2^16-1,1024}

	SetVariable gray_setvar1,win=ImageBrowserView,pos={126,30},size={130,16},proc=WhiteCountSetVarProc,title="White Count:"
	SetVariable gray_setvar1,win=ImageBrowserView,limits={0,2^16-1,1024}

	Variable xOffset=268
	Button fullScaleButton,win=ImageBrowserView,pos={xOffset,18},size={80,20},proc=ImageBrowserContFullScale,title="Full Scale"

	xOffset+=94
	Button scaleToDataButton,win=ImageBrowserView,pos={xOffset,8},size={100,20},proc=ImageBrowserContScaleToData,title="Scale to Data"

	CheckBox autoscaleToDataCB,win=ImageBrowserView,pos={xOffset,32},size={112,14},title="Autoscale to Data"
	CheckBox autoscaleToDataCB,win=ImageBrowserView, proc=ImageBrowserContAutoscToData
	
	// Update the view to sync to the model
	ImageBrowserViewUpdate()
End





Function ImageBrowserViewModelEtcChanged()
	// The Etc is because this is intended to signal the ImagerBrowserView that either the
	// ImagerBrowserModel or the Imager has changed.
	ImageBrowserViewUpdate()
End




Function IBViewFocusFrameChanged()
	// Called to notify the view that we're focussing, and there's a new frame
	IBViewUpdateDuringFocus()
End






//
// Private methods
//

Function ImageBrowserViewUpdate()
	// If the view doesn't exist, nothing to do
	if (!GraphExists("ImageBrowserView"))
		return 0
	endif

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel

	// Update the autoscaleOnFly checkbox
	Variable autoscaleToData=ImageBrowserModGetAutoscToData()
	CheckBox autoscaleToDataCB, win=ImageBrowserView, value=autoscaleToData

	// Get some info about the model that will be useful
	Variable isCurrentImageWave=IBModelGetIsCurrentImageWave()
	String imageWaveName=ImageBrowserModGetImWaveName()
	String imageWaveNameAbs=ImageBrowserModGetImWaveNameAbs()
	
	// Update the image popup
	String allVideoWaveNames=ImagerGetAllVideoWaveNames()
	Variable nVideoWaves=ItemsInList(allVideoWaveNames)
	if (nVideoWaves==0)
		PopupMenu image_popup0,win=ImageBrowserView,value="(none)",mode=1
	else
		String allVideoWaveNamesFU
		if (isCurrentImageWave)	
			Variable iVideo=WhichListItem(imageWaveName,allVideoWaveNames)
			if (iVideo>=0)
				allVideoWaveNamesFU="\""+allVideoWaveNames+"\""
				PopupMenu image_popup0, win=ImageBrowserView, mode=iVideo+1, value= #allVideoWaveNamesFU
			else
				// This is an error condition---there's supposedly a current image, but the wave doesn't seem to be in the place where those live
				Abort "The current image doesn't seem to be where it's supposed to be."
			endif
		else
			// This is an odd situation---there's no current image wave, but there are videos available...
			allVideoWaveNamesFU="\""+"None Selected;"+allVideoWaveNames+"\""
			PopupMenu image_popup0, win=ImageBrowserView, mode=1, value= #allVideoWaveNamesFU			
		endif
	endif

	// Update the frame selector
	if ( isCurrentImageWave )
		Variable nFrames=DimSize($imageWaveNameAbs, 2)
		Variable iFrame=ImageBrowserModelGetIFrame()
		if (nFrames==0)
			SetVariable plane_setvar0, win=ImageBrowserView, value=_STR:"", disable=2
		else
			SetVariable plane_setvar0, win=ImageBrowserView, limits={0,nFrames-1,1}, value=_NUM:iFrame, disable=0
		endif
	else
		SetVariable plane_setvar0, win=ImageBrowserView, value=_STR:"", disable=2
	endif

	// Update the blackCount SetVariable
	Variable blackCount=ImageBrowserModelGetBlackCount()
	SetVariable gray_setvar0,win=ImageBrowserView, value= _NUM:blackCount, disable=(autoscaleToData ? 2 : 0)
	
	// Update the whiteCount SetVariable
	Variable whiteCount=ImageBrowserModelGetWhiteCount()	
	SetVariable gray_setvar1, win=ImageBrowserView, value= _NUM:whiteCount, disable=(autoscaleToData ? 2 : 0)

	// Update the enablement of the "Full Scale" button
	Button fullScaleButton, win=ImageBrowserView, disable=(autoscaleToData ? 2 : 0)
	
	// Update the enablement of the "Scale to Data" button: Don't need it if autoscale to data is on
	Button scaleToDataButton, win=ImageBrowserView, disable=( (!isCurrentImageWave||autoscaleToData) ? 2 : 0)

	// Update the enablement of the autoscale checkbox
	CheckBox autoscaleToDataCB,win=ImageBrowserView, value=(isCurrentImageWave&&autoscaleToData), disable=( !isCurrentImageWave ? 2 : 0 )

	// Update the image
	//String oldImageName=ImageNameList("ImageBrowserView",";")
	//printf "oldImageName: %s\r", oldImageName
	//RemoveImage /Z /W=ImageBrowserView $oldImageName
	RemoveAllImagesFromGraph("ImageBrowserView")
	if ( !isCurrentImageWave )
		SetDataFolder savedDF	 	
		return 0
	endif

	AppendImage /W=ImageBrowserView /G=1 $imageWaveNameAbs
	ModifyImage /W=ImageBrowserView $imageWaveName ctab= {blackCount,whiteCount,Grays,0}, plane=iFrame
	//SetAxis /W=ImageBrowserView /A /R left
	SetAxis /W=ImageBrowserView left, CameraCCDHeightGetInUS(), 0
	SetAxis /W=ImageBrowserView bottom, 0, CameraCCDWidthGetInUS()
	
	
	// Position the plot	
	ModifyGraph /W=ImageBrowserView gfSize=8	// Set font size to 8 pts
	ModifyGraph /W=ImageBrowserView gmSize=8	// Set default size for markers in the graph (?)
	ModifyGraph /W=ImageBrowserView manTick={0,64,0,0}, manMinor={8,8}	
		// Major axis ticks every 64 units, 8 minor ticks per major, every 8th minor tick is emphasized

	// Make the pixels square, with the height being auto-sized
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
	Variable iROICurrent=ImagerGetCurrentROIIndex()
	Variable iROIBackground=ImagerGetBackgroundROIIndex()
	Variable iROI
	for (iROI=0; iROI<nROIs; iROI+=1)
		if (iROI==iROICurrent)	
			continue
		endif
		ImageBrowserViewDrawROI(iROI,iROICurrent,iROIBackground)
	endfor
	// Draw the current ROI last, so that it's on top
	if (nROIs>0)
		ImageBrowserViewDrawROI(iROICurrent,iROICurrent,iROIBackground)
	endif
	
	// Restore the original DF
	SetDataFolder savedDF	 	
End



Function IBViewUpdateDuringFocus()
	// An update function that only updates things that need updating
	// after new frames are acquired during focussing

	// If the view doesn't exist, nothing to do
	if (!GraphExists("ImageBrowserView"))
		return 0
	endif

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel

	// Update the blackCount SetVariable
	Variable blackCount=ImageBrowserModelGetBlackCount()
	SetVariable gray_setvar0,win=ImageBrowserView, value= _NUM:blackCount
	
	// Update the whiteCount SetVariable
	Variable whiteCount=ImageBrowserModelGetWhiteCount()	
	SetVariable gray_setvar1, win=ImageBrowserView, value= _NUM:whiteCount

	// Update the image
	String imageWaveName=ImageBrowserModGetImWaveName()
	ModifyImage /W=ImageBrowserView $imageWaveName ctab= {blackCount,whiteCount,Grays,0}

	// Restore the original DF
	SetDataFolder savedDF	 	
End



Function ImageBrowserViewDrawROI(iROI,iROICurrent,iROIBackground)
	// Draws the indicated ROI.  If iROI==iROICurrent, draws it a different color to indicate this
	Variable iROI
	Variable iROICurrent
	Variable iROIBackground	
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel

	String xBoxName=sprintf1v("xBox%d",iROI)
	Wave xBox=$xBoxName
	String yBoxName=sprintf1v("yBox%d",iROI)
	Wave yBox=$yBoxName
	AppendToGraph /W=ImageBrowserView yBox vs xBox
	//Print TraceNameList("ImageBrowserView",";",3)
	ModifyGraph /W=ImageBrowserView rgb($yBoxName)=(0,0,65535)
	if (iROI==iROICurrent)
		ModifyGraph /W=ImageBrowserView lsize($yBoxName)=1.5
	else
		ModifyGraph /W=ImageBrowserView lsize($yBoxName)=1
	endif
	if (iROI==iROIBackground)
		ModifyGraph /W=ImageBrowserView lstyle($yBoxName)=2
	else
		ModifyGraph /W=ImageBrowserView lstyle($yBoxName)=0
	endif
	
	// Restore the original DF
	SetDataFolder savedDF	 	
End
