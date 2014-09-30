//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access
// #pragma IndependentModule = DP	// Decided not to do, b/c want users to be able to modify hook functions

// These should all be in the same dir as this file, DataPro.ipf
#include ":DP_Sampler"
#include ":DP_DigitizerModel"
#include ":DP_DigitizerView"
#include ":DP_DigitizerController"
#include ":DP_BrowserModel"
#include ":DP_BrowserView"
#include ":DP_BrowserController"
#include ":DP_Sweeper"
#include ":DP_SweeperView"
#include ":DP_SweeperController"
#include ":DP_TestPulser"
#include ":DP_TestPulserView"
#include ":DP_TestPulserController"
//#include ":DP_SineBuilder"
#include ":DP_SineStimulus"
//#include ":DP_ChirpBuilder"
#include ":DP_ChirpStimulus"
//#include ":DP_WNoiseBuilder"
#include ":DP_WNoiseStimulus"
//#include ":DP_PSCBuilder"
#include ":DP_PSCStimulus"
//#include ":DP_RampBuilder"
#include ":DP_RampStimulus"
//#include ":DP_TrainBuilder"
#include ":DP_TrainStimulus"
//#include ":DP_TrainWPPBuilder"
//#include ":DP_TrainWPPStimulus"
//#include ":DP_TTLTrainBuilder"
#include ":DP_TTLTrainStimulus"
//#include ":DP_MulTrainBuilder"
#include ":DP_MulTrainStimulus"
//#include ":DP_TTLMTrainBuilder"
#include ":DP_TTLMTrainStimulus"
//#include ":DP_StairBuilder"
//#include ":DP_StairStimulus"
//#include ":DP_TTLPulseBuilder"
#include ":DP_TTLPulseStimulus"
//#include ":DP_PulseBuilder"
#include ":DP_PulseStimulus"
//#include ":DP_CenteredPulseStimulus"
#include ":DP_OutputViewerModel"
#include ":DP_OutputViewerView"
#include ":DP_OutputViewerController"
#include ":DP_Utilities"
#include ":DP_MyProcedures"
//#include ":DP_BuilderModel"
//#include ":DP_BuilderView"
//#include ":DP_BuilderController"
#include ":DP_Stimulus"
#include ":DP_Switcher"
#include ":DP_ASwitcher"
#include ":DP_Camera"
#include ":DP_CameraPrivateMethods"
#include ":DP_CameraClassMethods"
#include ":DP_FancyCamera"
#include ":DP_EpiLight"
#include ":DP_Imager"
#include ":DP_ImagerView"
#include ":DP_ImagerController"
#include ":DP_ImageBrowserModel"
#include ":DP_ImageBrowserView"
#include ":DP_ImageBrowserController"

#include ":DP_SimpStim"
#include ":DP_CompStim"
#include ":DP_CompStimWave"
#include ":DP_CompStimBuilderModel"
#include ":DP_CompStimBuilderView"
#include ":DP_CompStimBuilderController"

//#include ":DP_BarrageDetector"
//#include ":DP_BarrageDetectorView"
//#include ":DP_BarrageDetectorCont"




//---------------------- DataPro MENU -----------------------//

Menu "DataPro"
	dpMenu("All Controls"), MainContConstructors()
	dpMenu("-")
	dpMenu("Sweeper Controls"), SweeperContConstructor()
	dpMenu("Digitizer Controls"), DigitizerContConstructor()
	dpMenu("Imager Controls"), ImagerContConstructor()
//	dpMenu("-")
	dpMenu("New Signal Browser"), BrowserContConstructor("New")
	dpMenu("Image Browser"), ImageBrowserContConstructor()
	dpMenu("-")
	dpMenu("Stimulus Builder"), CSBContConstructor()
//	dpMenu("-")
//	dpMenu("Pulse Builder"), BuilderContConstructor("Pulse")
//	dpMenu("TTL Pulse Builder"), BuilderContConstructor("TTLPulse")
//	dpMenu("Train Builder"), BuilderContConstructor("Train")
//	dpMenu("Train-with-Prepulse Builder"), BuilderContConstructor("TrainWPP")
//	dpMenu("TTL Train Builder"), BuilderContConstructor("TTLTrain")
//	dpMenu("Multiple Train Builder"), BuilderContConstructor("MulTrain")
//	dpMenu("Multiple TTL Train Builder"), BuilderContConstructor("TTLMTrain")
//	dpMenu("Stair Builder"), BuilderContConstructor("Stair")
//	dpMenu("Ramp Builder"), BuilderContConstructor("Ramp")
//	dpMenu("PSC Builder"), BuilderContConstructor("PSC")
//	dpMenu("Sine Builder"), BuilderContConstructor("Sine")
//	dpMenu("Chirp Builder"), BuilderContConstructor("Chirp")
//	dpMenu("White Noise Builder"), BuilderContConstructor("WNoise")
//	dpMenu("-")
	dpMenu("Output Viewer"), OutputViewerContConstructor()
	dpMenu("-")
	dpMenu("Test Pulser"), TestPulserContConstructor()
	dpMenu("-")
	dpMenu("Switcher"), SwitcherContConstructor()
	dpMenu("Axon Switcher"), ASwitcherContConstructor()
	//dpMenu("-")	
	//dpMenu("Barrage Detector"), BarrageDetectorContConstructor()
End

Function /S dpMenu(item)
	String item
	
	String result
	strswitch (item)
		case "Imager Controls":
			result=stringFif(IsImagingModuleInUse(),item,"")
			break
		case "Image Browser":
			result=stringFif(IsImagingModuleInUse(),item,"")
			break
		default:
			result=item	
	endswitch
	return result
End

//Menu "DataPro Image"
////	"Data Pro_Menu"
////	"-"
//	//"Imager Controls", ImagerContConstructor()
//	//"-"
////	"Focus_Image"
////	"Acquire_Full_Image"
//	"Load_Full_Image"
//	"Load_Image_Stack"
//	"-"
//	"Image_Display"
//	"DFF_From_Stack"
//	"-"
//	"Show_DFoverF"
//	"Append_DFoverF"
//	"Quick_Append"
//	//"Get_SIDX_Image"
//End

// This adds it to the marquee pop-up menu in a graph window
Menu "GraphMarquee"
	"-"
	"Add ROI", ImagerBrowserContAddROI()
End

//Function IgorStartOrNewHook(igorApplicationNameStr)
//	String igorApplicationNameStr
//	InitializeDataPro()
//End

Function AfterCompiledHook()
	//Printf "Inside AfterCompiledHook()\r"
	InitializeDataPro()
	PostInitializationHook()
End

Function InitializeDataPro()
	//String savedDF=GetDataFolder(1)
	//NewDataFolder /O/S root:DP_Digitizer
	//String pathToThisFile=FunctionPath("")
	//String dataProPathAbs=ParseFilePath(1,pathToThisFile,":",1,0)
	//	// first 1 says to get the path up but not including the specified element
	//	// second 1 says the specified element is relative to the last element
	//	// 0 indicates the zeroth element (relative to the last), hence the last element
	//NewPath /O DataPro dataProPathAbs
	//LoadPICT /O /P=DataPro "DataProMenu.jpg", DataProMenu
	BuildMenu "DataPro"
	SamplerConstructor()
	DigitizerModelConstructor()
	SweeperConstructor()
	TestPulserConstructor()
	if ( IsImagingModuleInUse() )
		EpiLightConstructor()
		FancyCameraConstructor()
		if (!FancyCameraGetIsForReal())
			DoAlert /T="Unable to Find Camera" 0, "Unable to find camera.  Using faux software camera."
		endif
		ImagerConstructor()
		ImagerSetIsAcquiringVideo(0)	
			// If something got borked during acquire, and the user had to delete the old window and get a new one, 
			// this makes sure the view doesn't look like video is being acquired
		ImagerViewCCDTempChanged()
		IVStartTempUpdateBGTask()
		ImageBrowserModelConstructor()
	endif
//	// Set these things 
//	BuilderModelConstructor("TTLConst")
//	Variable defaultEpiTTLOutputIndex=1
//	EpiLightSetTTLOutputIndex(defaultEpiTTLOutputIndex)
//	SweeperEpiLightTTLOutputChanged()
End

//Function AcquisitionPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
//	String ctrlName
//	Variable popNum
//	String popStr
//End

//Function StartPanel() : Panel
//	PauseUpdate; Silent 1		// building window...
//	NewPanel /W=(271,307,737,541)
//	SetDrawLayer UserBack
//	SetDrawEnv fstyle= 1
//	DrawText 68,30,"It is very important that you save this as an"
//	SetDrawEnv fstyle= 1
//	DrawText 38,56,"unpacked experiment before you begin acquiring data."
//	SetDrawEnv fstyle= 1
//	DrawText 66,85,"Click the start button below and this will be"
//	SetDrawEnv fstyle= 1
//	DrawText 86,115,"the first thing you are prompted to do."
//	Button startbutton0,pos={177,136},size={100,30},proc=StartButtonProc,title="Start DataPro"
//EndMacro

//Function StartButtonProc(ctrlName) : ButtonControl
//	String ctrlName
//	Execute "StartDataPro()"
//	DoWindow /K StartPanel
//End

Function MainContConstructors()
	// Raise or create the main controllers (and their views) used for data acquisition
	DigitizerContConstructor()
	TestPulserContConstructor()
	SweeperContConstructor()
	BrowserContConstructor("NewOnlyIfNone")
	if ( IsImagingModuleInUse() )
		ImagerContConstructor()
	endif
End

Function IsImagingModuleInUse()
	Variable sidxPresent=(exists("SIDXRootOpen")==4)
	//sidxPresent=0		// Uncomment if you don't want to use the imaging module
	return sidxPresent		// Change to zero if you don't want to use the imaging module
End

Function IgorBeforeQuitHook(unsavedExp, unsavedNotebooks, unsavedProcedures)
	Variable unsavedExp
	Variable unsavedNotebooks
	Variable unsavedProcedures
	
	if ( IsImagingModuleInUse() )
		ImagerViewDestructor()
		CameraDestructor()
	endif
End

