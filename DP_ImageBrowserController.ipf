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

