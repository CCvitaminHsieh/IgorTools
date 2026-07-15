#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//
//*******************************************************************
//Verified Version:
//    Igor Pro 6.37 on Windows 10 
//Desc:
//    1. Install the below dependencies to start the service for data converting from HDF5 to Igor support
//    2. Dependencies(you can find these files in the following path):
//				2.1. HDF5.xop:          C:\Program Files (x86)\WaveMetrics\Igor Pro Folder\More Extensions\File Loaders
//				2.2. HDF5 Help.ihf:     C:\Program Files (x86)\WaveMetrics\Igor Pro Folder\More Extensions\File Loaders
//				2.3. HDF5 Browser.ipf:  C:\Program Files (x86)\WaveMetrics\Igor Pro Folder\WaveMetrics Procedures\File Input Output
//				2.4. HDF Utilities.ipf: C:\Program Files (x86)\WaveMetrics\Igor Pro Folder\WaveMetrics Procedures\File Input Output
//
//		3. Copy the above files and place them in the specified folder
//				3.1. Put "HDF5.xop" and "HDF5 HELP.ihf" to the below absolute path
//					  	path: C:\Program Files (x86)\WaveMetrics\Igor Pro Folder\Igor Extensions
//				3.2. Put "HDF5 Browser.ipf" and "HDF Utilities.ipf" to the specified folder
//						path: C:\Program Files (x86)\WaveMetrics\Igor Pro Folder\User Procedures
//
//		4. (Optional)
//       Before you use the following functions for labber data converting, I hope that you can read the below content.
// 			Q: How to activate HDF5 service?
//				A: You can get "Help Topics" of "HDF5XOP" from "Igor Help Browser", then read "HDF5 Help.ipf" to get more details.
// 			Q: How to open "HDF5Browser"?
// 			A: click the following step: Data -> Load Waves -> New HDF5 Browser
// 			Q: How to get the experimental data via "HDF5Browser" panel?
// 			A: Open HDF5 File, choose the Files of type as "All Files", find the folder of any HDF5 file exists , then click the specific file you want
// 			Q: How to load the experimental data to Data Browser?
// 			A: select Data (Group) -> Data (Datasets), then click "Load Dataset" button
//
//
//*******************************************************************
Function scaleSet(Wname, x_start, x_end, y_start, y_end)
	//Desc:
	//    the operation sets two dimensions (x-y coordinate system) scaling.
	//Args:
	//    Wname:
	//    x_start: the start value in x dimension
	//    x_end:   the end value in y dimension
	//    y_start: the start value in y dimension
	//    y_end:   the end value in y dimension
	//Usage:
	//    scaleSet(wave, )
	wave Wname 
	variable x_start, x_end, y_start, y_end
	setscale/I x, x_start,x_end, Wname
	setscale/I y, y_start, y_end, Wname
End

//
//*******************************************************************
//

Function WaveRename(Wname, StrName)
	//Desc:
	//    replace the oldName of the wave with newName
	//Args:
	//    Wname:   oldName of the wave stored in data browser	
	//    StrName: newName of the wave 
	//Usage:
	//    WaveRename()
	wave Wname
	string StrName
	rename Wname, $StrName
End 

//
//*******************************************************************
//

Function promptMessage(foldername)
	//Desc:
	//    show the following message.
	//Args:
	//    foldername: the folder name
	//Usage:
	//    promptMessage("
	string foldername
	print "In this script, we will convert the data from LabberFormat to Igor supported\n"
	print "You select this folder: ",foldername
End

//
//*******************************************************************
//


Function convertOKmessage(folderName, repositoryDataPath)
	//Desc:
	//    the function show the message for converting data completely, and
	//    the converted data will be save in this directory named "LabberToIgorRepository"
	//Args:
	//    folderName:         the folder name
	//    repositoryDataPath: the absolute path of the repository
	
	string folderName, repositoryDataPath
	print "\n----------------------MESSAGES---------------------------\n"
	print "Data convert successfully."
	print "Now, you can view the measurement data from this folder called LabberToIgorRepository"
	print "->File Name ", folderName
	print "->Folder Path", repositoryDataPath
	print "\n----------------------FINISHED---------------------------\n"
End

//
//*******************************************************************
//

Function showDiagram()
	//Desc:
	//    the function can display the diagram when you click the wave in the folder named "LabberToIgorRepository" 
	wave photo = $getbrowserselection(0)
	string ctabStyle = "RedWhiteBlue"
	variable colorInverse = 1
	display/k=0
	appendimage photo
	setaxis/A left
	modifyimage $nameofwave(photo), ctab={*, *, $ctabStyle, colorInverse}
End

//
//*******************************************************************
//

Function LabberConvert_DataMode(Source, StrName)
	//Desc:       
	//        
	//
	//Args:
	//    Source: get the experimental Data from HDF5Browser()
	//    StrName: designate the Wname of the destination
	//Usage: LabberDataConvert(Data, "Mag2Data")
	//
	wave Source
	string StrName
	variable m = DimSize(Source, 0), n = DimSize(Source, 2)
	variable col = n
	variable unit = 1e+9 // Hz
	variable x_start = Source[0][0][0] * unit, x_end = Source[m-1][0][0] * unit
	variable y_start = Source[0][1][0], y_end = Source[0][1][n-1]
	variable index
	make/o/n=(m, n) Destination
	
	for (index = 0 ; index < col ; index = index + 1)
		Destination[][index] = Source[p][2][index]
	endfor
	
	ScaleSet(Destination, x_start, x_end, y_start, y_end)
	WaveRename(Destination, StrName)
	
End

//
//*******************************************************************
//


Function LabberConvert_TraceMode(yaxisSource, xaxisSource, S21Trace)
	// Strategy for TraceMode
	// Traces
	// X axis: Frequency (Hz)
	// Y axis: Power(dBm) or Current(mA)                     
	// Z axis: S21 parameters, VNA - S21, (real, image)
	// VNA - S21 -> VNA -S21 t0dt 
	// path test:
	// root:'Weak_loop2.5X_GlobalFlux_3.8-5.':Traces:'VNA - S21'
	// command prompt test:
	// LabberConvert_TraceMode(Data, $"VNA - S21_t0dt", $"VNA - S21")
	wave yaxisSource, xaxisSource, S21Trace
	variable yaxisStart = yaxisSource[0][0]
	variable yaxisDelta = yaxisSource[1][0]
	variable xaxisStart = xaxisSource[0][0]
	variable xaxisDelta = xaxisSource[0][1]
	variable m = dimsize(S21Trace, 0), n = dimsize(S21Trace, 2) //m:3001, n:62
	variable indexM, indexN 

	make/o/n=(m, n) MagDestinate, PhaseDestinate
	// row:0-3001
	// col:0-1
	// layer:0-61
	
	for (indexM = 0 ; indexM < M ; indexM = indexM + 1)
		for (indexN = 0 ; indexN < N; indexN = indexN + 1)
			MagDestinate[indexM][indexN] = sqrt(S21Trace[indexM][0][indexN] ^2 + S21Trace[indexM][1][indexN] ^2)
			PhaseDestinate[indexM][indexN] = atan2(S21Trace[indexM][0][indexN], S21Trace[indexM][1][indexN])
		endfor
	endfor
	
	scaleSet(MagDestinate, xaxisStart, xaxisStart + m * xaxisDelta, yaxisStart, yaxisSource[n][0])
	scaleSet(PhaseDestinate, xaxisStart, xaxisStart + m * xaxisDelta, yaxisStart, yaxisSource[n][0])
	
End

//
//*******************************************************************
//

Function LabberConvert_LogMode()
	// Data Stored Structure
	// -Data
	// - Log_2/Data
	// - Log_3/Data
	// - Log_4/Data
	// - Log_5/Data
	// - Log_6/Data
	// etc
	//
	// Strategy for LogMode
	// go to each above folder, and do LabberConvert_DataMode to convert it as a igor format
	// rename each segmented file as the format, like "temp_1"
	// move all files in Log  to Data folder
	// combine all segmented waves into a complete image(wave)
	// move a complete wave to root:LabberToIgorRepository
	
	//variable 
	
End

//
//*******************************************************************
//

Function SearchFolder(keyword)
	string keyword
	string currentFolder = getdatafolder(0)
	string destFolder = getbrowserselection(0)
	variable discover =  0
	
	if (stringmatch(currentFolder, destFolder) != 1)
		setdatafolder $destFolder
		if (datafolderexists(keyword))
			setdatafolder $keyword
			discover = 1
//		else 
//			printf "No, the folder: %s can't be found in this path\n %s.\n", keyword, destFolder
		endif
//	else
//		print "Please click your experimental folder in Data Browser, and then try again."
	endif
	
	setdatafolder root:
	
	return discover
End

//
//*******************************************************************
//


Function main()
	string folderName = replacestring("'",replacestring("root:", getbrowserselection(0), ""),"")
	string repository = "LabberRepo"
	string repositoryDataPath
	string ModePath = getbrowserselection(0)
	sprintf repositoryDataPath, "root:%s:%s", repository, folderName
	
	setdatafolder root:
	
	if (datafolderexists(repository) == 0)
		newdatafolder $repository
	endif
	
	if (searchFolder("Data") == searchFolder("Traces"))
		setdatafolder ModePath
		wave yaxisInfo = $":Data:Data"
		setdatafolder $(":Traces")
		wave xaxisInfo = $"VNA - S21_t0dt"
		wave xaxis_Sparameter = $"VNA - S21"
		
		print "Traces Mode\n"
		promptMessage(folderName)
		
		if (waveexists($folderName) == 0)
			LabberConvert_TraceMode(yaxisInfo, xaxisInfo, xaxis_Sparameter)
//			rename MagDestinate, $("mag_"+folderName)
//			rename PhaseDestinate, $("phase_"+folderName)
//			if (waveexists(root:$(repository):$("mag_"+folderName)) == 0) 
//				movewave :$("mag_"+folderName), root:$(repository):$("mag_"+folderName)
//			elseif (waveexists(root:$(repository):$("phase_"+folderName)) == 0) 
//				movewave :$("phase_"+folderName), root:$(repository):$("phase_"+folderName) 
			variable mag_exist_in_repo = waveexists(root:$(repository):MagDestinate)
			variable phase_exist_in_repo = waveexists(root:$(repository):PhaseDestinate)
			if ((mag_exist_in_repo==0) || (phase_exist_in_repo==0) )
				movewave :MagDestinate, root:$(repository):MagDestinate
				movewave :PhaseDestinate, root:$(repository):PhaseDestinate
				setdatafolder root:$(repository)
				rename MagDestinate, $("mag_"+folderName)
				rename PhaseDestinate, $("phase_"+folderName)
			else
				//killwaves/z repositoryDataPath
				setdatafolder root:$(repository)
				killwaves/z root:$(repository):$("mag_"+folderName)
				killwaves/z root:$(repository):$("phase_"+folderName)
				setdatafolder destPath
				movewave $("mag_"+folderName), root:$(repository):$("mag_"+folderName)
				movewave :$("phase_"+folderName), root:$(repository):$("phase_"+folderName)
			endif
			convertOKmessage(folderName, repositoryDataPath)
		endif
		
	elseif (searchFolder("Data") == searchFolder("Log_2"))
		print "Log Mode\n"
		print "The experiment file has not been fully measured yet."
		
	elseif (searchFolder("Data"))
//		string repositoryDataPath
//		sprintf repositoryDataPath, "root:%s:%s", repository, folderName
		string destFolder = "Data"
		string destPath 
		sprintf destPath, "%s:%s", ModePath, destFolder 
		setdatafolder destPath
		wave Data

		print "Data Mode:\n" 
		promptMessage(folderName)
		//print repositoryDataPath
		if (waveexists($folderName) == 0)
			LabberConvert_DataMode(Data,"result")
			rename result, $folderName
			if (waveexists(root:$(repository):$(folderName)) == 0)
				movewave :$(folderName), root:$(repository):$(folderName)
			else
				//killwaves/z repositoryDataPath
				killwaves/z root:$(repository):$(folderName)
				setdatafolder destPath
				movewave $(folderName), root:$(repository):$(folderName)
			endif
			convertOKmessage(folderName, repositoryDataPath)
		endif
	endif
//	else
//		print "When you see this bug, it implies that you need to save your current environment as an Experiment format"
//    print "Report this bug to me."
	setdatafolder root:
End

