//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

Function ImagePlaneSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// instance variables
	NVAR iFrame
	NVAR previouswave
	SVAR videoWaveBaseName
	
	// Do stuff
	//String command
	//sprintf command, "ModifyImage \'\'#0 plane=%d", iFrame
	//Execute command
	ModifyImage ''#0 plane=(iFrame)
	
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
	SetDataFolder root:DP_Imager

	// instance vars
	NVAR blackCount=blackCount
	NVAR whiteCount=whiteCount
	
	ModifyImage ''#0 ctab= {blackCount,whiteCount,Grays,0}
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function AutoGrayScaleButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// instance vars
	NVAR blackCount
	NVAR whiteCount
	NVAR full_num
	NVAR iFrame
	SVAR fullFrameWaveBaseName
	
	String imageWaveName=WaveList("full_*","","WIN:")
	//String command

	//sprintf command, "ImageTransform /P=%d getplane %s", iFrame, imageWaveName
	//Execute command
	//WAVE M_ImagePlane	// "returned" from ImageTransform
	//ImageTransform /P=(iFrame) getPlane imageWaveName

	//sprintf command, "Imagestats /M=1/G={0,506,2,506} M_ImagePlane"
	//Execute command
	
	Imagestats /M=1 $imageWaveName
	blackCount=V_min
	whiteCount=V_max
	
	//sprintf command, "ModifyImage \'\'#0 ctab= {%d,%d,Grays,0}", blackCount, whiteCount
	//Execute command
	
	ModifyImage ''#0 ctab= {blackCount,whiteCount,Grays,0}
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function ImagePopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	//String command
	//sprintf command, "Image_Display(\"%s\")", popStr
	//Execute command
	ImageBrowserContSetCurrentVideo(popStr)
	
	// Restore the original DF
	SetDataFolder savedDF
End


Function ImageBrowserContSetCurrentVideo(imageWaveName)
	String imageWaveName
	
	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	//SVAR gimage
	NVAR iFrame		// the index of the video frame currently being shown
	//SVAR allVideoWaveNames		// a semicolon-separated list of all the video wave names
	SVAR fullFrameWaveBaseName		// the base name of the full-frame image waves
	SVAR videoWaveBaseName	// the base name of the triggered video waves, including the underscore
	NVAR blackCount
	NVAR whiteCount
	
	//String imageWaveName=gimage
	//Prompt imageWaveName, "Enter image wave", popup, WaveList(fullFrameWaveBaseName+"*",";","")+WaveList(videoWaveBaseName+"*",";","");
	//gimage=imageWaveName
	//String wave=imageWaveName
	//String command
	Variable nFrames=DimSize($imageWaveName, 2)
	iFrame=0
	printf "wintype(\"Image_Display\"): %d\r", wintype("Image_Display")
	if ( wintype("Image_Display")<1 )
	//if ( !GraphExists("Image_Display") )
		// If no window named Image_Display exists, create one
		Display /W=(45,40,345,340) /K=1 as "Image Browser"			// Create the graph window
		SetVariable plane_setvar0,pos={45,23},size={80,16},proc=ImagePlaneSetVarProc,title="plane"
		SetVariable plane_setvar0,limits={0,nFrames-1,1},value= iFrame
		SetVariable gray_setvar0,pos={137,1},size={130,16},proc=GrayScaleSetVarProc,title="gray low"
		SetVariable gray_setvar0,limits={0,64000,1000},value= blackCount
		SetVariable gray_setvar1,pos={137,23},size={130,16},proc=GrayScaleSetVarProc,title="gray high"
		SetVariable gray_setvar1,limits={0,64000,1000},value= whiteCount
		Button autogray_button0,pos={282,0},size={80,20},proc=AutoGrayScaleButtonProc,title="Autoscale"
		CheckBox auto_on_fly_check0,pos={282,25},size={111,14},title="Autoscale on the fly"
		CheckBox auto_on_fly_check0,value= 0
		PopupMenu image_popup0,pos={17,0},size={111,21},proc=ImagePopMenuProc,title="Image"
		PopupMenu image_popup0,mode=26	//,value= #"allVideoWaveNames"
		PopupMenu image_popup0,mode=1
	else
		// If a window named Image_Display exists, update the plane index SetVariable
		SetVariable plane_setvar0,limits={0,nFrames-1,1},value= iFrame
	endif
	DoWindow /F Image_Display	// Bring window named Image_Display to front
	String allVideoWaveNames=WaveList(fullFrameWaveBaseName+"*",";","")+WaveList(videoWaveBaseName+"*",";","")
	PopupMenu image_popup0,value= #"allVideoWaveNames"
	PopupMenu image_popup0,mode=WhichListItem(imageWaveName,allVideoWaveNames)+1
	//sprintf command, "RemoveImage %s", ImageNameList("Image_Display",";")
	//Execute command
	String oldImageWaveName=ImageNameList("Image_Display",";")
	printf "oldImageWaveName: %s\r", oldImageWaveName
	RemoveImage /Z $oldImageWaveName
	AppendImage $imageWaveName
//	SetAxis/A/R left
	ControlInfo auto_on_fly_check0
	if (V_Value>0)
		AutoGrayScaleButtonProc("autogray_button0")
	else
		ModifyImage $imageWaveName ctab= {blackCount,whiteCount,Grays,0}
	endif
	ModifyGraph margin(left)=29,margin(bottom)=22,margin(top)=36,gfSize=8,gmSize=8
	ModifyGraph manTick={0,64,0,0},manMinor={8,8}
	
	// Restore the original DF
	SetDataFolder savedDF	
End
