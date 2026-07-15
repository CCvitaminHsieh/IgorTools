#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function myProcessorFunc(textWave,entry)
	wave/t textWave //a reference to the bufferwave of interest
	variable entry	//which row has just been filled in the bufferwave.
	//print textWave[entry][0]
	//print " received at"+ textWave[entry][1]
end

// R&S SGMA-GUI 4.30.046.221 x64
// SGMA-GUI -> Help ->SGS_Help
// Example: Remote Control over LAN Using Socket Communication
// The socket address is a combination of the IP address or the host name of the R&S SGS 
// and the number of the port configured for remote-control via telnet.

Function SgmaConnection() // SGMA connection via telnet protocol 
	variable/g sockNum = 0
	variable SgmaPort = 5025  // Tip: The R&S SGS uses the port number 5025 for remote connection via Telnet.
	string SgmaIP = "169.254.2.20" // Instrument IP for SGMA-RF source 
	string SgmaFreq = "Freq 4.5GHz" // Freq default: Freq 4.5 GHz
	string RFB = "OUTp OFF" // RF Button default:OUTp OFF
	string  SgmaLev = "Pow -20 " // PowerLevel default (dBm): -20
	
	killwaves/z SgmaIndex // Clean the last result 
	make/t SgmaIndex
	//get the sockNum ( CommunicationKEY between PC client and Instrument client)
	sockitopenconnection/proc=myProcessorFunc sockNum,SgmaIP,SgmaPort,SgmaIndex 
	
	
	// SGMA cw control to the below default setting by sending the message
	sockitsendmsg sockNum,SgmaFreq+"\n"
	sockitsendmsg sockNum,RFB+"\n"
	sockitsendmsg sockNum,SgmaLev+"\n"
	
	variable/g sockNum
	if (SockitsendmsgF(sockNum,SgmaFreq)==0)
		print " Connect successfully"
		return 0
	else 
		print " Connect unsuccessfully." 
		print " Please restart the CWprogram to control the SGMA-ContinuousWave."
		return 1
	endif
End
Function SetSgmaCw(Freq,Level)
	variable Freq //min=1.000MHz,max=12.75GHz
	variable Level  //min=-20.00dBm,max=20.00dBm
	string strfreq,strlevel 
	Nvar sockNum //get the global variable from the function named SgmaConnection()
	
	if (sockNum==0)
		print "Warning : the SigmaConnect() is not activated"
	else
		if ((0.001<=Freq&&Freq<=12.75)&&(-20.00<=Level&&Level<=20.00)) 
			sprintf strfreq "Freq %g %s",Freq," GHz"
			sprintf strlevel "Pow %g",Level
 			sockitsendmsg sockNum,strfreq+"\n" 
 			sockitsendmsg sockNum,strlevel+"\n"
 		else
 			print "Warning: the range of the default Freq is from 0.001(GHz) to 12.75(GHz).\n"
 			print "Warning: the range of the default Level is from -20.00(dBm) to 20.00(dBm).\n"
		endif
	endif
End
Function SetSgmaCwOut(state)
	variable state //state = 1,0
	string strout
	Nvar sockNum //get the global variable from the function named SgmaConnection()
	
	if (sockNum==0)
		print "Warning : the SigmaConnect() is not activated"
	else
		if (state == 1 || state == 0)
			sprintf strout "OUTp %g",state
 			sockitsendmsg sockNum,strout+"\n"
 		else
 			print "Warning: the default of state = 1 (RFon).\n"
 			print "                                     state = 0 (RFoff)."
 		endif
 	endif
End
 

