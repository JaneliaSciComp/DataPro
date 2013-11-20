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
	ImageBrowserContSetVideo(popStr)
	
	// Restore the original DF
	SetDataFolder savedDF
End







Function ImageBrowserContSetVideo(imageWaveName)
	String imageWaveName
	
	ImageBrowserModelSetVideo(imageWaveName)
	RaiseOrCreateView("ImageBrowserView")
	ImageBrowserViewModelChanged()	
End
