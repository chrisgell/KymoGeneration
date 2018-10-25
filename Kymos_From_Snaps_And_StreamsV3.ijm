//Macro to generate Kymos from MT snaps and GFP streams.
//Chris Gell 24-05-2018
//Version 3beta1

//Macro is run from SLIMcg>Friel>Kymos from Snaps and Streams.

//Tested only with 512x512, 16bit, .czi and .dv Tiffs.

//Macro to make kymographss for SM TIRF data sets - specifically GFP's on fluorecentlabelled microtubules.
//Requires 2 images are loaded and that these are a stream (stack) and a single-slice mt image.
//Microtubules can be selected by either an algorithm (how well this works is largely dependant on the contrast and SNR of the MT image.
//Some images 
//There is then an option to manually edit these selections, or delete all of them, and use your own. Microtubule slections must be added to the ROI manager.
//To analyse the next image clear the ROI manager, close all open images and re-rum the macro.
//and close all open windows.
//load the next strem and snap.



// to add 
// reduce thickness or transparency of the lines in the mt map

//add in auto MT detection.

//DONE - name directory in an intelegent way - not wanted, not flexible.
//DONE, not wanted - cope with multiple streams (of the same MT FOV)?

//2018-10-18 updated a stream and MTs were still sometimes misidentified
//2018-10-18 updated to allow some chromatic shift correction, this is base dont he Fiji 'Align image by lin ROI' tools.
//2018-10-24 started tidying up and adding more functioanlity to prepare for a write-up



//environment variables
envAskForPNGs=0;	  // TRUE if PNGs should be saved.
envDoChromaticCorr=0; // TRUE if chromatic shift should be done.

//tidy up
print("\\Clear");	//Clear the log.
if (roiManager("count") !=0) {
			
			roiManager("Deselect");
			roiManager("Delete");
		
		}
		

//set some behavious of various parts.
roiManager("show all with labels");	



//see if any images are open, must only have two images open.
if (nImages!=2) {
	exit("Too many or too few images open, open 2 images, the MTs and SM stream.") 
}


//ask for an identifier for this analysis
expName=getString("Enter an indetifier for this experiment", "SM TIRF ");

//going to get the names of the MT and stream image now.
var gfpImageName=""; 
var mtImageName="";
getImageNames();




//do a quick contrast strtch
selectWindow(gfpImageName);
run("Enhance Contrast", "saturated=0.35");
run("Set... ", "zoom=150");
selectWindow(mtImageName);
run("Enhance Contrast", "saturated=0.35");
run("Set... ", "zoom=150");
run("Tile");
 


//WIll ask if we need to do a chromatic aberration correction and run it.
doCromaticAbCorr();

//Ask if the user want to attempt auto MT detection
doMTDetection();


//make the snap have the same number of frames as in the stream
convSnapToStream();


//the user needs to add the ROI
waitForUser("Please make sure you have selected ROI's as required.");


//loop throught the ROI manager to create each of the kymos
n = roiManager("count");
  for (i=0; i<n; i++) {
				
		//Make the GFp channel kymo
		selectWindow(gfpImageName);
		roiManager("select", i);
		Roi.setStrokeWidth(3);
		run("Multi Kymograph", "linewidth=3");
		selectWindow("Kymograph");
		rename("GFP - Kymograph" + (i + 1) +" "+expName);
		run("Green");
		run("Enhance Contrast", "saturated=0.35");
		
		//Make the MT kymo
		selectWindow(mtImageName);
		roiManager("select", i);
		Roi.setStrokeWidth(7);
		run("Magenta");
		run("Multi Kymograph", "linewidth=7");
		selectWindow("Kymograph");
		rename("MT - Kymograph" + i+1+" "+expName);
		selectWindow("MT - Kymograph" + (i+1)+" "+expName);
		run("Magenta");
		
		//make the merged kymo
		run("Merge Channels...", "c2=[GFP - Kymograph"+ (i+1)+" "+expName+"] c6=[MT - Kymograph"+ (i+1)+ " "+expName+"] create");
		selectWindow("Composite");
		rename("MT - GFP - Kymograph" + (i+1)+" "+expName);

  }// end of ROI loop


//make record image to show the MTs that have been used for kymograph genmeration.
selectWindow(mtImageName);
run("Duplicate...", " ");
rename("MTs");
run("Invert");
run("Grays");
run("Enhance Contrast", "saturated=0.35");
roiManager("Show All");

//save everything
dir = getDirectory("Choose a Directory");
newDir=dir;

//save ROIs
roiManager("deselect"); 
roiManager("save", newDir +expName+" "+gfpImageName+".zip")
roiManager("Show None"); 

//close orignals
selectWindow(mtImageName);
close(mtImageName);
selectWindow(gfpImageName);
close(gfpImageName);

run("Tile");

//save Kymographs
ids=newArray(nImages); 
for (i=0;i<nImages;i++) { 
        selectImage(i+1); 
        title = getTitle; 
        //print(title); 
        ids[i]=getImageID; 

        saveAs("tiff", newDir + expName + title + " " + "MT-" + mtImageName+ "Stream-"+gfpImageName); 
}


//This is deprecated, but ask user if wants kymo and mt 'map' saving as png.
//This used to be promted for, but I thinks it's not necessary (typically) so there is a variable set now at the start.
if (envAskForPNGs==1) {
	
	ids=newArray(nImages); 
	
	for (i=0;i<nImages;i++) { 
	        selectImage(i+1); 
	        title = getTitle; 
	        //print(title); 
	        ids[i]=getImageID; 
			//run("Flatten");
	        //saveAs("png", dir+title+" "+gfpImageName); 
	        saveAs("png", newDir+expName+title); 
	}
} 

//ask the user if you would all windows closing - this tidies thing sup for the next run.

if (getBoolean("Close all open windows?") == 1) {

	run("Close All");
	
	//check to see if anything in ROI and clear it
		if (roiManager("count") !=0) {
			
			roiManager("Deselect");
			roiManager("Delete");
		
		}

	
}




//End of core macro


function doCromaticAbCorr() {

	//Need to determine if this is an Elyra experiment (or at least one where chromatic registration is needed).
	if (getBoolean("Do you need to perform chromatic registration \n(for example ELyra data)?") == 1) {
	
		//Code to align data from the Elyra using the fixed, rigid, no scaling, no rotation transform using a line Roi.
		//Chris Gell November 17 2018

		//this is useful when drawing the ROIs
		run("Synchronize Windows");
	
		selectWindow(gfpImageName); //Choose the stream and make a STD projection
		run("Z Project...", "projection=[Standard Deviation]");
		run("Enhance Contrast", "saturated=0.35");
		run("16-bit");
		run("Tile");
	
	
		/*	The user needs to draw an ROI on this projection and then restore to the GFP image, then restore the MT image and move it accordingly.
			Best to choose a diagonal tube (aligned at 45 degrees) along a MT (idnetified via). Movement is best done with the cursor keys,
			you are then shown a overlay of the the gfp projection and mts to check. Note that the only way to re-run is to choose to stop the macro.
		*/
		
		setTool("line");
		waitForUser("Please synchronise windows, then draw a line ROI on the GFP projection. Using the cursor keys, to align it to the MT on the MT image.");
		
		//run the correction, this assumes a very simple translational error that can be accounted for by a simple tranlation.
		run("Align Image by line ROI", "source=["+mtImageName+"] target=[STD_"+gfpImageName+"]");
		selectWindow(mtImageName+" aligned to STD_"+gfpImageName);
		run("16-bit");
		
		//generate a preview result
		run("Merge Channels...", "c2=[STD_"+gfpImageName+"] c6=["+mtImageName+" aligned to STD_"+gfpImageName+"] create keep");


		
		//see if the user likes it
		setTool("zoom");
		waitForUser("Please check you are happy with the registration, \n you will be asked to accept it after you dismiss this dialog.");
		if (getBoolean("Confirm the registration and proceed?") != 1) {
			exit();
		}
		
		//close the merge window, close the mt window and rename the other one
		selectWindow("Composite");
		close();
		selectWindow("STD_"+gfpImageName);
		close();
		selectWindow(mtImageName);
		close();
		selectWindow(mtImageName+" aligned to STD_"+gfpImageName);
		rename(mtImageName);
		run("Select None");
		selectWindow(gfpImageName);
		run("Select None");
	
	}
}

function getImageNames() {


		 //create an array with a list of open window names and then work out which image is which.
		 n = nImages; 
		    list = newArray(n); 
		    for (i=1; i<=n; i++) { 
		        selectImage(i); 
		        list[i-1] = getTitle; 
		    } 
		
		//will now test to see which window is the stream and whcih is the mt image.   
		selectWindow(list[0]);
		getDimensions(width, height, channels, slices, frames);
		if ((slices) & (frames)==1) {
			gfpImageName=list[1];
			mtImageName=list[0];
		} else if ((slices) | (frames)>1) {
			gfpImageName=list[0];
			mtImageName=list[1];
		} 


}

function convSnapToStream() {
	selectWindow(gfpImageName);
	getDimensions(width, height, channels, slices, frames);
	gfpImageID=getImageID();
	n = frames;
	//make the MT image the same length
	selectWindow(mtImageName);
	mtImageID=getImageID();
	//make a blurred mt image, a little better look for the kymos
	run("Gaussian Blur...", "sigma=1");
	run("Copy");
	  for (i=0; i<n-1; i++) {
	      run("Add Slice");
	      run("Paste");
	}
}



function doMTDetection() {

	if (getBoolean("Do you want to attempt automatic detection of the microtubules?") == 1) {
		
		
		//check to see if anything in ROI and clear it
		if (roiManager("count") !=0) {
			
			roiManager("Deselect");
			roiManager("Delete");
		
		}
		
		//preprocessing
		selectWindow(mtImageName);
		run("Duplicate...", "title=MT-copy");
		run("Auto Threshold", "method=Default white");
		run("Area Opening", "pixel=70");
		
		//detection
		run("Connected Components Labeling", "connectivity=4 type=[16 bits]");
		selectWindow("MT-copy-areaOpen");
		selectWindow("MT-copy-areaOpen-lbl");
		run("Geodesic Diameter", "label=MT-copy-areaOpen-lbl distances=[Chessknight (5,7,11)] show image=["+mtImageName+"] export");
		selectWindow("MT-copy-areaOpen-lbl");
		close();
		selectWindow("MT-copy-areaOpen");
		close();
		selectWindow("MT-copy");
		close();
		selectWindow("MT-copy-areaOpen-lbl-GeodDiameters"); 
         run("Close"); 
		
		//display results
		selectWindow(mtImageName);
		run("Enhance Contrast", "saturated=0.35");
		run("Remove Overlay");
		
		
		//enlarge the slections. 
		
		n = roiManager("count");
		  for (i=0; i<n; i++) {
				roiManager("Select", i);		
				run("Scale... ", "x=1.50 y=1.50 centered");
				roiManager("Update");
		
		  }// end of ROI loop
		
		
		roiManager("Show All");
		setTool("polyline");

		//now need to see if the user wants to edit and then accept these.
		waitForUser("Please examine the selected ROIs and edit as necessary. \nRemember to either delete, update or add changes to the manager. \nYou will then be asked to confirm the choices after you dismiss this dialog.");
		
		
			if (getBoolean("Do you want to accept these ROIs \nIf you say no, all ROIs will be removed and you will be asked to manually select them.") != 1) {
					
				if (roiManager("count") !=0) {
			
					roiManager("Deselect");
					roiManager("Delete");
		
				}
				
			}
		
	}
}

