//Macro to generate Kymos from MT snaps and GFP streams.
//Chris Gell 21-05-2018
//Version 2.1

//macro to make kymos for gfp tirf data
//assumes 2 images are loaded and that 
//these are a stream and a mt.
//go to either and add lines to the 
//ROI manager. Then run the macro.

//to do the next one clear the ROI manager
//and close all open windows.
//load the next strem and snap.



// to add 
// DONE- have it work out which is the stream
// reduce thickness or transparency of the lines in the mt map
//DONE - name directory in an intelegent way - not wanted, not flexible.
//DONE, not wanted - cope with multiple streams (of the same MT FOV)?

//2018-10-18 updated a stream and MTs were still sometimes misidentified
//2018-10-18 updated to allow some chromatic shift correction, this is base dont he Fiji 'Align image by lin ROI' tools.



//environment variables
envMakeFullOverlay=0;
envAskForPNGs=0;
 print("\\Clear");




//see if any images are open.
if (nImages!=2) {
	//
	Dialog.create("");
	Dialog.addMessage("Too many or too few images open, open 2 images, the MTs and stream.");
	Dialog.show();
	exit; 
}



roiManager("show all with labels")


//ask for an identifier for this analysis
expName=getString("Enter an indetifier for this experiment", "");




 //create an array with a list of open window names and then work out which image is which.
 n = nImages; 
    list = newArray(n); 
    for (i=1; i<=n; i++) { 
        selectImage(i); 
        list[i-1] = getTitle; 
print(list[i-1]);
    } 
print("end");
   

selectWindow(list[0]);
getDimensions(width, height, channels, slices, frames);

print("list0 is"+list[0]+"      list1 is "+list[1]);
print("list0 has "+slices+" slices      "+frames+"  frames");

if ((slices) & (frames)==1) {
	gfpImageName=list[1];
	mtImageName=list[0];
	print("done the and");
}



selectWindow(list[0]);
getDimensions(width, height, channels, slices, frames);
if ((slices) | (frames)>1) {
	gfpImageName=list[0];
	mtImageName=list[1];
		print("done the or");
}

print("gfp image is "+gfpImageName);
print("mt image is "+mtImageName);


//Need to determine if this is an Elyra experiment (or at least one where chromatic registration is needed).
if (getBoolean("Do you need to perform chromatic registration \n (for example ELyra data).") == 1) {

//Code to align data from the Elyra using the fixed, rigid, no scaling, no rotation transform using a line Roi.
//Chris Gell November 17 2018


selectWindow(gfpImageName); //Choose the stream and make a STD projection




run("Z Project...", "projection=[Standard Deviation]");
run("Enhance Contrast", "saturated=0.35");
run("16-bit");

/*	the user needs to draw an ROI on this projection and the MT image and the stream image (draw it on one, restore to the others)
	best to choose a diagonal tube (aligned at 45 degrees) along a MT (idnetified via) . Movement is best done with the cursor keys,
	you are then shown a overlay of the the gfp projection and mts to check. Note that the only way to re-run is to choose to stop the macro.
	

	The source image should always be the MT image.
	

*/

setTool("line");
waitForUser("Please draw a line ROI on a MT in the using the GFP rpojection \n and restore this to the GFP and MT channel \n using the cursor keys to align it.");


run("Align Image by line ROI", "source=["+mtImageName+"] target=[STD_"+gfpImageName+"]");
selectWindow(mtImageName+" aligned to STD_"+gfpImageName);
run("16-bit");
run("Merge Channels...", "c2=[STD_"+gfpImageName+"] c6=["+mtImageName+" aligned to STD_"+gfpImageName+"] create keep");


waitForUser("Please check you are happy \n with the registration, \n you will be asked to accept it.");

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








//get the number of frames in the stream
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


//if wanted make a full overlay


if (envMakeFullOverlay==1) {
setSlice(1);
run("Select None");
//create mt id tools
run("Merge Channels...", "c2=["+gfpImageName+"] c6=["+mtImageName+"] create keep");
run("Z Project...", "projection=[Average Intensity]");
run("Red");
run("Enhance Contrast", "saturated=0.35");
}

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


//make record image
selectWindow(mtImageName);
run("Duplicate...", " ");
rename("MTs");
run("Invert");
run("Grays");
run("Enhance Contrast", "saturated=0.35");
roiManager("Show All");

//save everything
dir = getDirectory("Choose a Directory");
//dirTemp = getDirectory("Choose a Directory");
//File.makeDirectory(dir+expName); 
//newDir=dir + "/"+expName+"/";
newDir=dir;

 roiManager("deselect"); 
 roiManager("save", newDir +expName+" "+gfpImageName+".zip")
 roiManager("Show None"); 


//close orignals
selectWindow(mtImageName);
close(mtImageName);
selectWindow(gfpImageName);
close(gfpImageName);


ids=newArray(nImages); 
for (i=0;i<nImages;i++) { 
        selectImage(i+1); 
        title = getTitle; 
        //print(title); 
        ids[i]=getImageID; 

        saveAs("tiff", newDir + expName + title + " " + "MT-" + mtImageName+ "Stream-"+gfpImageName); 
}



if (envAskForPNGs==1) {

 //ask user if wants kymo and mt 'map' saving as png.
//getBoolean("Save PNGs of everything?");
 if (getBoolean("Save PNGs of everything?")) {
 
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
}


//End of code

